import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../../../config/api_config.dart';
import '../merchant_model.dart';


class MerchantApi {
  static final String baseUrl = ApiConfig.baseUrl;

  static Future<Merchant> fetchProfile(String token) async {
    final response = await http.get(Uri.parse("$baseUrl/merchant/me"), headers: _headers(token));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Merchant.fromJson(data is List ? data[0] : data);
    }
    throw Exception("Failed to load profile");
  }
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'ngrok-skip-browser-warning': 'true', // Required to bypass ngrok warning
  };
  static Future<Merchant> updateProfile(String token, Merchant merchant, {Uint8List? imageBytes, String? fileName}) async {
    var request = http.MultipartRequest('PUT', Uri.parse("$baseUrl/merchant/me"));
    request.headers.addAll(_headers(token));
    request.fields.addAll({
      'name': merchant.name,
      'email': merchant.email ?? '',
      'phone': merchant.phone ?? '',
    });

    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('avatar', imageBytes, filename: fileName ?? 'profile.jpg'));
    }

    var response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Merchant.fromJson(data is List ? data[0] : data);
    }
    throw Exception("Update failed");
  }
}


