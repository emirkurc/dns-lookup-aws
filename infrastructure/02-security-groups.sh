#!/bin/bash
# ------------------------------------------------------------------
# [02-security-groups.sh]
# Security Group (Güvenlik Duvarı) Kurulumu
# ------------------------------------------------------------------

echo "🛡️ Security Groups Oluşturuluyor..."

# VPC ID'yi bul
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=emir-dns-project-vpc" --query "Vpcs[0].VpcId" --output text)

if [ -z "$VPC_ID" ]; then
    echo "❌ HATA: VPC bulunamadı. Önce 01-vpc-setup.sh çalıştırılmalı."
    exit 1
fi

# 1. Load Balancer SG (ALB-SG)
# İnternetten gelen HTTP (80) isteklerini kabul eder.
ALB_SG=$(aws ec2 create-security-group --group-name ALB-SG --description "Allow HTTP from Internet" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 create-tags --resources $ALB_SG --tags Key=Name,Value=ALB-SG
echo "✅ ALB-SG Oluşturuldu: $ALB_SG"

# 2. Web Server SG (Web-SG)
# Sadece ALB'den gelen trafiği kabul eder (Port 5889).
WEB_SG=$(aws ec2 create-security-group --group-name Web-SG --description "Allow traffic from ALB" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $WEB_SG --protocol tcp --port 5889 --source-group $ALB_SG
# SSH İzni (Opsiyonel - Debug için kendi IP'nizi verebilirsiniz, şimdilik kapalı güvenli)
# aws ec2 authorize-security-group-ingress --group-id $WEB_SG --protocol tcp --port 22 --cidr 0.0.0.0/0 
aws ec2 create-tags --resources $WEB_SG --tags Key=Name,Value=Web-SG
echo "✅ Web-SG Oluşturuldu: $WEB_SG"

# 3. MongoDB SG (MongoDB-SG)
# Sadece Web Sunucularından gelen trafiği kabul eder (Port 27017).
DB_SG=$(aws ec2 create-security-group --group-name MongoDB-SG --description "Allow traffic from Web App" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $DB_SG --protocol tcp --port 27017 --source-group $WEB_SG
aws ec2 create-tags --resources $DB_SG --tags Key=Name,Value=MongoDB-SG
echo "✅ MongoDB-SG Oluşturuldu: $DB_SG"

echo "🎉 Güvenlik Grupları Hazır!"