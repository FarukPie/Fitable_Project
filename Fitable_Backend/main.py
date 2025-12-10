from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import hashlib
import json

# Kendi yazdığımız servisi çağırıyoruz 👇
from scraper_service import analyze_product_logic, init_driver

app = FastAPI()

# Global driver değişkeni
driver = None

# Basit Cache Sistemi (In-Memory)
# Key: URL + UserStats Hash, Value: Result JSON
analysis_cache = {}

# --- GÜVENLİK İZNİ (CORS) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- VERİ MODELİ ---
class ProductRequest(BaseModel):
    url: str
    user_height: int
    user_weight: int
    user_shoulder: int = 0
    user_waist: int = 0

# --- STARTUP / SHUTDOWN EVENTLERİ ---
@app.on_event("startup")
def startup_event():
    global driver
    # Uygulama başlarken driver'ı bir kere oluştur
    driver = init_driver()

@app.on_event("shutdown")
def shutdown_event():
    global driver
    # Uygulama kapanırken driver'ı temizle
    if driver:
        print("🛑 WebDriver kapatılıyor...")
        driver.quit()

# --- ANA ENDPOINT (KAPI) ---
@app.post("/analyze")
def analyze_endpoint(request: ProductRequest):
    # 1. Cache Kontrolü 🧠
    # Benzersiz bir anahtar oluştur (URL + Ölçüler)
    cache_key = f"{request.url}-{request.user_height}-{request.user_weight}-{request.user_shoulder}-{request.user_waist}"
    cache_hash = hashlib.md5(cache_key.encode()).hexdigest()
    
    if cache_hash in analysis_cache:
        print("⚡ CACHE HIT! Sonuç hafızadan dönülüyor.")
        return analysis_cache[cache_hash]

    # 2. Analiz İşlemi (Cache Miss)
    result = analyze_product_logic(
        driver,
        request.url, 
        request.user_height, 
        request.user_weight, 
        request.user_shoulder, 
        request.user_waist
    )
    
    if "error" in result:
        return {"analysis": "Hata oluştu: " + result["error"], "title": "Hata", "image_url": ""}
    
    # 3. Sonucu Cache'e Kaydet
    analysis_cache[cache_hash] = result
    return result

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)