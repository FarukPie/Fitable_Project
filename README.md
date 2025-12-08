# 👕 Fitable - AI Destekli Akıllı Beden Asistanı

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Gemini AI](https://img.shields.io/badge/Google%20Gemini%20AI-8E75B2?style=for-the-badge&logo=googlebard&logoColor=white)

<div align="center">
  <img src="[LOGO_LINKINI_BURAYA_YAPISTIR_VEYA_DOSYA_YOLU]" alt="Fitable Logo" width="200">
  <br>
  <em>"Hangi bedeni almalıyım?" sorusuna yapay zeka destekli kesin çözüm.</em>
</div>

## 🚀 Proje Hakkında

**Fitable**, e-ticaret sitelerinden yapılan alışverişlerde yaşanan "beden uyuşmazlığı" ve yüksek iade oranlarını çözmek için geliştirilmiş bir mobil uygulamadır.

Kullanıcılar, Trendyol, Zara, Bershka gibi uygulamalarda gezerken beğendikleri ürünün linkini **Fitable** ile paylaştıklarında; arka planda çalışan yapay zeka algoritmamız ürünün kalıbını, kumaş yapısını ve beden tablosunu analiz eder. Kullanıcının önceden girdiği vücut ölçüleri ile eşleştirerek en doğru bedeni (Örn: "Sana M beden tam olur, kumaşı esnektir") önerir.

## 📱 Ekran Görüntüleri

<div align="center">
  <img src="[SS_1_LINKI]" width="250" alt="Ana Ekran">
  <img src="[SS_2_LINKI]" width="250" alt="Analiz Sonucu">
  <img src="[SS_3_LINKI]" width="250" alt="Profil Ekranı">
</div>

## 🛠️ Kullanılan Teknolojiler (Tech Stack)

Bu proje, modern mobil mimari ve mikroservis yapısı kullanılarak geliştirilmiştir:

* **Frontend (Mobil):**
    * **Flutter (Dart):** Cross-platform (iOS & Android) mobil arayüz.
    * **Share Intent:** Diğer uygulamalardan (Deep Linking) veri yakalama.
* **Backend & Scraping:**
    * **Python:** Web Scraping ve veri işleme motoru.
    * **Selenium / BeautifulSoup:** Dinamik HTML analizi.
    * **FastAPI / Flask:** API yönetimi.
* **Yapay Zeka (AI):**
    * **Google Gemini API:** HTML verisinden beden tablosunu (Size Chart) anlamlandırma ve NLP ile kumaş analizi.
* **Veritabanı & Cloud:**
    * **Firebase Firestore:** NoSQL tabanlı kullanıcı ve ürün veri yönetimi.
    * **Firebase Auth:** Güvenli kullanıcı kimlik doğrulama.

## ⚙️ Nasıl Çalışır? (Mimari)

1.  **Veri Girişi:** Kullanıcı boy, kilo, omuz, bel gibi ölçülerini uygulamaya bir kez girer.
2.  **Link Paylaşımı:** E-ticaret uygulamasındaki "Paylaş" butonuna basar ve Fitable'ı seçer.
3.  **Scraping (Python):** Backend servisimiz linke gider, sayfanın HTML yapısını ve beden tablosunu çeker.
4.  **AI Analizi:** Çekilen karmaşık veri Gemini AI'a gönderilir. AI, bu veriyi temizleyip standart bir JSON formatına dönüştürür.
5.  **Eşleşme:** Kullanıcının ölçüleri ile ürünün kalıbı kıyaslanır.
6.  **Sonuç:** Kullanıcıya saniyeler içinde "Sana L Beden Uygundur" bildirimi gider.

## 📦 Kurulum (Geliştirici İçin)

Projeyi yerel ortamınızda çalıştırmak için:

```bash
# Projeyi klonlayın
git clone [https://github.com/KULLANICI_ADIN/fitable.git](https://github.com/KULLANICI_ADIN/fitable.git)

# Flutter paketlerini yükleyin
cd fitable_app
flutter pub get

# Python gereksinimlerini yükleyin
cd fitable_backend
pip install -r requirements.txt

# Uygulamayı başlatın
flutter run
🗺️ Yol Haritası (Roadmap)
[x] Kullanıcı Profili ve Ölçü Girişi

[x] Python ile Web Scraping Motoru

[x] Gemini AI Entegrasyonu

[ ] iOS & Android Store Yayını

[ ] Premium Üyelik Sistemi

[ ] Daha Fazla Marka Entegrasyonu
![IMG-20251202-WA0010](https://github.com/user-attachments/assets/a07b5b83-b92d-4261-8a28-d12fc0e845fc)
![IMG-20251202-WA0007](https://github.com/user-attachments/assets/a8a1fd0c-6c5c-4fb9-bf87-861a38f5c4c5)
![IMG-20251202-WA0008](https://github.com/user-attachments/assets/2f072349-3e59-4b22-bd41-36eb25f92df7)
![IMG-20251202-WA0009](https://github.com/user-attachments/assets/151039cc-64e9-4e0d-b7f2-52d48c370c40)
![IMG-20251202-WA0006](https://github.com/user-attachments/assets/af27b8fd-42d5-4f78-b0c6-a55f4963ceff)

