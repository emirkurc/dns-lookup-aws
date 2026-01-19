# 🎓 Öğrenilen Dersler (Lessons Learned)

Bu proje, teorik bulut bilişim bilgilerinin gerçek dünya senaryolarına (Production Environment) nasıl uyarlandığını anlamak açısından kritik bir deneyim oldu. Süreç boyunca edindiğim en önemli teknik ve mimari kazanımlar aşağıdadır:

---

## 1. "Stateless" Mimarinin Önemi
Auto Scaling Group (ASG) kullanırken sunucuların "harcanabilir" (disposable) olması gerektiğini yaşayarak öğrendim.
* **Deneyim:** Geliştirme aşamasında logları sunucu içine dosya olarak yazdırıyordum. Ancak ASG, yük azaldığında bir sunucuyu kapattığında o loglar da siliniyordu.
* **Ders:** Veriyi asla uygulama sunucusunda tutmamak gerekir.
    * Loglar → **CloudWatch**'a.
    * Kullanıcı Verisi → **MongoDB**'ye (Kalıcı Disk).
    * Şifreler → **Secrets Manager**'a taşınmalıdır.

## 2. IAM Rolleri ve "Least Privilege" İlkesi
Başlangıçta her şeye `AdministratorAccess` vererek ilerlemek kolay görünse de, hata ayıklama (debugging) sırasında bunun ne kadar riskli olduğunu gördüm.
* **Deneyim:** Uygulama Secrets Manager'a erişemediğinde hata alıyordum ama nedenini anlamak zordu.
* **Ders:** Her servise (EC2, CodeBuild, Lambda) sadece ihtiyacı olan yetkiyi tanımlamak, hem güvenliği artırıyor hem de hatanın kaynağını (AccessDenied) bulmayı kolaylaştırıyor.

## 3. Infrastructure as Code (IaC) Gücü
AWS Konsolu üzerinden elle tıklayarak (ClickOps) yapılan işlemlerin tekrarlanamaz ve hataya açık olduğunu fark ettim.
* **Deneyim:** VPC kurulumunu ilk başta elle yaptım ve Subnet ayarlarını karıştırdım. Silip tekrar yapmak saatlerimi aldı.
* **Ders:** Bash scriptleri ile altyapıyı kod haline getirmek, tüm ortamı dakikalar içinde ve hatasız bir şekilde yeniden ayağa kaldırmamı sağladı.

## 4. Maliyet Farkındalığı (Cost Management)
Bulut kaynaklarının "kullandığın kadar öde" modelinin, "kullanmadığını kapat" disiplini gerektirdiğini öğrendim.
* **Deneyim:** Projenin başında açık unuttuğum bir NAT Gateway, sunucular kapalı olmasına rağmen maliyet oluşturmaya devam etti.
* **Ders:** Proje bitiminde kaynakları temizleyen bir `cleanup.sh` scripti yazmak ve CloudWatch Billing Alarm kurmak, bir bulut mühendisinin ilk yapması gereken iştir.

## 5. Güvenlik Grupları ve Ağ İzolasyonu
Güvenliğin sadece şifrelemekten ibaret olmadığını, ağ seviyesinde izolasyonun şart olduğunu kavradım.
* **Ders:** Veritabanını internete kapatmak (Private Subnet) ve sadece Web Sunucularından gelen trafiğe (Security Group Reference) izin vermek, dışarıdan gelebilecek saldırı yüzeyini %99 oranında azalttı.

---

**Özet:** Bu proje sayesinde sadece AWS servislerini kullanmayı değil, onları **güvenli, ölçeklenebilir ve yönetilebilir** bir şekilde birbirine bağlamayı (Architecture) öğrendim.