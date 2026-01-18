#!/bin/bash
# CloudWatch Alarm ve Log Kurulumu
aws cloudwatch put-metric-alarm --alarm-name CPU-High --metric-name CPUUtilization --threshold 80
aws logs create-log-group --log-group-name /aws/ec2/web-application
echo "Monitoring aktif."
