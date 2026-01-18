#!/bin/bash
apt-get update -y
apt-get install -y docker.io git
systemctl start docker
systemctl enable docker
mkdir /app
cd /app
git clone https://github.com/emirr/dns-lookup-aws.git .
cd application
docker build -t dns-app .
# ÝÞTE DÜZELTÝLEN YER: Hepsi yan yana
docker run -d --name web-app --restart always -p 5889:5889 -e MONGO_HOST="10.0.11.128" -e FLASK_PORT=5889 dns-app
