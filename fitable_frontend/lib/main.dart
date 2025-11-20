import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON verisini okumak için

void main() {
  runApp(const FitableApp());
}

class FitableApp extends StatelessWidget {
  const FitableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitable',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  // Kullanıcının girdiği verileri tutan kontrolcüler
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _boyController = TextEditingController();
  final TextEditingController _kiloController = TextEditingController();

  String _sonucMetni = "Analiz sonucu burada görünecek...";
  bool _yukleniyor = false; // Yükleniyor animasyonu için

  // --- PYTHON'A BAĞLANAN FONKSİYON ---
  Future<void> analizEt() async {
    // 1. Veriler boş mu kontrol et
    if (_urlController.text.isEmpty) {
      setState(() {
        _sonucMetni = "Lütfen bir link girin!";
      });
      return;
    }

    setState(() {
      _yukleniyor = true; // Yükleniyor ikonunu göster
      _sonucMetni = "Yapay Zeka ürünü inceliyor, lütfen bekle...";
    });

    // 2. İstek Hazırla (Backend Adresini Buraya Yazıyoruz)
    // DİKKAT: Chrome'da test ediyorsan '127.0.0.1' çalışır.
    // Eğer telefonda test edersen buraya Ngrok linkini koyacağız.
    final url = Uri.parse('http://127.0.0.1:8000/analyze');

    try {
      // 3. Verileri Gönder
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "url": _urlController.text,
          "user_height": int.tryParse(_boyController.text) ?? 180, // Boşsa 180 al
          "user_weight": int.tryParse(_kiloController.text) ?? 80, // Boşsa 80 al
        }),
      );

      // 4. Cevabı Al ve Göster
      if (response.statusCode == 200) {
        final gelenVeri = jsonDecode(utf8.decode(response.bodyBytes)); // Türkçe karakter düzeltmesi
        setState(() {
          _sonucMetni = gelenVeri['analysis']; // Backend'den gelen 'analysis' kısmı
        });
      } else {
        setState(() {
          _sonucMetni = "Hata: Sunucuya bağlanılamadı. (Kod: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _sonucMetni = "Bağlantı Hatası: $e \n\nBackend çalışıyor mu?";
      });
    } finally {
      setState(() {
        _yukleniyor = false; // Yükleme bitti
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fitable AI"),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LOGO
              const Icon(Icons.checkroom, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              
              // LİNK GİRİŞİ
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: "Trendyol Ürün Linki",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 15),

              // BOY VE KİLO (Yan Yana)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _boyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Boy (cm)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _kiloController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Kilo (kg)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // BUTON
              ElevatedButton.icon(
                onPressed: _yukleniyor ? null : analizEt, // Yüklenirken tıklamayı kapat
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: _yukleniyor 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _yukleniyor ? "ANALİZ EDİLİYOR..." : "BEDENİMİ BUL",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 25),

              // SONUÇ KUTUSU
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🤖 Yapay Zeka Önerisi:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    Text(
                      _sonucMetni,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}