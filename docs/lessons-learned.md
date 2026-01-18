# Öğrenilen Dersler 🎓

Bu proje sürecinde edindiğim önemli deneyimler:

1. **IAM Rollerinin Önemi:** Servislerin (EC2, CloudWatch) birbirleriyle konuşabilmesi için doğru IAM yetkilerinin verilmesi gerektiğini yaşayarak öğrendim. Logların gitmemesi sorunu buna bir örnekti.
2. **Stateful vs Stateless:** Web uygulamasının stateless (durumsuz) olması gerektiğini, veritabanının ise stateful olduğunu ve bu yüzden ayrılmaları gerektiğini kavradım.
3. **Maliyet Yönetimi:** NAT Gateway ve ALB gibi servislerin saatlik maliyetleri olduğunu ve gereksiz kaynakların kapatılması gerektiğini öğrendim.
4. **Security Groups:** "0.0.0.0/0" iznini sadece gerekli yerlere (ALB HTTP portu) vermenin, veritabanını ise sadece Web sunucularına açmanın güvenliği nasıl artırdığını gördüm.
