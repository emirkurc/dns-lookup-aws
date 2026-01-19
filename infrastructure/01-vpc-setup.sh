#!/bin/bash
# ------------------------------------------------------------------
# [01-vpc-setup.sh]
# AWS VPC, Subnet, IGW, NAT Gateway ve Route Table Kurulumu
# ------------------------------------------------------------------

echo "🚀 VPC Kurulumu Başlıyor..."

# 1. VPC Oluşturma (10.0.0.0/16)
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=emir-dns-project-vpc
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"
echo "✅ VPC Oluşturuldu: $VPC_ID"

# 2. Internet Gateway (IGW) Oluşturma
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=emir-dns-igw
echo "✅ IGW Oluşturuldu ve VPC'ye bağlandı: $IGW_ID"

# 3. Subnetlerin Oluşturulması
echo "🌍 Subnetler Oluşturuluyor..."

# Public Subnet 1 (us-east-1a)
PUB_SUB_1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PUB_SUB_1 --tags Key=Name,Value=Public-Subnet-1
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUB_1 --map-public-ip-on-launch

# Public Subnet 2 (us-east-1b)
PUB_SUB_2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PUB_SUB_2 --tags Key=Name,Value=Public-Subnet-2
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUB_2 --map-public-ip-on-launch

# Private Subnet 1 (us-east-1a) - MongoDB Primary
PRI_SUB_1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.11.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PRI_SUB_1 --tags Key=Name,Value=Private-Subnet-1

# Private Subnet 2 (us-east-1b) - MongoDB Secondary
PRI_SUB_2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.12.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PRI_SUB_2 --tags Key=Name,Value=Private-Subnet-2

echo "✅ 4 Subnet Hazır."

# 4. NAT Gateway Kurulumu (Private Subnetlerin internete çıkması için)
echo "🔌 NAT Gateway Kuruluyor (Bu işlem 1-2 dakika sürebilir)..."
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUB_1 --allocation-id $EIP_ALLOC --query 'NatGateway.NatGatewayId' --output text)
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID
aws ec2 create-tags --resources $NAT_GW_ID --tags Key=Name,Value=emir-dns-nat-gw
echo "✅ NAT Gateway Aktif: $NAT_GW_ID"

# 5. Route Table Ayarları
echo "🗺️ Route Table Ayarları Yapılıyor..."

# Public Route Table (IGW'ye gider)
RT_PUB=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT_PUB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 create-tags --resources $RT_PUB --tags Key=Name,Value=emir-public-rt
aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $PUB_SUB_1
aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $PUB_SUB_2

# Private Route Table (NAT Gateway'e gider)
RT_PRI=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT_PRI --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
aws ec2 create-tags --resources $RT_PRI --tags Key=Name,Value=emir-private-rt
aws ec2 associate-route-table --route-table-id $RT_PRI --subnet-id $PRI_SUB_1
aws ec2 associate-route-table --route-table-id $RT_PRI --subnet-id $PRI_SUB_2

echo "🎉 Ağ Altyapısı (VPC) Başarıyla Kuruldu!"