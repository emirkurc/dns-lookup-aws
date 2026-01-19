#!/bin/bash
# ------------------------------------------------------------------
# [04-web-app-deployment.sh]
# Web Uygulaması Launch Template ve IAM Rolü Kurulumu
# ------------------------------------------------------------------

echo "💻 Web App Deployment Hazırlığı Başlıyor..."

# 1. Dinamik Değişkenler
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=emir-dns-project-vpc" --query "Vpcs[0].VpcId" --output text)
WEB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=Web-SG" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text)
# MongoDB IP'sini bul (Primary sunucunun Private IP'si)
MONGO_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=MongoDB-Primary" "Name=instance-state-name,Values=running,pending" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
AMI_ID="ami-0c7217cdde317cfec" # Amazon Linux 2023

if [ -z "$MONGO_IP" ]; then
    echo "⚠️ UYARI: MongoDB IP'si bulunamadı. 'localhost' kullanılacak (Hata verebilir)."
    MONGO_IP="localhost"
else
    echo "   📍 MongoDB Host: $MONGO_IP"
fi

# 2. IAM Rolü Oluştur (Secrets Manager ve CloudWatch yetkisi için)
echo "🔑 IAM Rolü ve Instance Profile Oluşturuluyor..."
ROLE_NAME="emir-dns-project-role"
PROFILE_NAME="emir-dns-project-profile"

# Trust Policy (EC2 bu rolü kullanabilsin)
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
EOF

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json 2>/dev/null
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Instance Profile Oluştur ve Role Bağla
aws iam create-instance-profile --instance-profile-name $PROFILE_NAME 2>/dev/null
aws iam add-role-to-instance-profile --instance-profile-name $PROFILE_NAME --role-name $ROLE_NAME 2>/dev/null
# Rolün aktifleşmesi için kısa bir bekleme
sleep 10
rm trust-policy.json

# 3. User Data Script Hazırlığı
# Burada app.py ve docker dosyalarını direkt sunucuya gömüyoruz.
# Bu sayede 'git clone' auth hatası yaşamadan %100 çalışmasını garanti ediyoruz.
echo "📜 User Data Script Hazırlanıyor..."

# Uygulama Kodunu (app.py) Base64 yapıyoruz ki script içinde bozulmasın
# (Not: Buradaki kod application/app.py'nin aynısıdır)
APP_PY_CONTENT=$(cat ../application/app.py | base64 -w 0)
REQ_TXT_CONTENT=$(cat ../application/requirements.txt | base64 -w 0)
DOCKER_CONTENT=$(cat ../application/Dockerfile | base64 -w 0)
HTML_CONTENT=$(cat ../application/templates/index.html | base64 -w 0)

# UserData Scriptin Kendisi
cat > web-userdata.sh <<EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s) 2>&1

# 1. Docker Kurulumu
yum update -y
yum install -y docker python3-pip
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

# Docker Compose Kurulumu
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 2. Dosyaları Oluştur
mkdir -p /app/application/templates
cd /app/application

echo "$APP_PY_CONTENT" | base64 -d > app.py
echo "$REQ_TXT_CONTENT" | base64 -d > requirements.txt
echo "$DOCKER_CONTENT" | base64 -d > Dockerfile
echo "$HTML_CONTENT" | base64 -d > templates/index.html

# 3. Docker Compose Dosyasını Oluştur (Ortam Değişkenleri ile)
cat > docker-compose.yml <<YAML
version: '3'
services:
  web:
    build: .
    ports:
      - "5889:5889"
    environment:
      - MONGO_HOST=$MONGO_IP
      - MONGO_PORT=27017
      - AWS_REGION=us-east-1
      - MONGO_USER=admin
    logging:
      driver: awslogs
      options:
        awslogs-region: us-east-1
        awslogs-group: /aws/ec2/web-application
        awslogs-stream: web-container
        awslogs-create-group: "true"
    restart: always
YAML

# 4. Başlat
docker-compose up -d --build
EOF

# Tüm scripti Base64 yap (Launch Template için)
USER_DATA_FINAL=$(cat web-userdata.sh | base64 -w 0)
rm web-userdata.sh

# 4. Launch Template Oluştur
echo "🚀 Launch Template Oluşturuluyor..."
aws ec2 create-launch-template \
    --launch-template-name emir-dns-template-final \
    --version-description "v1 Production Ready" \
    --launch-template-data "{
        \"ImageId\": \"$AMI_ID\",
        \"InstanceType\": \"t3.small\",
        \"KeyName\": \"emir-dns-project-key\",
        \"UserData\": \"$USER_DATA_FINAL\",
        \"SecurityGroupIds\": [\"$WEB_SG\"],
        \"IamInstanceProfile\": { \"Name\": \"$PROFILE_NAME\" },
        \"TagSpecifications\": [{ \"ResourceType\": \"instance\", \"Tags\": [{ \"Key\": \"Name\", \"Value\": \"Web-ASG-Node\" }] }]
    }"

echo "🎉 Launch Template Başarıyla Oluşturuldu!"