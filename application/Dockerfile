# Python 3.9 Slim versiyonunu baz al (Hafif ve hızlı)
FROM python:3.9-slim

# Çalışma dizinini ayarla
WORKDIR /app

# Gereksinimleri kopyala ve yükle
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama kodlarını kopyala
COPY . .

# Uygulama portunu dışarı aç (Proje gereksinimi: 5889)
EXPOSE 5889

# Healthcheck ekle (Proje gereksinimi)
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:5889/health || exit 1

# Uygulamayı başlat
CMD ["python", "app.py"]