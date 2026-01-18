#!/bin/bash
# Load Balancer ve Target Group Kurulumu
aws elbv2 create-load-balancer --name emir-dns-alb --subnets subnet-1 subnet-2 --security-groups sg-123
aws elbv2 create-target-group --name emir-dns-target-group --protocol HTTP --port 5889 --vpc-id vpc-123
echo "ALB ve Target Group hazır."
