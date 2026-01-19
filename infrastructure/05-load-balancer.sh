#!/bin/bash
# ------------------------------------------------------------------
# [05-load-balancer.sh]
# Application Load Balancer (ALB) ve Target Group Kurulumu
# ------------------------------------------------------------------

echo "⚖️ Load Balancer Kurulumu Başlıyor..."

# 1. Dinamik Değişkenler (Otomatik Bulur)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=emir-dns-project-vpc" --query "Vpcs[0].VpcId" --output text)
PUB_SUB_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Public-Subnet-1" --query "Subnets[0].SubnetId" --output text)
PUB_SUB_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Public-Subnet-2" --query "Subnets[0].SubnetId" --output text)
ALB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ALB-SG" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text)

echo "   📍 Subnets: $PUB_SUB_1, $PUB_SUB_2"
echo "   📍 Security Group: $ALB_SG"

# 2. Target Group Oluştur
# Load Balancer trafiği nereye yönlendirecek? (Port 5889)
echo "🎯 Target Group Oluşturuluyor..."
TG_ARN=$(aws elbv2 create-target-group \
    --name emir-dns-target-group \
    --protocol HTTP \
    --port 5889 \
    --vpc-id $VPC_ID \
    --health-check-protocol HTTP \
    --health-check-path "/health" \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --target-type instance \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "✅ Target Group Hazır: $TG_ARN"

# 3. Load Balancer (ALB) Oluştur
echo "⚖️ ALB Oluşturuluyor (Biraz zaman alabilir)..."
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name emir-dns-alb \
    --subnets $PUB_SUB_1 $PUB_SUB_2 \
    --security-groups $ALB_SG \
    --scheme internet-facing \
    --type application \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo "✅ ALB Oluşturuldu: $ALB_ARN"

# 4. Listener Oluştur (Port 80 -> Target Group)
# Dışarıdan gelen HTTP isteklerini Target Group'a bağlar.
echo "👂 Listener Ekleniyor..."
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN > /dev/null

# 5. DNS Adresini Göster
DNS_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query "LoadBalancers[0].DNSName" --output text)
echo "🎉 Load Balancer Hazır!"
echo "🌍 Web Sitesi Adresi: http://$DNS_NAME"