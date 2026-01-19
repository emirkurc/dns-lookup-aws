#!/bin/bash
# ------------------------------------------------------------------
# [test-deployment.sh]
# Deployment Test Scripti (Health Check & DNS Lookup)
# ------------------------------------------------------------------

echo "🧪 Deployment Testi Başlıyor..."

# 1. Load Balancer DNS Adresini Bul
echo "🔍 Load Balancer adresi aranıyor..."
ALB_DNS=$(aws elbv2 describe-load-balancers --names emir-dns-alb --query "LoadBalancers[0].DNSName" --output text 2>/dev/null)

if [ -z "$ALB_DNS" ]; then
    echo "❌ HATA: Load Balancer bulunamadı. Önce kurulumu yapın."
    exit 1
fi

echo "   📍 Hedef: http://$ALB_DNS"

# 2. Health Check Testi
echo "🩺 Health Check endpoint kontrol ediliyor (/health)..."
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS/health)

if [ "$HEALTH_STATUS" == "200" ]; then
    echo "   ✅ Health Check BAŞARILI (HTTP 200)"
else
    echo "   ❌ Health Check BAŞARISIZ (HTTP $HEALTH_STATUS)"
    echo "   ⚠️ Lütfen Target Group durumunu kontrol edin."
fi

# 3. Örnek DNS Sorgusu (Simülasyon)
echo "🌍 Örnek DNS Sorgusu yapılıyor (google.com)..."
RESPONSE=$(curl -s -X POST -F "domain=google.com" http://$ALB_DNS)

# Basit bir string kontrolü
if [[ "$RESPONSE" == *"Results Found"* ]] || [[ "$RESPONSE" == *"IP Addresses"* ]]; then
    echo "   ✅ DNS Lookup BAŞARILI (Sonuçlar döndü)"
else
    echo "   ⚠️ DNS Lookup beklenen yanıtı vermedi. Manuel kontrol edin."
fi

echo "🏁 Test Tamamlandı."