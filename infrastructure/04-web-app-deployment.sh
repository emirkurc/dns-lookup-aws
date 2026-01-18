# Deployment Rehberi 🛠️

Bu projeyi sıfırdan kurmak için aşağıdaki adımları izleyin.

### Gereksinimler
* AWS CLI (v2)
* Docker & Docker Compose (Local test için)
* Git

### Adım 1: Altyapı Kurulumu
Altyapı scriptlerini sırasıyla çalıştırın:
\\\ash
./infrastructure/01-vpc-setup.sh
./infrastructure/02-security-groups.sh
\\\

### Adım 2: Veritabanı
MongoDB sunucusunu Private Subnet'te başlatın:
\\\ash
./infrastructure/03-mongodb-deployment.sh
\\\

### Adım 3: Web Uygulaması ve Scaling
Launch Template ve ASG kurulumu:
\\\ash
./infrastructure/04-web-app-deployment.sh
./infrastructure/06-auto-scaling.sh
\\\

### Adım 4: Monitoring ve Güvenlik
\\\ash
./infrastructure/07-monitoring.sh
\\\
"@
 | Out-File "DEPLOYMENT-GUIDE.md" -Encoding UTF8


# ---------------------------------------------------------
# 2. APPLICATION (.env.example)
# ---------------------------------------------------------
"MONGO_HOST=mongodb_ip_address
MONGO_PORT=27017
MONGO_USER=admin
MONGO_PASS=password123" | Out-File "application/.env.example" -Encoding UTF8


# ---------------------------------------------------------
# 3. INFRASTRUCTURE SCRIPTS (Eksik Olanlar)
# ---------------------------------------------------------

# 04-web-app-deployment.sh
@"
#!/bin/bash
# Launch Template Oluşturma Scripti
aws ec2 create-launch-template \
    --launch-template-name emir-dns-template-final \
    --launch-template-data file://lt-config.json
echo "Web App Launch Template oluşturuldu."
