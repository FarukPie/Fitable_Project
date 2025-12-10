import os
import time
import requests
import json
import re
from io import BytesIO
from PIL import Image
from dotenv import load_dotenv
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor

# Selenium
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import google.generativeai as genai

# --- AYARLAR ---
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-2.0-flash', system_instruction="Sen uzman bir e-ticaret ve moda analistisin.")

def init_driver():
    """Initializes and returns a Chrome WebDriver with optimized settings."""
    print("🚀 WebDriver Başlatılıyor (Singleton)...")
    chrome_options = Options()
    chrome_options.add_argument("--headless") 
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.page_load_strategy = 'eager' 
    
    prefs = {
        "profile.managed_default_content_settings.images": 2, 
        "profile.managed_default_content_settings.stylesheets": 2, 
    }
    chrome_options.add_experimental_option("prefs", prefs)
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    
    return webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

def download_image(url):
    """Helper function to download a single image."""
    try:
        resp = requests.get(url, timeout=3)
        if resp.status_code == 200:
            img_data = Image.open(BytesIO(resp.content))
            img_data.thumbnail((800, 800))
            return img_data
    except:
        return None

def extract_json_from_html(html_content):
    """Extracts product data from embedded JSON in HTML."""
    try:
        # Pattern 1: window.__PRODUCT_DETAIL_APP_INITIAL_STATE__
        match = re.search(r'window\.__PRODUCT_DETAIL_APP_INITIAL_STATE__\s*=\s*({.*?});', html_content)
        if match:
            data = json.loads(match.group(1))
            product = data.get('product', {})
            return {
                "title": product.get('name', ''),
                "features": [attr.get('value', '') for attr in product.get('attributes', [])[:5]],
                "images": ["https://cdn.dsmcdn.com" + img if img.startswith('/') else img for img in product.get('images', [])[:3]],
                "reviews": [] # JSON'da yorumlar genelde ayrı bir XHR ile gelir, burada olmayabilir.
            }
    except:
        pass
    return None

def analyze_product_logic(driver, url, height, weight, shoulder, waist):
    header = ""
    feature_text = ""
    reviews_text = ""
    images = []
    processed_urls = []
    
    # --- 1. ULTRA HIZLI YÖNTEM (JSON EXTRACTION) ---
    print(f"Ultra Hızlı mod (JSON) deneniyor: {url}")
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    
    use_selenium = True 
    
    try:
        response = requests.get(url, headers=headers, timeout=5)
        if response.status_code == 200:
            # A. JSON Çıkarma Denemesi
            json_data = extract_json_from_html(response.text)
            if json_data and json_data['title']:
                print("✅ JSON Modu Başarılı! Selenium ve Soup atlanıyor.")
                header = json_data['title']
                feature_text = "\n".join(json_data['features'])
                processed_urls = json_data['images']
                reviews_text = "Hızlı modda yorumlar alınamadı."
                use_selenium = False
            else:
                # B. BeautifulSoup Fallback (Eğer JSON yoksa ama HTML geldiyse)
                soup = BeautifulSoup(response.content, "html.parser")
                h1 = soup.find("h1")
                if h1:
                    header = h1.text.strip()
                    features = soup.select(".detail-attr-container li")
                    feature_text = "\n".join([f.text.strip() for f in features[:5]])
                    img_elements = soup.find_all("img")
                    for img in img_elements:
                        src = img.get("src")
                        if src and "cdn.dsmcdn" in src and ".jpg" in src and "mnresize" in src:
                            if src not in processed_urls:
                                processed_urls.append(src)
                                if len(processed_urls) >= 3: break
                    
                    if header and processed_urls:
                        print("✅ Requests (Soup) Modu Başarılı!")
                        use_selenium = False
                        reviews_text = "Hızlı modda yorumlar alınamadı."
            
    except Exception as e:
        print(f"Hızlı mod hatası: {e}")

    # --- 2. GÜVENLİ YÖNTEM (SELENIUM FALLBACK) ---
    if use_selenium:
        if driver is None:
             return {"error": "Driver başlatılamadı, lütfen sistemi kontrol edin."}

        print("Selenium moduna geçiliyor (Mevcut Driver)...")
        
        try:
            driver.get(url)
            driver.execute_script("window.scrollTo(0, 500);")
            
            if not header: 
                try:
                    header = driver.find_element(By.TAG_NAME, "h1").text
                    features = driver.find_elements(By.CSS_SELECTOR, ".detail-attr-container li")
                    feature_text = "\n".join([f.text for f in features[:5]]) 
                except:
                    header = "Başlık alınamadı"
            
            # Yorumlar
            try:
                fit_elements = driver.find_elements(By.CSS_SELECTOR, "[class*='fit-survey']")
                if fit_elements and fit_elements[0].text.strip():
                    reviews_text += f"🚨 TRENDYOL KALIP UYARISI: {fit_elements[0].text}\n"
            except: pass

            try:
                summary_elements = driver.find_elements(By.CSS_SELECTOR, "[class*='review-summary']")
                if summary_elements and len(summary_elements[0].text) > 20:
                    reviews_text += f"📊 MAĞAZA YORUM ÖZETİ: {summary_elements[0].text}\n"
            except: pass
            
            # Resimler
            if not processed_urls:
                img_elements = driver.find_elements(By.TAG_NAME, "img")
                for img in img_elements:
                    src = img.get_attribute("src")
                    if src and "cdn.dsmcdn" in src and ".jpg" in src and "mnresize" in src:
                        if src not in processed_urls:
                            processed_urls.append(src)
                            if len(processed_urls) >= 3: break 
                            
        except Exception as e:
            print(f"Selenium hatası: {e}")
        
    # --- 3. RESİMLERİ İNDİR (PARALEL) ---
    print(f"Resimler indiriliyor ({len(processed_urls)} adet)...")
    with ThreadPoolExecutor(max_workers=5) as executor:
        results = executor.map(download_image, processed_urls)
        images = [img for img in results if img is not None]

    # --- 4. AI ANALİZİ ---
    try:
        prompt = f"""
        GİRDİLER:
        - Başlık: {header}
        - Özellikler: {feature_text}
        - Kullanıcı Ölçüleri: Boy:{height}, Kilo:{weight}, Omuz:{shoulder}, Bel:{waist}
        - Yorumlar: {reviews_text}
        
       GÖREV 1 (KATEGORİ KONTROLÜ):
        Bu ürün GİYİM veya AYAKKABI mı? (Mouse, Parfüm, Elektronik vb. DEĞİLDİR).
        Değilse valid: false yap.
        
        GÖREV 2 (BEDEN ANALİZİ & YORUM):
        Eğer ürün giyimse:
        1. Kullanıcıya EN UYGUN bedeni "Ana Öneri" olarak belirle.
        2. Ancak sadece bunu söyleme; bir beden büyük veya küçük alırsa üzerindeki duruşunun nasıl değişeceğini anlat.
        3. Kumaş bilgisi ve kalıp yorumlarını (Dar/Bol) kullanarak profesyonel bir terzi gibi tavsiye ver.
        
        ÖRNEK CEVAP TARZI:
        "Sizin için en ideal beden M'dir; omuzlarınıza tam oturacaktır. Ancak daha salaş/oversize bir görünüm isterseniz L beden tercih edebilirsiniz, boyu biraz uzun durabilir. Vücudu sarsın isterseniz S beden dar gelebilir."
        
        {{
            "valid": true (veya false), 
            "message": "Eğer valid false ise buraya 'Bu bir kıyafet değildir.' yaz. Eğer true ise buraya beden önerisini ve nedenini (maksimum 2 cümle) yaz."
        }}
        """
        
        print("AI Analiz Yapıyor (JSON Mod)...")
        
        generation_config = genai.types.GenerationConfig(
            max_output_tokens=400, 
            temperature=0.4, 
            response_mime_type="application/json" 
        )

        response = model.generate_content(
            [prompt] + images,
            generation_config=generation_config
        )
        
        cover_image = processed_urls[0] if processed_urls else ""
        
        return {
            "ai_response": response.text.strip(), 
            "title": header,
            "image_url": cover_image
        }

    except Exception as e:
        return {"error": str(e)}