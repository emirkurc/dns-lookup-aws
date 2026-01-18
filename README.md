# AWS Scalable DNS Lookup Project 🚀

Bu proje, Python Flask ile geliştirilmiş, AWS üzerinde çalışan, yüksek erişilebilirliğe sahip ve güvenli bir DNS sorgulama uygulamasıdır. Sanallaştırma ve Bulut Bilişim Teknolojileri dersi dönem ödevi olarak hazırlanmıştır.

## 🌟 Özellikler
* **Frontend/Backend:** Python Flask + Docker
* **Database:** MongoDB (Private Subnet, Persistent Volume)
* **Security:** AWS WAF, Secrets Manager, Private Subnets, Security Groups
* **Scaling:** Application Load Balancer + Auto Scaling Group
* **Monitoring:** CloudWatch Logs, Alarms, Dashboard

## 🏗️ Mimari
Proje **Multi-AZ** mimarisi kullanılarak tasarlanmıştır:
* **Public Subnetler:** ALB ve NAT Gateway barındırır.
* **Private Subnetler:** Uygulama sunucuları ve Veritabanı (MongoDB) barındırır.
* **Güvenlik:** WAF ile SQL Injection ve Rate Limit koruması sağlanmıştır.

## 🔗 Canlı Demo (Opsiyonel)
**Load Balancer URL:** http://emir-dns-alb-123456789.us-east-1.elb.amazonaws.com (Örnek)

## 🛠️ Kurulum
1. **Altyapı:** infrastructure/ klasöründeki scriptler sırasıyla çalıştırılır.
2. **Uygulama:** UserData scriptleri EC2 açılışında Docker'ı başlatır.
3. **Konfigürasyon:** .env dosyası veya Secrets Manager kullanılır.

## 🏆 Tamamlanan Bonuslar
* ✅ **Multi-AZ MongoDB:** Yedeklilik için ikinci AZ'de Replica Node.
* ✅ **AWS WAF:** DDoS ve SQLi koruması.
* ✅ **Secrets Manager:** Şifre güvenliği.
* ✅ **ECR:** Docker imaj deposu.
* ✅ **Automated Backup:** Günlük disk yedeği.
* ✅ **CI/CD:** CodeBuild projesi altyapısı.
