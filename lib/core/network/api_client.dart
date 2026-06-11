import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const _storage = FlutterSecureStorage();

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    // Fetch the token from storage
    String? token = await _storage.read(key: 'jwt');

    final defaultHeaders = {
      "ngrok-skip-browser-warning": "true",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token", // 🔑 ADD THIS LINE
    };

    return http.get(
      url,
      headers: {...defaultHeaders, ...?headers},
    );
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    String? token = await _storage.read(key: 'jwt');

    final defaultHeaders = {
      "ngrok-skip-browser-warning": "true",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token", // 🔑 ADD THIS LINE
    };

    return http.post(
      url,
      headers: {...defaultHeaders, ...?headers},
      body: body,
    );
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt');

    final defaultHeaders = {
      "ngrok-skip-browser-warning": "true",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    return http.delete(url, headers: {...defaultHeaders, ...?headers});
  }

  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body}) async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt');

    final defaultHeaders = {
      "ngrok-skip-browser-warning": "true",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    return http.patch(
      url,
      headers: {...defaultHeaders, ...?headers},
      body: body,
    );
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt');

    final defaultHeaders = {
      "ngrok-skip-browser-warning": "true",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    return http.put(
      url,
      headers: {...defaultHeaders, ...?headers},
      body: body,
    );


  }
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }
}
