import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Python Backend Adresi
  // (Eğer telefonda test ediyorsan buraya Ngrok linkini, emülatörde 10.0.2.2, web'de 127.0.0.1 yazmalısın)
  static const String _baseUrl = 'https://fitable.onrender.com'; 

  // Analiz İsteği Gönderen Fonksiyon
  static Future<Map<String, dynamic>> analizEt({
    required String url,
    required String boy,
    required String kilo,
    required String omuz,
    required String bel,
  }) async {
    
    final uri = Uri.parse('$_baseUrl/analyze');

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "url": url,
          "user_height": int.tryParse(boy) ?? 180,
          "user_weight": int.tryParse(kilo) ?? 80,
          "user_shoulder": int.tryParse(omuz) ?? 0,
          "user_waist": int.tryParse(bel) ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        // Başarılıysa veriyi döndür (UTF-8 desteğiyle)
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        // Sunucu hatası varsa
        return {"error": "Sunucu Hatası: ${response.statusCode}"};
      }
    } catch (e) {
      // Bağlantı hatası varsa
      return {"error": "Bağlantı Hatası: $e"};
    }
  }
}