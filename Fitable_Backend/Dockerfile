# 1. Python 3.11 Slim
FROM python:3.11-slim

# 2. Sistem araçları
RUN apt-get update && apt-get install -y \
    wget gnupg unzip curl ca-certificates \
    --no-install-recommends

# 3. Chrome Kurulumu
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Çalışma klasörü
WORKDIR /app

# 5. Paketleri yükle
RUN pip install --no-cache-dir fastapi uvicorn requests python-dotenv selenium webdriver-manager google-generativeai Pillow firebase_admin

# 6. Dosyaları kopyala
COPY . .

# 7. Portu aç
EXPOSE 8000

# 8. BAŞLATMA KOMUTU (DEDEKTİF MODU 🔍)
# Önce dosyaları listele (ls -la), sonra sunucuyu başlat.
CMD sh -c "ls -la && uvicorn main:app --host 0.0.0.0 --port 8000"