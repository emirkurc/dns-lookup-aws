import os
import socket
import datetime
from flask import Flask, render_template, request, jsonify
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

app = Flask(__name__)

# --- AYARLAR (Environment Variables) ---
# Proje dosyasındaki "Ortam değişkenleri ile yapılandırma" maddesi [cite: 26]
MONGO_HOST = os.environ.get('MONGO_HOST', 'localhost')
MONGO_PORT = int(os.environ.get('MONGO_PORT', 27017))
MONGO_USER = os.environ.get('MONGO_USER', 'admin')
MONGO_PASS = os.environ.get('MONGO_PASSWORD', 'password')
APP_PORT = int(os.environ.get('FLASK_PORT', 5889))

# --- MONGODB BAĞLANTISI ---
def get_db_connection():
    try:
        # Authentication ile bağlantı dizesi
        client = MongoClient(
            host=MONGO_HOST,
            port=MONGO_PORT,
            username=MONGO_USER,
            password=MONGO_PASS,
            serverSelectionTimeoutMS=2000
        )
        # Bağlantıyı test et
        client.server_info()
        return client
    except Exception as e:
        print(f"Veritabanı hatası: {e}")
        return None

# --- ROTALAR ---

@app.route('/')
def index():
    """Ana Sayfayı Göster"""
    return render_template('index.html')

@app.route('/health')
def health_check():
    """AWS Load Balancer için Sağlık Kontrolü """
    # Veritabanı bağlantısını kontrol et
    client = get_db_connection()
    db_status = "healthy" if client else "unhealthy"
    if client:
        client.close()
    
    # 200 OK döndürmek zorundayız
    return jsonify({
        "status": "healthy",
        "database": db_status,
        "timestamp": datetime.datetime.now().isoformat()
    }), 200

@app.route('/lookup', methods=['POST'])
def lookup():
    """DNS Sorgusu Yap ve Kaydet [cite: 22, 23]"""
    domain = request.form.get('domain')
    
    if not domain:
        return jsonify({"error": "Domain gerekli"}), 400

    result = {
        "domain": domain,
        "query_time": datetime.datetime.now().isoformat(),
        "client_ip": request.remote_addr
    }

    try:
        # 1. DNS Sorgusu (A Kaydı)
        ip_list = []
        ais = socket.getaddrinfo(domain, 0, 0, 0, 0)
        for result_tuple in ais:
            ip_list.append(result_tuple[-1][0])
        
        # Tekrar eden IP'leri temizle
        result["ips"] = list(set(ip_list))
        result["status"] = "success"

        # 2. Veritabanına Kayıt [cite: 23]
        client = get_db_connection()
        if client:
            db = client['dnsdb']
            db.queries.insert_one(result.copy()) # Copy because _id is added
            result["db_saved"] = True
            client.close()
        else:
            result["db_saved"] = False
            result["db_error"] = "Veritabanına ulaşılamadı"

    except socket.gaierror:
        result["status"] = "error"
        result["message"] = "Domain bulunamadı veya geçersiz."
    except Exception as e:
        result["status"] = "error"
        result["message"] = str(e)

    return jsonify(result)

if __name__ == '__main__':
    # Proje gereksinimi: Port 5889 
    app.run(host='0.0.0.0', port=APP_PORT)