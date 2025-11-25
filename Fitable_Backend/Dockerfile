# 1. Python 3.11 Slim
FROM python:3.11-slim

# 2. Sistem araçları ve Chrome
RUN apt-get update && apt-get install -y \
    wget gnupg unzip curl ca-certificates \
    --no-install-recommends

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Önce ana klasörü ayarla
WORKDIR /app

# 4. Bütün projeyi kopyala (Frontend, Backend hepsi gelir)
COPY . .

# 5. ✨ KRİTİK HAMLE: Backend klasörünün İÇİNE gir
WORKDIR /app/Fitable_Backend

# 6. Paketleri yükle
RUN pip install --no-cache-dir fastapi uvicorn requests python-dotenv selenium webdriver-manager google-generativeai Pillow firebase_admin

# 7. Portu aç
EXPOSE 8000

# 8. Başlat (Artık içeride olduğumuz için main.py'yi görür)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]