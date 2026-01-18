#!/bin/bash
# Sistem Güncellemesi
apt-get update -y
apt-get upgrade -y

# Docker ve Git Kurulumu
apt-get install -y docker.io git
systemctl start docker
systemctl enable docker

# Projeyi GitHub"dan Çek
# DÝKKAT: Buradaki linki kendi repo adresimizle deðiþtireceðiz!
mkdir /app
cd /app
git clone https://github.com/KULLANICI_ADINIZ/REPO_ADINIZ.git .

# Uygulama Klasörüne Gir
cd application

# Docker Build & Run
# MongoDB IP adresini EC2"yu baþlatýrken "Environment" olarak vereceðiz ama 
# burada script içinde de dinamik alabiliriz. Þimdilik build alalým.
docker build -t dns-app .

# Uygulamayý Baþlat (Arka Planda)
# Not: MONGO_HOST deðiþkeni EC2 baþlatýlýrken UserData içine enjekte edilecek
# veya buraya elle yazýlacak.
docker run -d \
  --name web-app \
  --restart always \
  -p 5889:5889 \
  -e MONGO_HOST="MONGODB_PRIVATE_IP_ADRESI" \
  -e FLASK_PORT=5889 \
  dns-app

