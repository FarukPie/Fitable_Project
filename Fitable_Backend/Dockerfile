# 1. Python 3.9 Slim (Hafif Sürüm)
FROM python:3.9-slim

# 2. Gerekli sistem araçlarını yükle
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    curl \
    ca-certificates \
    --no-install-recommends

# 3. Google Chrome Kurulumu (YENİ MODERN YÖNTEM 🛠️)
# apt-key yerine gpg --dearmor kullanıyoruz
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Çalışma klasörünü ayarla
WORKDIR /app

# 5. Paketleri yükle
RUN pip install --no-cache-dir fastapi uvicorn requests python-dotenv selenium webdriver-manager google-generativeai Pillow cloud_firestore firebase_admin

# 6. Dosyaları kopyala
COPY . .

# 7. Portu aç
EXPOSE 8000

# 8. Başlat
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]