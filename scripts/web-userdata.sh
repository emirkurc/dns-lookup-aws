#!/bin/bash
# ------------------------------------------------------------------
# [web-userdata.sh]
# Web Uygulama Sunucusu Başlangıç Scripti (Amazon Linux 2023)
# ------------------------------------------------------------------

# Loglama ayarı (/var/log/user-data.log dosyasına yazar)
exec > >(tee /var/log/user-data.log|logger -t user-data -s) 2>&1
echo "🚀 Web App Kurulumu Başlıyor..."

# 1. Paketlerin Yüklenmesi
yum update -y
yum install -y docker python3-pip git

# 2. Docker Servisinin Başlatılması
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

# 3. Docker Compose Kurulumu
# Amazon Linux reposunda native olmadığı için binary'den kuruyoruz.
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 4. Uygulama Dizinini Hazırla
mkdir -p /app/application
cd /app/application

# NOT: Gerçek deployment sırasında bu dosyalar (app.py, Dockerfile vb.)
# 04-web-app-deployment.sh tarafından Base64 decode edilerek buraya yazılır.
# Bu script referans amaçlıdır.

# 5. Konteynerleri Ayağa Kaldır
# Secrets Manager ve CloudWatch Log Driver entegrasyonu ile başlatır.
docker-compose up -d --build

echo "✅ Web Uygulaması Başlatıldı."