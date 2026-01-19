\# 🔧 Sorun Giderme (Troubleshooting) ve Çözümler



Bu doküman, proje geliştirme ve canlıya alma (deployment) süreçlerinde karşılaşılan kritik teknik sorunları, bu sorunların kök neden analizlerini (Root Cause Analysis) ve uygulanan çözüm adımlarını detaylandırır.



---



\## 🔴 Senaryo 1: Load Balancer Target Group "Unhealthy" Durumu



\### 📉 Belirti (Symptom)

Application Load Balancer (ALB) oluşturulduktan sonra, Target Group altındaki EC2 instance'ların durumu sürekli `Unhealthy` veya `Initializing` döngüsünde kalıyordu. Web sitesine erişim sağlanamıyordu.



\### 🕵️‍♂️ Kök Neden Analizi (RCA)

1\.  Sorunlu instance'lardan birine \*\*AWS Systems Manager - Session Manager\*\* kullanılarak bağlanıldı.

2\.  Docker konteyner durumu `docker ps -a` komutu ile kontrol edildi. Konteynerin sürekli `Restarting` modunda olduğu görüldü.

3\.  Hata logları `docker logs <container\\\_id>` komutu ile incelendi.

4\.  \*\*Hata Mesajı:\*\* `Botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling the GetSecretValue operation`.

5\.  \*\*Sebep:\*\* EC2 Instance Profile (IAM Rolü) üzerinde `SecretsManagerReadWrite` yetkisi eksikti. Uygulama açılırken veritabanı şifresini çekemeyip çöküyordu.



\### ✅ Çözüm

`emir-dns-project-role` isimli IAM rolüne, AWS Secrets Manager servisine erişim izni veren politika eklendi. Ardından Auto Scaling Group üzerinde "Instance Refresh" yapılarak sunucuların yenilenmesi sağlandı.



---



\## 🔴 Senaryo 2: CloudWatch Loglarının Görüntülenememesi



\### 📉 Belirti

Web uygulaması sorunsuz çalışmasına rağmen, CloudWatch Dashboard üzerinde uygulama logları (stdout/stderr) akmıyordu.



\### 🕵️‍♂️ Kök Neden Analizi

1\.  `docker-compose.yml` dosyası incelendi. `logging: driver: awslogs` ayarının doğru olduğu görüldü.

2\.  Ancak EC2 sunucusunun sistem logları (`/var/log/messages`) incelendiğinde, Docker daemon'ın log grubuna yazma izni olmadığına dair hatalar bulundu.

3\.  \*\*Sebep:\*\* EC2 IAM rolüne `CloudWatchLogsFullAccess` yetkisi verilmemişti. Docker sürücüsü, log grubunu oluşturmaya çalışırken yetki hatası alıyordu.



\### ✅ Çözüm

IAM rolüne gerekli CloudWatch izinleri eklendi ve UserData scripti güncellenerek `awslogs-create-group: "true"` seçeneği Docker Compose konfigürasyonuna eklendi.



---



\## 🔴 Senaryo 3: Veritabanı Bağlantı Zaman Aşımı (Timeout)



\### 📉 Belirti

Web arayüzünde "Lookup" butonuna basıldığında sayfa yaklaşık 30 saniye bekliyor ve ardından `500 Internal Server Error` hatası veriyordu.



\### 🕵️‍♂️ Kök Neden Analizi

1\.  Uygulama loglarında `pymongo.errors.ServerSelectionTimeoutError` hatası görüldü.

2\.  VPC Reachability Analyzer aracı kullanılarak Web Sunucusu ile MongoDB Sunucusu arasındaki ağ yolu test edildi.

3\.  \*\*Sebep:\*\* MongoDB Security Group (Private Subnet), gelen trafiği reddediyordu. Inbound kurallarında Web Sunucusu Security Group ID'si tanımlanmamıştı.



\### ✅ Çözüm

MongoDB Security Group'un Inbound kurallarına, Kaynak (Source) olarak `Web-SG` ID'si eklendi ve 27017 portuna izin verildi.



---



\## 🔴 Senaryo 4: PowerShell ve Linux Karakter Kodlama Sorunu



\### 📉 Belirti

Windows işletim sisteminde hazırlanan `User Data` scripti AWS'ye yüklendiğinde, Linux sunucu scripti çalıştıramıyordu (Syntax Error).



\### 🕵️‍♂️ Kök Neden Analizi

Windows ve Linux sistemlerinin satır sonu karakterleri (CRLF vs LF) ve dosya encoding yapıları farklıydı. Script AWS'ye text olarak kopyalandığında karakter bozulması yaşanıyordu.



\### ✅ Çözüm

Scriptler AWS Launch Template'e yüklenmeden önce \*\*Base64\*\* formatına kodlandı (Encoded). Bu sayede scriptin bütünlüğü korunarak Linux sunucuya aktarıldı.



---



\*\*Son Güncelleme:\*\* Ocak 2026

