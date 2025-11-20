from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os
import requests
from io import BytesIO
from PIL import Image
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware

# Selenium ve AI kütüphaneleri
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import google.generativeai as genai

# --- KURULUMLAR ---
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-2.0-flash', system_instruction="Sen bir moda asistanısın.")

app = FastAPI() # Uygulamayı başlatıyoruz

# --- GÜVENLİK İZNİ (CORS) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Tüm sitelerden gelen isteklere izin ver
    allow_credentials=True,
    allow_methods=["*"], # GET, POST her şeye izin ver
    allow_headers=["*"],
)

# Flutter'dan gelecek veri formatı (Sadece bir link bekliyoruz)
class ProductRequest(BaseModel):
    url: str
    user_height: int = 180 # Varsayılan değerler
    user_weight: int = 80

# --- ANA FONKSİYON (SCRAPER) ---
def analyze_product(url, height, weight):
    # Tarayıcı Ayarları (HEADLESS = Ekranda pencere açılmadan gizli çalış)
    chrome_options = Options()
    chrome_options.add_argument("--headless") 
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)
    
    try:
        driver.get(url)
        driver.implicitly_wait(3) # Akıllı bekleme
        
        # 1. Metin Verisi
        try:
            header = driver.find_element(By.TAG_NAME, "h1").text
            features = driver.find_elements(By.CSS_SELECTOR, ".detail-attr-container li")
            feature_text = "\n".join([f.text for f in features])
            full_text = f"Ürün: {header}\nÖzellikler:\n{feature_text}"
        except:
            full_text = "Metin verisi alınamadı."

        # 2. Resim Verisi
        images = []
        img_elements = driver.find_elements(By.TAG_NAME, "img")
        processed_urls = []
        
        for img in img_elements:
            src = img.get_attribute("src")
            if src and "cdn.dsmcdn" in src and ".jpg" in src and "mnresize" in src:
                if src not in processed_urls:
                    processed_urls.append(src)
                    try:
                        resp = requests.get(src)
                        images.append(Image.open(BytesIO(resp.content)))
                    except:
                        pass
                    if len(images) >= 3: break
        
        # 3. AI Analizi
        prompt = f"""
        Kullanıcı Verileri: Boy: {height}cm, Kilo: {weight}kg.
        Ürün Verileri: {full_text}
        
        Görevin:
        1. Bu ürünün kalıbını tespit et.
        2. Kullanıcıya uygun bedeni öner.
        3. Neden bu bedeni önerdiğini 1 cümleyle açıkla.
        """
        
        response = model.generate_content([prompt] + images)
        return response.text

    except Exception as e:
        return f"Hata oluştu: {str(e)}"
    finally:
        driver.quit() # Tarayıcıyı kapat

# --- ENDPOINT (KAPI) ---
@app.post("/analyze")
def analyze_endpoint(request: ProductRequest):
    print(f"İstek geldi: {request.url}")
    result = analyze_product(request.url, request.user_height, request.user_weight)
    return {"analysis": result}

# --- SUNUCUYU BAŞLAT ---
if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)