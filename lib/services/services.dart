import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000/api'
        : 'http://127.0.0.1:8000/api';
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return _authRequest('register', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _authRequest('login', {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    String? name,
  }) {
    final requestBody = switch (provider) {
      'apple' => {'identity_token': token, 'name': name ?? ''},
      'facebook' => {'access_token': token},
      'google' => {'id_token': token},
      _ => throw ArgumentError.value(provider, 'provider'),
    };
    return _authRequest('social/$provider', requestBody);
  }

  static Future<Map<String, dynamic>> _authRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/$endpoint/'),
          headers: const {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = json.decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded is Map
          ? decoded['detail'] ?? decoded.values.first
          : decoded;
      throw Exception('Django giriş xətası: $detail');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['access'] is! String ||
        decoded['refresh'] is! String ||
        decoded['user'] is! Map) {
      throw const FormatException('Django auth cavabı düzgün formatda deyil.');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> refreshAccessToken(
    String refreshToken,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/refresh/'),
          headers: const {'Content-Type': 'application/json'},
          body: json.encode({'refresh': refreshToken}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
        'Django sessiyası yenilənmədi (HTTP ${response.statusCode}).',
      );
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['access'] is! String) {
      throw const FormatException('Django token yeniləməsi düzgün deyil.');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/me/'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
        'Django istifadəçi profili yüklənmədi '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Django profil cavabı düzgün deyil.');
    }
    return decoded;
  }

  // 1. Məhsulları çəkmək üçün
  static Future<List<dynamic>> getProducts() async {
    final response = await http
        .get(Uri.parse('$baseUrl/products/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List<dynamic>) return decoded;
      throw const FormatException(
        'Django məhsul siyahısı düzgün formatda deyil.',
      );
    }
    throw Exception(
      'Məhsulları yükləmək mümkün olmadı '
      '(HTTP ${response.statusCode}): ${response.body}',
    );
  }

  // Kateqoriyaları çəkmək üçün
  static Future<List<dynamic>> getCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl/categories/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List<dynamic>) return decoded;
      throw const FormatException(
        'Django kateqoriya siyahısı düzgün formatda deyil.',
      );
    }
    throw Exception(
      'Kateqoriyaları yükləmək mümkün olmadı (HTTP ${response.statusCode}): ${response.body}',
    );
  }

  static Future<List<Map<String, dynamic>>> getCart(String cartId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/cart/$cartId/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(
        'Səbəti Django-dan yükləmək mümkün olmadı '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw const FormatException('Django səbət cavabı düzgün formatda deyil.');
    }
    return (decoded['items'] as List).map((item) {
      if (item is! Map) {
        throw const FormatException('Django səbət sətri düzgün deyil.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Future<void> saveCart(
    String cartId,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/cart/$cartId/'),
          headers: const {'Content-Type': 'application/json'},
          body: json.encode({'items': items}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(
        'Səbəti Django-da saxlamaq mümkün olmadı '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required String name,
    required String email,
    required String phone,
    required String deliveryAddress,
    required String cartId,
    String? promoCode,
    required String authToken,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: json.encode({
            'user': {'name': name, 'email': email, 'phone': phone},
            'cart_id': cartId,
            'items': items,
            'delivery_address': deliveryAddress,
            'promo_code': promoCode ?? '',
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 201) {
      throw Exception(
        'Sifarişi Django-da yaratmaq mümkün olmadı '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Django sifariş cavabı düzgün deyil.');
    }
    return decoded;
  }

  // 2. Mağazaları (Shops) çəkmək üçün
  static Future<List<dynamic>> getShops() async {
    final response = await http
        .get(Uri.parse('$baseUrl/shops/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Mağazaları yükləmək mümkün olmadı');
  }

  // 3. Sifarişləri (Orders) çəkmək üçün
  static Future<List<dynamic>> getOrders({required String authToken}) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/orders/'),
          headers: {'Authorization': 'Bearer $authToken'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List<dynamic>) return decoded;
      throw const FormatException('Django sifariş siyahısı düzgün deyil.');
    }
    throw Exception(
      'Sifarişləri Django-dan yükləmək mümkün olmadı '
      '(HTTP ${response.statusCode}): ${response.body}',
    );
  }

  // 4. İstifadəçiləri çəkmək üçün
  static Future<List<dynamic>> getUsers() async {
    final response = await http
        .get(Uri.parse('$baseUrl/users/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('İstifadəçiləri yükləmək mümkün olmadı');
  }
}
