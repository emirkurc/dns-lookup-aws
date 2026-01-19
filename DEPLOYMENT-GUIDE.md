# 🛠️ Deployment Guide (Kurulum Rehberi)

Bu doküman, DNS Lookup uygulamasının AWS üzerine sıfırdan kurulması için gerekli tüm adımları içerir. Kurulum süreci **Infrastructure as Code (IaC)** prensibiyle bash scriptleri üzerinden yürütülür.

---

## 📋 Ön Hazırlıklar (Prerequisites)

Kuruluma başlamadan önce aşağıdaki araçların bilgisayarınızda kurulu olması gerekmektedir:

1.  **AWS CLI (v2):** AWS komut satırı aracı.
    * Kurulum kontrolü: `aws --version`
2.  **Konfigürasyon:** AWS hesabınıza yetkili bir kullanıcı ile giriş yapılmış olmalı.
    * Komut: `aws configure`
    * Region: `us-east-1` (N. Virginia)
3.  **EC2 Key Pair:** Sunuculara SSH ile bağlanmak için anahtar.
    * İsim: `emir-dns-project-key`
    * Format: `.pem`

---

## 🚀 Adım Adım Kurulum (Step-by-Step Installation)

### Adım 1: Ağ Altyapısının Kurulumu (VPC Setup)
Bu script; VPC, Public/Private Subnetler, Internet Gateway, NAT Gateway ve Route Table'ları oluşturur.


./infrastructure/01-vpc-setup.sh

Beklenen Sonuç: emir-dns-project-vpc isminde bir VPC ve 4 adet subnet (2 Public, 2 Private) oluşmalıdır.

### Adım 2: Güvenlik Grupları (Security Groups)
Sunucular arası izolasyonu sağlayan güvenlik duvarlarını tanımlar.
./infrastructure/02-security-groups.sh

Oluşan Gruplar:

ALB-SG: Sadece Port 80 (HTTP) açık.
Web-SG: Sadece ALB'den gelen trafiğe açık.
MongoDB-SG: Sadece Web sunucularından gelen trafiğe açık (Port 27017).

### Adım 3: Veritabanı Kurulumu (Database Deployment)
Private Subnet içerisine MongoDB sunucusunu ve Replica (Yedek) sunucuyu kurar.
./infrastructure/03-mongodb-deployment.sh

Bu işlem sırasında UserData scripti çalışarak Docker ve MongoDB'yi otomatik başlatır.

### Adım 4: Web Uygulaması ve Auto Scaling
Uygulama sunucuları için "Launch Template" oluşturur ve CPU kullanımına göre ölçeklenen Auto Scaling Grubu'nu başlatır.

./infrastructure/04-web-app-deployment.sh
./infrastructure/06-auto-scaling.sh

Web sunucuları açılırken AWS Secrets Manager'dan veritabanı şifresini otomatik çeker.

### Adım 5: Load Balancer (ALB)
Gelen trafiği karşılayacak ve sunuculara dağıtacak olan Load Balancer'ı kurar.
./infrastructure/05-load-balancer.sh

Erişim: Script sonunda size bir DNS adresi (örn: emir-dns-alb-12345.us-east-1.elb.amazonaws.com) verecektir.

### Adım 6: Monitoring ve Güvenlik (Final)
CloudWatch Alarmları, Log Grupları ve WAF (Web Application Firewall) kurallarını aktif eder.
./infrastructure/07-monitoring.sh


## Doğrulama ve Test
Kurulum bittikten sonra sistemin çalıştığını doğrulamak için:

1-Web Arayüzü: Load Balancer DNS adresini tarayıcıda açın.

2-Sorgu Testi: google.com gibi bir domain girip "Lookup" butonuna basın. Sonuçlar listelenmelidir.

3-Health Check: Tarayıcıda adresin sonuna /health ekleyin. {"status": "healthy"} yanıtı dönmelidir.

## Kaynakların Temizlenmesi (Cleanup)
Test işlemleri bittikten sonra maliyet oluşmaması için tüm kaynakları silebilirsiniz:

./scripts/cleanup.sh
UYARI: Bu işlem veritabanı dahil tüm kaynakları kalıcı olarak siler!


