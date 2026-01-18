from flask import Flask, render_template, request, jsonify
import dns.resolver
from pymongo import MongoClient
import os
import boto3
import json

app = Flask(__name__)

# --- [ADIM 7] SECRETS MANAGER ENTEGRASYONU ---
def get_secret():
    secret_name = "emir-dns-mongo-secret-final"
    region_name = "us-east-1"
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = get_secret_value_response['SecretString']
        return json.loads(secret)
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        # Hata olursa fallback (Yedek)
        return {"username": "admin", "password": "password123"}

# Şifreyi kasadan çek
secrets = get_secret()
MONGO_USER = secrets['username']
MONGO_PASS = secrets['password']
MONGO_HOST = os.environ.get('MONGO_HOST', 'mongodb')
# ---------------------------------------------

client = MongoClient(f'mongodb://{MONGO_USER}:{MONGO_PASS}@{MONGO_HOST}:27017/')
db = client['dns_db']
collection = db['queries']

@app.route('/', methods=['GET', 'POST'])
def index():
    result = None
    error = None
    if request.method == 'POST':
        domain = request.form.get('domain')
        try:
            answers = dns.resolver.resolve(domain, 'A')
            ip_addresses = [r.to_text() for r in answers]
            result = ip_addresses
            collection.insert_one({'domain': domain, 'ips': ip_addresses})
        except Exception as e:
            error = str(e)
    return render_template('index.html', result=result, error=error)

@app.route('/health')
def health():
    return jsonify(status='healthy'), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5889)
