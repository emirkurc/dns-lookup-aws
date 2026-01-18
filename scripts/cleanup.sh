#!/bin/bash
echo "Cleaning up resources..."
# Uyarı: Bu script tüm kaynakları siler!
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name emir-dns-asg-final --force-delete
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elbv2:...
echo "Cleanup complete."
