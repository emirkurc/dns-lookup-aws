#!/bin/bash
# AWS VPC Kurulum Scripti
# Proje Gereksinimi: 10.0.0.0/16 CIDR

echo "VPC Kurulumu Baþlýyor..."

# 1. VPC Oluþturma
# Bu komut sanal aðýn duvarlarýný örer.
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query "Vpc.VpcId" --output text)
echo "VPC Oluþturuldu: $VPC_ID"

# VPC"ye isim etiketi yapýþtýr (Konsolda bulmak kolay olsun diye)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=emir-dns-project-vpc

# 2. DNS Ayarlarýný Açma [cite: 42-43]
# Bu olmazsa sunucular internete isimle çýkamaz.
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"

# 3. Internet Gateway (IGW) Oluþturma 
# Bu, VPC"nin internete açýlan kapýsýdýr.
IGW_ID=$(aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text)
echo "Internet Gateway Oluþturuldu: $IGW_ID"

aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=emir-dns-project-igw
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

echo "Temel VPC ve Internet Gateway Hazýr!"
echo "Lütfen Subnet kurulumuna geçin."

