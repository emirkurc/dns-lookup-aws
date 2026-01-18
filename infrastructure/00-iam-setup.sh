#!/bin/bash
# 00-iam-setup.sh
# Amaç: EC2 sunucularýnýn CloudWatch ve SSM kullanabilmesi için yetki rolü oluþturmak.

echo "IAM Rolü Hazýrlanýyor..."

# 1. Güven Politikasýný Tanýmla (EC2 bu rolü giyebilir)
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# 2. Rolü Oluþtur
ROLE_NAME="emir-dns-project-role"
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json

# 3. Hazýr Ýzinleri (Managed Policies) Ekle [cite: 110-111]
# CloudWatch loglarý için:
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
# Güvenli baðlantý (SSM) için:
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
# Secrets Manager (Bonus) için:
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite

# 4. Instance Profile Oluþtur (EC2"ya takýlacak kýlýf)
PROFILE_NAME="emir-dns-project-profile"
aws iam create-instance-profile --instance-profile-name $PROFILE_NAME
aws iam add-role-to-instance-profile --instance-profile-name $PROFILE_NAME --role-name $ROLE_NAME

echo "IAM Rolü ve Profili Hazýr: $PROFILE_NAME"
# Geçici dosyayý sil
rm trust-policy.json

