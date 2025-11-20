import google.generativeai as genai
import os
from dotenv import load_dotenv

# Şifreni yükle
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ .env dosyasından Key okunamadı!")
else:
    genai.configure(api_key=api_key)
    
    print("🔍 API Key ile erişilebilen modeller listeleniyor...")
    print("-" * 40)
    
    try:
        for m in genai.list_models():
            # Sadece resim veya metin üretebilenleri gösterelim
            if 'generateContent' in m.supported_generation_methods:
                print(f"✅ Mevcut Model: {m.name}")
    except Exception as e:
        print(f"❌ Hata oluştu: {e}")