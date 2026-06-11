import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Ensure this is in pubspec.yaml
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stoxneu/config/api_config.dart';
import '../../../../Screens/Products/model/BannerModel.dart';

class BannerService {
  final String baseUrl = ApiConfig.baseUrl;
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  // 1. FIXED GET: Added Ngrok Header
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/banners"),
        headers: {
          'ngrok-skip-browser-warning': 'true', // REQUIRED for Ngrok
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => BannerModel.fromJson(e)).toList();
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch Error: $e");
      throw Exception("Connection Error: $e");
    }
  }

  // 2. POST: Create Banner
  Future<bool> createBanner(dynamic imageInput, String type,
      String link) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse("$baseUrl/admin/banners"));
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.fields['type'] = type;
      request.fields['link'] = link;

      if (kIsWeb && imageInput is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageInput,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (imageInput is File) {
        request.files.add(
            await http.MultipartFile.fromPath('image', imageInput.path));
      }

      var response = await request.send();
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Upload error: $e");
      return false;
    }
  }

  // 3. PATCH: Update Status
// Generic update for Edit Icon
// 1. Generic update (Type & Link)
  Future<bool> updateBanner(int id, String type, String link) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/admin/banners/$id"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'type': type,
          'link': link,
        }),
      );

      // DEBUG PRINT: Check your terminal for this!
      print("📡 STATUS CODE: ${response.statusCode}");
      print("📡 RESPONSE BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("❌ FETCH ERROR: $e");
      return false;
    }
  }


// 2. Status update (Published Toggle)
  Future<bool> updateBannerStatus(int id, bool isPublished) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/admin/banners/$id"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // MUST be in every request
        },
        body: json.encode({'is_published': isPublished}),
      );
      return response.statusCode == 200;
    } catch (e) {
      // On Web, this catch blocks 'Failed to fetch' errors
      debugPrint("❌ PATCH Error: $e");
      return false;
    }
  }


  // 4. DELETE: Remove banner
  Future<bool> deleteBanner(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/admin/banners/$id"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

// Fetch Products for Dropdown
  // Fetch Products for Dropdown (Admin)
  Future<List<Map<String, dynamic>>> getAvailableProducts() async {
    try {
      String? token = await storage.read(key: 'jwt'); // Ensure storage is initialized
      final response = await http.get(
        Uri.parse("$baseUrl/admin/products"),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Access the 'data' key as per your Node.js response
        List data = decoded['data'] ?? [];
        return data.map((e) => {"id": e['id'], "name": e['name']}).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

// Fetch Categories for Dropdown (Admin)
  Future<List<Map<String, dynamic>>> getAvailableCategories() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/categories"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Access the 'data' key
        List data = decoded['data'] ?? [];
        return data.map((e) => {"id": e['id'], "name": e['name']}).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

}