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
import google.generativeai as genai

# --- AYARLAR ---
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-2.0-flash', system_instruction="Sen uzman bir e-ticaret ve moda analistisin.")

def analyze_product_logic(url, height, weight, shoulder, waist):
    # --- 1. TARAYICI AYARLARI (TURBO MOD 🚀) ---
    chrome_options = Options()
    chrome_options.add_argument("--headless") 
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.page_load_strategy = 'eager' 
    
    # Resimleri tarayıcıda engelle (Hız için)
    prefs = {
        "profile.managed_default_content_settings.images": 2, 
        "profile.managed_default_content_settings.stylesheets": 2, 
    }
    chrome_options.add_experimental_option("prefs", prefs)
    
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)
    
    try:
        print(f"Linke gidiliyor: {url}")
        driver.get(url)
        
        driver.execute_script("window.scrollTo(0, 500);")
        time.sleep(1) 

        # --- METİN VERİSİ ---
        try:
            header = driver.find_element(By.TAG_NAME, "h1").text
            features = driver.find_elements(By.CSS_SELECTOR, ".detail-attr-container li")
            feature_text = "\n".join([f.text for f in features[:5]]) 
        except:
            header = "Başlık alınamadı"
            feature_text = ""

        # --- YORUMLAR (AKILLI VERSİYON) ---
        reviews_text = ""
        found_summary = False

        try:
            fit_elements = driver.find_elements(By.CSS_SELECTOR, "[class*='fit-survey']")
            if fit_elements and fit_elements[0].text.strip():
                reviews_text += f"🚨 TRENDYOL KALIP UYARISI: {fit_elements[0].text}\n"
                found_summary = True
        except: pass

        if not found_summary:
            try:
                summary_elements = driver.find_elements(By.CSS_SELECTOR, "[class*='review-summary']")
                if summary_elements and len(summary_elements[0].text) > 20:
                    reviews_text += f"📊 MAĞAZA YORUM ÖZETİ: {summary_elements[0].text}\n"
                    found_summary = True
            except: pass

        if not found_summary:
            try:
                comments = driver.find_elements(By.CSS_SELECTOR, ".rnr-com-tx")
                for i, comment in enumerate(comments[:3]):
                    if comment.text.strip():
                        reviews_text += f"- Yorum: {comment.text}\n"
            except: reviews_text = "Yorum yok."

        # --- RESİMLER ---
        images = []
        img_elements = driver.find_elements(By.TAG_NAME, "img")
        processed_urls = []
        
        print("Resimler işleniyor...")
        for img in img_elements:
            src = img.get_attribute("src")
            if src and "cdn.dsmcdn" in src and ".jpg" in src and "mnresize" in src:
                if src not in processed_urls:
                    processed_urls.append(src)
                    try:
                        resp = requests.get(src, timeout=3)
                        if resp.status_code == 200:
                            img_data = Image.open(BytesIO(resp.content))
                            img_data.thumbnail((800, 800)) 
                            images.append(img_data)
                    except: pass
                    
                    if len(images) >= 5: break
        
        # ---------------------------------------------------------
        # 4. AI ANALİZİ (JSON FORMATLI & SIFIR TOLERANS 🛡️)
        # ---------------------------------------------------------
        prompt = f"""
        GİRDİLER:
        - Başlık: {header}
        - Özellikler: {feature_text}
        - Kullanıcı Ölçüleri: Boy:{height}, Kilo:{weight}, Omuz:{shoulder}, Bel:{waist}
        - Yorumlar: {reviews_text}
        
        GÖREV 1 (KATEGORİ KONTROLÜ - ÇOK KRİTİK):
        Bu ürün giyilebilir bir "Kıyafet" (Tişört, Pantolon, Mont, Elbise, İç Giyim, Mayo) veya "Ayakkabı" mı?
        - Mouse, Klavye, Telefon, Parfüm, Krem, Çanta, Saat, Takı, Ev Eşyası, Elektronik vb. KESİNLİKLE KIYAFET DEĞİLDİR.
        
        GÖREV 2 (BEDEN ANALİZİ):
        Sadece ve sadece ürün KIYAFET ise beden önerisi yap.
        - ASLA "Denenmeli" deme. Kararlı ol. Tek bir beden seç.
        
        ÇIKTI FORMATI (SADECE JSON):
        Bana süslü cümleler kurma. Sadece aşağıdaki JSON formatını doldur ve ver:
        
        {{
            "valid": true (veya false), 
            "message": "Eğer valid false ise buraya 'Bu bir kıyafet değildir.' yaz. Eğer true ise buraya beden önerisini ve nedenini (maksimum 2 cümle) yaz."
        }}
        """
        
        print("AI Analiz Yapıyor (JSON Mod)...")
        
        generation_config = genai.types.GenerationConfig(
            max_output_tokens=200, 
            temperature=0.0, # Yaratıcılık sıfır, sadece mantık
            response_mime_type="application/json" # Cevabı JSON olmaya zorla
        )

        response = model.generate_content(
            [prompt] + images,
            generation_config=generation_config
        )
        
        cover_image = processed_urls[0] if processed_urls else ""
        
        # AI'dan gelen JSON'u "ai_response" anahtarı ile Frontend'e gönderiyoruz
        return {
            "ai_response": response.text.strip(), 
            "title": header,
            "image_url": cover_image
        }

    except Exception as e:
        return {"error": str(e)}
    finally:
        try:
            driver.quit()
        except: pass