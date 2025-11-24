# 1. Python ve Chrome'un olduğu temel bir Linux sürümü seçiyoruz
FROM python:3.9-slim

# 2. Gerekli sistem araçlarını ve Chrome'u indiriyoruz
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    curl \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean

# 3. Çalışma klasörünü ayarla
WORKDIR /app

# 4. Gereksinimleri kopyala ve yükle
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Tüm kodları kopyala
COPY . .

# 6. Portu aç
EXPOSE 8000

# 7. Başlatma komutu
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]