from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Kendi yazdığımız servisi çağırıyoruz 👇
from services.scraper import analyze_product_logic

app = FastAPI()

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

# --- ANA ENDPOINT (KAPI) ---
@app.post("/analyze")
def analyze_endpoint(request: ProductRequest):
    # İşi 'services/scraper.py' içindeki aşçıya devrediyoruz
    result = analyze_product_logic(
        request.url, 
        request.user_height, 
        request.user_weight, 
        request.user_shoulder, 
        request.user_waist
    )
    
    if "error" in result:
        return {"analysis": "Hata oluştu: " + result["error"], "title": "Hata", "image_url": ""}
        
    return result

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)