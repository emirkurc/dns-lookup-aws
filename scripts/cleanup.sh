#!/bin/bash
# ------------------------------------------------------------------
# [cleanup.sh]
# Tüm AWS Kaynaklarını Temizleme Scripti
# UYARI: Bu işlem geri alınamaz!
# ------------------------------------------------------------------

echo "⚠️ DİKKAT: Proje kaynakları siliniyor..."

# 1. Load Balancer ve ASG Sil
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name emir-dns-asg-final --force-delete
aws elbv2 delete-load-balancer --load-balancer-arn $(aws elbv2 describe-load-balancers --names emir-dns-alb --query "LoadBalancers[0].LoadBalancerArn" --output text)
aws elbv2 delete-target-group --target-group-arn $(aws elbv2 describe-target-groups --names emir-dns-target-group --query "TargetGroups[0].TargetGroupArn" --output text)

# 2. EC2 Sunucuları (MongoDB)
IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=MongoDB*" --query "Reservations[].Instances[].InstanceId" --output text)
aws ec2 terminate-instances --instance-ids $IDS

# 3. NAT Gateway (En Pahalısı)
NAT_ID=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=emir-dns-nat-gw" --query "NatGateways[0].NatGatewayId" --output text)
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID

echo "⏳ Kaynakların silinmesi birkaç dakika sürebilir. Lütfen konsoldan VPC'yi de manuel silmeyi unutmayın."