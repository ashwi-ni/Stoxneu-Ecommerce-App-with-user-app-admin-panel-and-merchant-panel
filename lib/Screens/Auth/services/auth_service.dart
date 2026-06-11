import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:stoxneu/config/api_config.dart';

class AuthApiService {
  static final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body, {
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final defaultHeaders = {'Content-Type': 'application/json'};

    if (headers != null) {
      defaultHeaders.addAll(headers);
      // ✅ merge auth header
    }
    debugPrint("POST to $endpoint with HEADERS: $defaultHeaders");
    debugPrint("POST body: $body");
    final response = await http.post(
      uri,
      headers: defaultHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Something went wrong');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? headers}) async {

    final uri = Uri.parse("$baseUrl$endpoint");

    // Merge default headers with any provided
    final defaultHeaders = {'Content-Type': 'application/json',
      "ngrok-skip-browser-warning": "anyValue",
    };
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    debugPrint("GET from $endpoint with HEADERS: $defaultHeaders");
    final response = await http.get(
      uri,
      headers: defaultHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception("GET request failed: ${response.body}");
    }
  }

  // Inside your AuthApiService class
  Future<dynamic> put(String endpoint, dynamic body, {Map<String, String>? headers}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final combinedHeaders = {"Content-Type": "application/json", ...?headers};

    try {
      final response = await http.put(url, headers: combinedHeaders, body: jsonEncode(body));

      // 🔥 CRITICAL: You must return the decoded body, not just the response object
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("PUT Request Failed: $e");
    }
  }


}
