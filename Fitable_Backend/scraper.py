import os
import time
import requests
from io import BytesIO
from PIL import Image
from dotenv import load_dotenv

# Selenium
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

# AI
import google.generativeai as genai

# 1. AYARLAR
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)

# Modele "system instruction" vererek onu bir moda uzmanı yapıyoruz
model = genai.GenerativeModel(
    'gemini-2.0-flash',
    system_instruction="Sen uzman bir terzi ve moda asistanısın. Görevin ürün verilerini inceleyip beden ölçülerini çıkarmak."
)

chrome_options = Options()
chrome_options.add_argument("--start-maximized")
chrome_options.add_argument("--disable-blink-features=AutomationControlled")
chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

# 2. BAŞLAT
print("🚀 Fitable Ajanı Başlatılıyor...")
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

# --- TEST LİNKİ ---
# (Beden bilgisi olan bir ürün seçelim)
url = "https://www.trendyol.com/tudors/unisex-oversize-genis-kesim-100-pamuk-yumusak-dokulu-basic-bisiklet-yaka-siyah-tisort-p-817785986?boutiqueId=61&merchantId=139435" # <-- BURAYA LİNK YAPIŞTIRACAĞIZ
driver.get(url)
time.sleep(3)

print("-" * 40)
print("🔍 VERİLER TOPLANIYOR...")

# A. METİN VERİLERİNİ ÇEK
text_data = ""
try:
    # Ürün Adı
    header = driver.find_element(By.TAG_NAME, "h1").text
    text_data += f"Ürün Adı: {header}\n"
    
    # Ürün Özellikleri (Manken bilgisi genelde buradadır)
    # Trendyol'da özellikler genelde 'ul' listesi içindedir
    attributes = driver.find_elements(By.CSS_SELECTOR, ".detail-attr-container li")
    text_data += "Ürün Özellikleri:\n"
    for attr in attributes:
        text_data += f"- {attr.text}\n"
        
    print("✅ Metin verileri alındı.")
except:
    print("⚠️ Metin verileri tam alınamadı.")

# B. RESİMLERİ ÇEK (İlk 3 resim yeterli, maliyet/hız için)
images_for_ai = []
img_elements = driver.find_elements(By.TAG_NAME, "img")
processed_urls = []

print("✅ Resimler taranıyor...")
for img in img_elements:
    src = img.get_attribute("src")
    if src and "cdn.dsmcdn" in src and ".jpg" in src and "mnresize" in src:
        if src not in processed_urls:
            processed_urls.append(src)
            # Resmi indirip AI için hazırla
            try:
                response = requests.get(src)
                img_blob = Image.open(BytesIO(response.content))
                images_for_ai.append(img_blob)
            except:
                pass
            
            if len(images_for_ai) >= 3: # Sadece ilk 3 resim
                break

print("-" * 40)
print("🤖 AI ANALİZ YAPIYOR... (Lütfen bekle)")

# C. GEMINI'YE HEPSİNİ GÖNDER
# Prompt: Hem metni oku hem resimlere bak
user_prompt = f"""
Aşağıdaki ürün verilerini analiz et:

METİN BİLGİLERİ:
{text_data}

GÖREVLER:
1. Bu ürünün kalıbı nasıl? (Slim fit, Oversize, Normal vb.)
2. Manken ölçüleri veya beden tablosu bilgisi var mı? Varsa yaz.
3. 180 cm boy ve 80 kg biri için hangi bedeni önerirsin? (Tahmin yap)

Cevabı kısa ve maddeler halinde ver.
"""

# Resimleri ve soruyu tek pakette gönderiyoruz
input_package = [user_prompt] + images_for_ai 

try:
    response = model.generate_content(input_package)
    print("\n📢 SONUÇ RAPORU:")
    print(response.text)
except Exception as e:
    print(f"❌ AI Hatası: {e}")

print("-" * 40)
# driver.quit()
