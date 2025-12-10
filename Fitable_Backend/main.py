from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import hashlib
import json
import asyncio
import os
from concurrent.futures import ThreadPoolExecutor

# Redis (Opsiyonel - Eğer yoksa In-Memory çalışır)
try:
    import redis
except ImportError:
    redis = None

# Kendi yazdığımız servisi çağırıyoruz 👇
from scraper_service import analyze_product_logic, init_driver

app = FastAPI()

# --- AYARLAR ---
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Global Değişkenler
driver = None
driver_lock = asyncio.Lock() # 🔒 Driver'ı aynı anda tek kişinin kullanması için
executor = ThreadPoolExecutor(max_workers=3) # Blocking işlemleri buraya atacağız

# Cache İstemcisi
redis_client = None
local_cache = {}

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
async def startup_event():
    global driver, redis_client
    
    # 1. Driver Başlat
    driver = init_driver()
    
    # 2. Redis Bağlantısı (Varsa)
    if redis:
        try:
            redis_client = redis.from_url(REDIS_URL, decode_responses=True)
            redis_client.ping()
            print("✅ Redis bağlantısı başarılı!")
        except Exception as e:
            print(f"⚠️ Redis bağlanamadı, In-Memory cache kullanılacak: {e}")
            redis_client = None

@app.on_event("shutdown")
async def shutdown_event():
    global driver
    if driver:
        print("🛑 WebDriver kapatılıyor...")
        driver.quit()
    if redis_client:
        redis_client.close()

# --- CACHE FONKSİYONLARI ---
def get_cache(key):
    if redis_client:
        try:
            data = redis_client.get(key)
            return json.loads(data) if data else None
        except:
            return None
    return local_cache.get(key)

def set_cache(key, value, expire=3600): # 1 Saat Cache
    if redis_client:
        try:
            redis_client.setex(key, expire, json.dumps(value))
        except:
            pass
    else:
        local_cache[key] = value

# --- ANA ENDPOINT (ASYNC) ---
@app.post("/analyze")
async def analyze_endpoint(request: ProductRequest):
    # 1. Cache Kontrolü 🧠
    cache_key = f"{request.url}-{request.user_height}-{request.user_weight}-{request.user_shoulder}-{request.user_waist}"
    cache_hash = hashlib.md5(cache_key.encode()).hexdigest()
    
    cached_result = get_cache(cache_hash)
    if cached_result:
        print("⚡ CACHE HIT! Sonuç dönülüyor.")
        return cached_result

    # 2. Analiz İşlemi (Thread Pool + Locking)
    # Blocking işlemi ana thread'i tıkamaması için executor'da çalıştırıyoruz.
    # Ancak Driver tek olduğu için sıraya koymak (Lock) zorundayız.
    
    async with driver_lock: # 🔒 Sıraya gir
        loop = asyncio.get_event_loop()
        
        # run_in_executor ile senkron fonksiyonu asenkron gibi çalıştır
        result = await loop.run_in_executor(
            executor, 
            analyze_product_logic,
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
    set_cache(cache_hash, result)
    
    return result

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
