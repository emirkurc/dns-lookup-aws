# 🏛️ Mimari Tasarım ve Kararlar Dokümanı

Bu doküman, DNS Lookup projesinin altyapı tasarım kararlarını, bileşenlerin görevlerini ve güvenlik önlemlerini detaylandırır. Mimari, **AWS Well-Architected Framework** (Güvenlik, Güvenilirlik, Performans Verimliliği, Maliyet Optimizasyonu) prensiplerine göre kurgulanmıştır.

---

## 🏗️ Üst Düzey Mimari Bileşenleri

Sistem, tek bir başarısızlık noktasını (Single Point of Failure - SPOF) ortadan kaldırmak için **Multi-AZ (Çoklu Erişilebilirlik Bölgesi)** stratejisi kullanır.

### 1. Ağ Katmanı (VPC & Networking)
* **VPC CIDR:** `10.0.0.0/16` (Geniş adres uzayı, gelecekteki genişlemeler için).
* **Subnet Stratejisi:**
    * **Public Subnets (AZ1 & AZ2):** İnternet trafiğini karşılayan bileşenler (Load Balancer, NAT Gateway) burada bulunur.
    * **Private Subnets (AZ1 & AZ2):** Dış dünyadan izole edilmesi gereken bileşenler (Uygulama Sunucuları, Veritabanı) burada bulunur.
* **NAT Gateway:** Private Subnet'teki sunucuların güncelleme alabilmesi (outbound traffic) için gereklidir, ancak dışarıdan içeriye (inbound) trafiği engeller.

### 2. Uygulama Katmanı (Compute & Application)
* **Stateless Design:** Uygulama sunucuları (Web Tier) herhangi bir kullanıcı verisini veya oturum bilgisini yerel diskte tutmaz. Bu sayede sunucular istenildiği an kapatılıp yenisi açılabilir.
* **Containerization:** Uygulama Docker konteynerleri içinde izole çalışır. Bu, "benim makinemde çalışıyordu" sorununu çözer ve tutarlı bir ortam sağlar.
* **Auto Scaling Group (ASG):**
    * **Metric:** CPU Kullanımı > %70.
    * **Action:** Yeni bir EC2 instance başlat ve Load Balancer'a kaydet.
    * **Benefit:** Trafik arttığında performans düşmez, trafik azaldığında maliyet düşer.

### 3. Veri Katmanı (Data Persistence)
* **Teknoloji:** MongoDB (NoSQL).
* **Konum:** Private Subnet (En yüksek güvenlik seviyesi).
* **Erişim:** Sadece Web Sunucularının Security Group'undan gelen trafiği kabul eder (Port 27017).
* **High Availability:**
    * **Primary Node (us-east-1a):** Yazma ve okuma işlemlerini yapar.
    * **Secondary Node (us-east-1b):** Verilerin gerçek zamanlı kopyasını tutar (Replica Set). Primary çökerse devreye girer.

### 4. Güvenlik Katmanı (Security)
* **AWS WAF (Web Application Firewall):**
    * **SQL Injection Rule:** Zararlı SQL sorgularını engeller.
    * **Rate Limit:** 5 dakika içinde aynı IP'den gelen 500'den fazla isteği bloklar (DDoS koruması).
* **Secrets Manager:** Veritabanı kullanıcı adı ve şifresi kod içinde saklanmaz. Uygulama açılırken AWS API üzerinden bu bilgileri anlık çeker.
* **Security Groups:** "Least Privilege" prensibine göre sadece gerekli portlar (80, 5889, 27017) açılmıştır.

---

## 🔄 Veri Akış Diyagramı (Data Flow)

1.  **Kullanıcı** → DNS Sorgusu yapar (`http://load-balancer-url`).
2.  **Internet Gateway** → İsteği VPC içine alır.
3.  **ALB (Load Balancer)** → İsteği karşılar, WAF kurallarından geçirir ve en uygun (Healthy) Web Sunucusuna iletir.
4.  **Web Sunucusu (Docker)** → İsteği işler:
    * `dnspython` kütüphanesi ile domain'i sorgular.
    * Sonucu **MongoDB**'ye yazar.
5.  **MongoDB** → Kayıt işlemini onaylar.
6.  **Web Sunucusu** → Sonucu JSON/HTML olarak kullanıcıya döner.

---

## 📊 Kullanılan AWS Servisleri

| Servis | Görev | Gerekçe |
| :--- | :--- | :--- |
| **VPC** | Ağ İzolasyonu | Kaynakları güvenli bir sanal ağda tutmak için. |
| **EC2** | Sanal Sunucu | Uygulama ve veritabanını çalıştırmak için. |
| **ALB** | Yük Dengeleme | Trafiği sunuculara eşit dağıtmak için. |
| **Auto Scaling** | Otomatik Ölçekleme | Yük altında performans kaybını önlemek için. |
| **Secrets Manager** | Şifre Yönetimi | Hassas verileri korumak için. |
| **CloudWatch** | İzleme & Loglama | Sistem sağlığını takip etmek ve hata ayıklamak için. |
| **Backup** | Yedekleme | Veri kaybını önlemek için (Disaster Recovery). |

