# Sorun Giderme (Troubleshooting) 🔧

Proje geliştirme sürecinde karşılaşılan hatalar ve çözümleri:

### 1. Target Group "Unhealthy" Durumu
**Sorun:** Load Balancer altındaki instance'lar "Unhealthy" görünüyordu.
**Analiz:** EC2 instance içine bağlanarak (Session Manager) \docker ps\ komutu çalıştırıldı. Container'ın sürekli restart ettiği görüldü.
**Sebep:** \wslogs\ sürücüsü konfigüre edilmişti ancak EC2 IAM rolünde \CloudWatchLogsFullAccess\ yetkisi eksikti. Bu yüzden Docker log yazamayıp çöküyordu.
**Çözüm:** IAM rolüne gerekli yetkiler eklendi ve user-data scripti güncellendi.

### 2. MongoDB Bağlantı Hatası
**Sorun:** Web uygulaması veritabanına bağlanamıyordu.
**Çözüm:** Security Group kuralları kontrol edildi. MongoDB Security Group'un inbound kurallarına sadece Web Server Security Group ID'si eklendi.

### 3. PowerShell Encoding Hatası
**Sorun:** UserData scriptleri Windows'tan yüklenirken karakter hatası oluştu.
**Çözüm:** Dosyalar Base64 encode edilerek Launch Template içine gömüldü.
