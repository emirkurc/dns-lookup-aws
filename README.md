# ☁️ AWS Scalable DNS Lookup Web Application

![AWS](https://img.shields.io/badge/AWS-Cloud-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.9-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-2.0-000000?style=for-the-badge&logo=flask&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Container-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-Database-47A248?style=for-the-badge&logo=mongodb&logoColor=white)

Bu proje, **Sanallaştırma ve Bulut Teknolojileri** dersi dönem ödevi kapsamında geliştirilmiştir. Amazon Web Services (AWS) üzerinde çalışan, yüksek erişilebilirliğe (High Availability) sahip, hataya dayanıklı (Fault Tolerant) ve otomatik ölçeklenebilir (Auto Scalable) bir DNS sorgulama mimarisidir.

---

## 🎯 Proje Amacı ve Kapsamı

Projenin temel amacı, kullanıcıların domain adreslerini (örn: `google.com`) sorgulayarak **A kayıtlarını (IP adresleri)** öğrendiği ve bu sorgu geçmişinin güvenli bir veritabanında saklandığı modern bir web platformu oluşturmaktır.

Ancak projenin asıl odak noktası sadece kodlama değil, **Endüstri Standartlarında Bulut Mimarisi** tasarlamaktır. Bu kapsamda aşağıdaki DevOps prensipleri uygulanmıştır:
* **Infrastructure as Code (IaC):** Tüm altyapı Bash scriptleri ile otomatize edilmiştir.
* **Security by Design:** "Least Privilege" ve "Network Isolation" prensipleri uygulanmıştır.
* **Stateless Architecture:** Uygulama sunucuları herhangi bir durum (state) tutmaz, bu sayede kolayca ölçeklenebilir.

---

## 🏗️ Mimari Tasarım

Proje, AWS Well-Architected Framework'ün 5 sütununa (Security, Reliability, Performance, Cost, Operational Excellence) uygun olarak tasarlanmıştır.

### 1. Network Katmanı (VPC & Isolation)
* **VPC:** `10.0.0.0/16` bloğunda izole bir sanal ağ oluşturulmuştur.
* **Public Subnets:** Load Balancer ve NAT Gateway gibi dış dünyaya açılması gereken bileşenler buradadır.
* **Private Subnets:** Uygulama sunucuları ve Veritabanı burada barınır. Dış dünyadan doğrudan erişim engellenmiştir (Security Hardening).

### 2. Compute Katmanı (Auto Scaling & Docker)
* **EC2 & Docker:** Uygulama, `t3.small` sunucular üzerinde Docker konteynerleri olarak çalışır. Bu sayede "Dependency Hell" sorunu ortadan kaldırılmıştır.
* **Auto Scaling Group (ASG):** Trafik arttığında (CPU > %70) sistem otomatik olarak yeni sunucular ekler, trafik azaldığında sunucuları kapatır (Cost Optimization).

### 3. Veri Katmanı (Database & Persistence)
* **MongoDB:** Veritabanı Private Subnet içerisinde çalışır.
* **Multi-AZ Deployment:** Veri güvenliği için Primary sunucu `us-east-1a` bölgesinde, Replica (Yedek) sunucu `us-east-1b` bölgesindedir. Bir veri merkezi çökse bile sistem çalışmaya devam eder.
* **Secrets Manager:** Veritabanı şifreleri kod içinde (Hard-coded) değil, AWS Secrets Manager kasasında şifreli olarak saklanır.

### 4. Trafik Yönetimi ve Güvenlik
* **Application Load Balancer (ALB):** Gelen trafiği sağlıklı sunuculara dağıtır. `/health` endpoint'i üzerinden sunucuları sürekli kontrol eder.
* **AWS WAF (Web Application Firewall):** ALB önünde konumlanarak SQL Injection ve DDoS saldırılarını engeller. Rate Limiting kuralı ile IP başına istek sınırı uygulanmıştır.

---

## 🛠️ Teknoloji Yığını (Tech Stack)

| Bileşen | Teknoloji / Servis | Açıklama |
| :--- | :--- | :--- |
| **Backend** | Python Flask | RESTful API ve Web Arayüzü |
| **Database** | MongoDB | NoSQL Veri Depolama |
| **Container** | Docker & Compose | Uygulama Sanallaştırma |
| **Orchestration** | AWS Auto Scaling | Otomatik Ölçekleme |
| **Network** | VPC, NAT Gateway | Ağ İzolasyonu |
| **Security** | WAF, Security Groups | Ağ Güvenliği |
| **Monitoring** | CloudWatch | Loglama ve Alarm Yönetimi |
| **IaC** | Bash Scripting | Altyapı Otomasyonu |

---

## 📂 Proje Klasör Yapısı

```bash
dns-lookup-aws/
├── application/                 # Uygulama kaynak kodları
│   ├── app.py                   # Flask ana dosyası
│   ├── Dockerfile               # Container imaj tanımı
│   ├── docker-compose.yml       # Servis orkestrasyonu
│   └── requirements.txt         # Python kütüphaneleri
├── infrastructure/              # AWS Altyapı kurulum scriptleri
│   ├── 01-vpc-setup.sh          # Network kurulumu
│   ├── 02-security-groups.sh    # Güvenlik duvarları
│   ├── ...                      # Diğer scriptler
├── scripts/                     # Helper ve UserData scriptleri
├── docs/                        # Dokümantasyon ve Kanıtlar
│   ├── architecture-diagram.png # Mimari şeması
│   ├── screenshots/             # Çalışma anı görüntüleri
│   └── troubleshooting.md       # Sorun giderme notları
└── README.md                    # Proje ana dokümanı

## Kurulum ve Çalıştırma
Projenin kurulumu tamamen otomatize edilmiştir. Detaylı kurulum adımları için lütfen DEPLOYMENT-GUIDE.md dosyasını inceleyiniz.

Hızlı Başlangıç:
* **Repoyu klonlayın.**
* **infrastructure/ klasöründeki scriptleri sırasıyla çalıştırın.**
* **Load Balancer DNS adresine gidin.**