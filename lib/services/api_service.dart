import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Django serverinizin ünvanı (Emulator üçün 10.0.2.2, real cihaz üçün lokal IP istifadə edin)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Kateqoriyaları gətirmək üçün metod
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/'));

      if (response.statusCode == 200) {
        // UTF-8 kodlaşdırmasını tənzimləyirik ki, Azərbaycan hərfləri düzgün çıxsın
        utf8.decode(response.bodyBytes);
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception(
          'Kateqoriyaları yükləmək mümkün olmadı: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Xəta baş verdi: $e');
    }
  }
}
