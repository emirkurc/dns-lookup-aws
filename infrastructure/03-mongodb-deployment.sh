#!/bin/bash
# 03-mongodb-deployment.sh
# Amaç: Private Subnet içinde MongoDB sunucusunu baþlatmak

echo "MongoDB Deployment Baþlýyor..."

# Deðiþkenler (Önceki adýmlardan gelmeli veya elle girilmeli)
# AMI_ID: Ubuntu 22.04 (us-east-1)
AMI_ID="ami-0c7217cdde317cfec"

# EC2 Baþlatma
MONGO_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t3.small \
    --key-name emir-dns-project-key \
    --subnet-id $PRIV_SUB1 \
    --security-group-ids $DB_SG \
    --user-data file://../scripts/mongodb-userdata.sh \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp3\"}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=MongoDB-Server}]" \
    --query "Instances[0].InstanceId" \
    --output text)

echo "MongoDB Sunucusu Baþlatýldý: $MONGO_ID"
echo "Özel IP adresi bekleniyor..."
aws ec2 wait instance-running --instance-ids $MONGO_ID
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $MONGO_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
echo "MongoDB Private IP: $PRIVATE_IP"

