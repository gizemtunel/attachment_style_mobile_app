import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Windows üzerinde çalıştığı için adresi 127.0.0.1 (localhost) olarak güncelledik.
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>?> analizEt(String kullaniciMetni) async {
    final url = Uri.parse('$baseUrl/analiz-et');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        },
        body: jsonEncode({"text": kullaniciMetni}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("Sunucu Hatası: Kod ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Bağlantı Hatası: Sunucu açık mı? Detay: $e");
      return null;
    }
  }
}