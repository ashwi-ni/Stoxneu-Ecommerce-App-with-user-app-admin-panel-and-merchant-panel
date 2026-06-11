import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stoxneu/config/api_config.dart';
import '../../Auth/repository/auth_repository.dart';
import '../../Auth/services/auth_service.dart';
import '../../Products/model/product_model.dart';

class WishListApiService {
  final AuthRepository authRepository;
  static  String baseUrl = ApiConfig.baseUrl; // your backend

  WishListApiService({required this.authRepository});

  Future<Map<String, String>> _getHeaders() async {
    final token = await authRepository.getToken();
    if (token == null) throw Exception("User not logged in");
    return {
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Product>> fetchWishlist() async {
    try {
      final headers = await _getHeaders();

      print("📤 REQUEST HEADERS: $headers");

      final response = await http.get(
        Uri.parse("$baseUrl/wishlist"),
        headers: headers,
      );

      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        throw Exception(
          "Wishlist API error ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      print("❌ API EXCEPTION: $e");
      rethrow;
    }
  }
  Future<void> addToWishlist(Product product) async {
    final response = await http.post(
      Uri.parse("$baseUrl/wishlist"),
      headers: await _getHeaders(),
      body: json.encode({"productId": product.id}),
    );

    if (response.statusCode != 201) {
      print("Add wishlist failed: ${response.body}");
      throw Exception("Failed to add to wishlist");
    }
  }

  Future<void> removeFromWishlist(int productId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/wishlist/$productId"),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      print("Remove wishlist failed: ${response.body}");
      throw Exception("Failed to remove from wishlist");
    }
  }
}