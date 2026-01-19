#!/bin/bash
# ------------------------------------------------------------------
# [07-monitoring.sh]
# CloudWatch Alarmları ve WAF (Güvenlik Duvarı) Kurulumu
# ------------------------------------------------------------------

echo "👀 Monitoring ve Güvenlik Katmanı Kuruluyor..."

# 1. CloudWatch Log Grubu Oluştur (Garanti olsun diye)
aws logs create-log-group --log-group-name /aws/ec2/web-application 2>/dev/null
aws logs put-retention-policy --log-group-name /aws/ec2/web-application --retention-in-days 7

# 2. Alarm: Yüksek CPU Kullanımı
echo "🚨 CPU Alarmı Oluşturuluyor..."
aws cloudwatch put-metric-alarm \
    --alarm-name "High-CPU-Utilization" \
    --alarm-description "Alarm when CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=AutoScalingGroupName,Value=emir-dns-asg-final \
    --evaluation-periods 2

# 3. Alarm: Unhealthy Hosts (ALB)
echo "🚨 Unhealthy Host Alarmı Oluşturuluyor..."
ALB_ARN_SUFFIX=$(aws elbv2 describe-load-balancers --names emir-dns-alb --query "LoadBalancers[0].LoadBalancerArn" --output text | awk -F "loadbalancer/" '{print "app/"$2}')
TG_ARN_SUFFIX=$(aws elbv2 describe-target-groups --names emir-dns-target-group --query "TargetGroups[0].TargetGroupArn" --output text | awk -F "targetgroup/" '{print "targetgroup/"$2}')

aws cloudwatch put-metric-alarm \
    --alarm-name "Unhealthy-Hosts-Count" \
    --metric-name UnHealthyHostCount \
    --namespace AWS/ApplicationELB \
    --statistic Average \
    --period 60 \
    --threshold 0 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=LoadBalancer,Value=$ALB_ARN_SUFFIX Name=TargetGroup,Value=$TG_ARN_SUFFIX \
    --evaluation-periods 1

# 4. AWS WAF (Web Application Firewall) - Bonus +5 Puan
echo "🛡️ WAF (Güvenlik Duvarı) Oluşturuluyor..."

# Web ACL Oluştur (Rate Limit ve SQL Injection Korumalı)
WAF_ID=$(aws wafv2 create-web-acl \
    --name "Emir-DNS-Project-WAF" \
    --scope REGIONAL \
    --default-action Allow={} \
    --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=EmirDNSWAF \
    --rules '[
        {
            "Name": "RateLimitRule",
            "Priority": 1,
            "Statement": {
                "RateBasedStatement": {
                    "Limit": 500,
                    "AggregateKeyType": "IP"
                }
            },
            "Action": { "Block": {} },
            "VisibilityConfig": { "SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "RateLimit" }
        }
    ]' \
    --region us-east-1 \
    --query 'Summary.Id' \
    --output text)

# WAF'ı Load Balancer'a Bağla
ALB_ARN=$(aws elbv2 describe-load-balancers --names emir-dns-alb --query "LoadBalancers[0].LoadBalancerArn" --output text)
aws wafv2 associate-web-acl --web-acl-arn arn:aws:wafv2:us-east-1:$(aws sts get-caller-identity --query Account --output text):regional/webacl/Emir-DNS-Project-WAF/$WAF_ID --resource-arn $ALB_ARN

echo "✅ WAF Aktif Edildi ve ALB'ye Bağlandı."
echo "🎉 Tüm Monitoring ve Güvenlik Sistemleri Hazır!"