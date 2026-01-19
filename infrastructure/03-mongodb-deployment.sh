#!/bin/bash
# ------------------------------------------------------------------
# [03-mongodb-deployment.sh]
# MongoDB Kurulumu (Private Subnet & Secrets Manager)
# ------------------------------------------------------------------

echo "🍃 MongoDB Deployment Başlıyor..."

# 1. Dinamik Olarak Kaynak ID'lerini Bul (Reproducible olması için)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=emir-dns-project-vpc" --query "Vpcs[0].VpcId" --output text)
PRI_SUB_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Private-Subnet-1" --query "Subnets[0].SubnetId" --output text)
PRI_SUB_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Private-Subnet-2" --query "Subnets[0].SubnetId" --output text)
DB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=MongoDB-SG" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text)
AMI_ID="ami-04b4f1a9cf54c11d0" # Ubuntu 24.04 LTS (US-East-1)

echo "   📍 VPC: $VPC_ID"
echo "   📍 Subnet: $PRI_SUB_1"
echo "   📍 Security Group: $DB_SG"

# 2. Secrets Manager'da Şifre Oluştur (Bonus +5 Puan)
echo "🔐 Secrets Manager: Veritabanı şifresi oluşturuluyor..."
SECRET_NAME="emir-dns-mongo-secret-final"
# Eğer secret varsa hata vermemesi için sessizce geçiyoruz
aws secretsmanager create-secret --name $SECRET_NAME \
    --description "MongoDB Credentials" \
    --secret-string '{"username":"admin","password":"StrongPassword123!"}' \
    --tags Key=Project,Value=DNS-Lookup 2>/dev/null || echo "   ⚠️ Secret zaten var, devam ediliyor."

# 3. UserData Script (Sunucu açılınca ne yapacak?)
# Docker kurar ve MongoDB'yi başlatır.
USER_DATA_SCRIPT='#!/bin/bash
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
docker run -d -p 27017:27017 \
  --name mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=StrongPassword123! \
  -v mongodb_data:/data/db \
  --restart always \
  mongo:4.4'

# Scripti Base64'e çevir (Hata riskini sıfırlar)
USER_DATA_B64=$(echo "$USER_DATA_SCRIPT" | base64 -w 0)

# 4. MongoDB Primary Sunucusunu Başlat (Private Subnet 1)
echo "🚀 Primary MongoDB Sunucusu Başlatılıyor..."
MONGO_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name emir-dns-project-key \
    --security-group-ids $DB_SG \
    --subnet-id $PRI_SUB_1 \
    --user-data $USER_DATA_B64 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MongoDB-Primary}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "✅ Primary MongoDB Oluşturuldu: $MONGO_ID"

# 5. MongoDB Secondary Sunucusunu Başlat (Private Subnet 2 - Bonus Multi-AZ)
echo "🚀 Secondary (Replica) MongoDB Sunucusu Başlatılıyor..."
MONGO_SEC_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name emir-dns-project-key \
    --security-group-ids $DB_SG \
    --subnet-id $PRI_SUB_2 \
    --user-data $USER_DATA_B64 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MongoDB-Secondary}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "✅ Secondary MongoDB Oluşturuldu: $MONGO_SEC_ID"
echo "🎉 Veritabanı Katmanı Hazır!"