#!/bin/bash
# Sistem Güncellemelerini Yap
apt-get update -y
apt-get upgrade -y

# Docker Kurulumu
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker Servisini Baþlat
systemctl start docker
systemctl enable docker

# MongoDB Containerý Baþlat (Authentication Açýk)
# Kullanýcý adý: admin, Þifre: secret (Projede bu þifreyi deðiþtireceðiz ama þimdilik test için kalsýn)
docker run -d \
  --name mongodb \
  --restart always \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  -v mongodb_data:/data/db \
  mongo:6.0

