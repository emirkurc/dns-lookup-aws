# Proje Mimarisi 🏛️

Bu proje, AWS Well-Architected Framework prensiplerine uygun olarak tasarlanmıştır.

## Bileşenler

### 1. Network (VPC)
* **CIDR:** 10.0.0.0/16
* **Subnetler:** 2 Public (Web), 2 Private (DB)
* **Gateway:** Internet Gateway (IGW) ve NAT Gateway (Private erişim için).

### 2. Compute (EC2 & Docker)
* **Web Tier:** Auto Scaling Group içinde çalışan t3.small sunucular. Docker container içinde Flask uygulaması çalışır.
* **Data Tier:** Private Subnet'te çalışan MongoDB sunucusu. Dış dünyadan izole edilmiştir.

### 3. Traffic Management
* **ALB:** Gelen trafiği sağlıklı sunuculara dağıtır. /health endpoint'ini kontrol eder.
* **WAF:** ALB önünde durarak kötü niyetli trafiği (SQLi, DDoS) engeller.

### 4. Security
* **Security Groups:** Sadece gerekli portlara izin veren least-privilege kurallar.
* **Secrets Manager:** Veritabanı şifreleri kod içinde değil, güvenli kasada saklanır.
