#!/bin/bash
# ------------------------------------------------------------------
# [mongodb-userdata.sh]
# MongoDB Sunucusu Başlangıç Scripti (Ubuntu)
# ------------------------------------------------------------------

# Logları kaydet (Hata ayıklama için)
exec > >(tee /var/log/user-data.log|logger -t user-data -s) 2>&1
echo "🍃 MongoDB Kurulumu Başlıyor..."

# 1. Sistem Güncelleme ve Docker Kurulumu
apt-get update -y
apt-get install -y docker.io

# 2. Docker Servisini Başlat
systemctl start docker
systemctl enable docker

# 3. MongoDB Konteynerini Başlat
# - Root yetkileri ile (admin/StrongPassword123!)
# - Veriler /data/db klasöründe kalıcı hale getirilir (Volume Mapping)
# - --restart always ile sunucu kapanıp açılsa bile devreye girer.
docker run -d -p 27017:27017 \
  --name mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=StrongPassword123! \
  -v mongodb_data:/data/db \
  --restart always \
  mongo:4.4

echo "✅ MongoDB Başarıyla Başlatıldı."