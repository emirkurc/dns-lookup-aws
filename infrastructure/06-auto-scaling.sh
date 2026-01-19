#!/bin/bash
# ------------------------------------------------------------------
# [06-auto-scaling.sh]
# Auto Scaling Group (ASG) ve Scaling Policy Kurulumu
# ------------------------------------------------------------------

echo "📈 Auto Scaling Kurulumu Başlıyor..."

# 1. Dinamik Değişkenler
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=emir-dns-project-vpc" --query "Vpcs[0].VpcId" --output text)
# Web sunucuları Public Subnet'te olacak (Mimari gereği)
PUB_SUB_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Public-Subnet-1" --query "Subnets[0].SubnetId" --output text)
PUB_SUB_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Public-Subnet-2" --query "Subnets[0].SubnetId" --output text)
TG_ARN=$(aws elbv2 describe-target-groups --names emir-dns-target-group --query "TargetGroups[0].TargetGroupArn" --output text)
LAUNCH_TEMPLATE_ID=$(aws ec2 describe-launch-templates --launch-template-names emir-dns-template-final --query "LaunchTemplates[0].LaunchTemplateId" --output text)

echo "   📍 Launch Template ID: $LAUNCH_TEMPLATE_ID"
echo "   📍 Target Group ARN: $TG_ARN"

# 2. Auto Scaling Group (ASG) Oluştur
# Min: 2, Max: 6, Desired: 2
echo "🚀 ASG Oluşturuluyor..."
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name emir-dns-asg-final \
    --launch-template "LaunchTemplateId=$LAUNCH_TEMPLATE_ID,Version=\$Latest" \
    --min-size 2 \
    --max-size 6 \
    --desired-capacity 2 \
    --vpc-zone-identifier "$PUB_SUB_1,$PUB_SUB_2" \
    --target-group-arns $TG_ARN \
    --health-check-type ELB \
    --health-check-grace-period 300

echo "✅ ASG 'emir-dns-asg-final' oluşturuldu."

# 3. Scaling Policy (Büyüme Kuralı)
# CPU %70'i geçerse sunucu ekle.
echo "📏 Scaling Policy (CPU > 70%) Ekleniyor..."
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name emir-dns-asg-final \
    --policy-name TargetTracking-CPU70 \
    --policy-type TargetTrackingScaling \
    --target-tracking-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ASGAverageCPUUtilization"
        },
        "TargetValue": 70.0
    }'

echo "🎉 Auto Scaling Sistemi Aktif!"