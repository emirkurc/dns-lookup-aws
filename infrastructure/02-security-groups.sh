#!/bin/bash
# 02-security-groups.sh
# Amaç: Load Balancer, Web Sunucusu ve MongoDB için güvenlik duvarlarýný kurmak

echo "Güvenlik Gruplarý Oluþturuluyor..."

# 1. ALB Security Group (Herkese Açýk)
ALB_SG=$(aws ec2 create-security-group --group-name ALB-SG --description "ALB Security Group" --vpc-id $VPC_ID --query "GroupId" --output text)
aws ec2 create-tags --resources $ALB_SG --tags Key=Name,Value=ALB-SG
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "ALB SG Oluþturuldu: $ALB_SG"

# 2. Web Server Security Group (Sadece ALB"ye Açýk)
WEB_SG=$(aws ec2 create-security-group --group-name Web-SG --description "Web Server Security Group" --vpc-id $VPC_ID --query "GroupId" --output text)
aws ec2 create-tags --resources $WEB_SG --tags Key=Name,Value=Web-SG
aws ec2 authorize-security-group-ingress --group-id $WEB_SG --protocol tcp --port 5889 --source-group $ALB_SG
# Yönetim için SSH (Opsiyonel/Geçici)
aws ec2 authorize-security-group-ingress --group-id $WEB_SG --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Web SG Oluþturuldu: $WEB_SG"

# 3. MongoDB Security Group (Sadece Web Server"a Açýk - Private)
DB_SG=$(aws ec2 create-security-group --group-name Mongo-SG --description "MongoDB Security Group" --vpc-id $VPC_ID --query "GroupId" --output text)
aws ec2 create-tags --resources $DB_SG --tags Key=Name,Value=Mongo-SG
aws ec2 authorize-security-group-ingress --group-id $DB_SG --protocol tcp --port 27017 --source-group $WEB_SG
echo "MongoDB SG Oluþturuldu: $DB_SG"

