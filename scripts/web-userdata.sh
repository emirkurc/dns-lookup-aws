#!/bin/bash
apt-get update -y
apt-get install -y docker.io git
systemctl start docker
systemctl enable docker
mkdir -p /app
cd /app
git clone https://github.com/emirr/dns-lookup-aws.git .
cd application
docker build -t dns-app .
# TEK SATIR (ONE-LINER) ÇALIÞAN KOMUT:
docker run -d --name web-app --restart always -p 5889:5889 -e MONGO_HOST="MONGODB_PRIVATE_IP_ADRESI" -e MONGO_USERNAME=admin -e MONGO_PASSWORD=secret -e FLASK_PORT=5889 dns-app
