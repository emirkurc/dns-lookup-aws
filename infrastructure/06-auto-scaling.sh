#!/bin/bash
# Auto Scaling Group Kurulumu
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name emir-dns-asg-final \
    --launch-template LaunchTemplateName=emir-dns-template-final \
    --min-size 2 --max-size 6 --desired-capacity 2 \
    --vpc-zone-identifier subnet-1,subnet-2
echo "ASG oluşturuldu."
