import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stoxneu/Screens/Products/model/product_model.dart';
import 'package:stoxneu/config/api_config.dart';
import '../../../../Screens/Auth/repository/auth_repository.dart';
import '../../../../core/network/api_client.dart';


class MerchantProductApi {

  final AuthRepository authRepository;

  MerchantProductApi({required this.authRepository});

  final String baseUrl = ApiConfig.baseUrl;

  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required double mrp,
    required int categoryId,
    required int subCategoryId,
    required String imageUrl,
  }) async {
    final token = await authRepository.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/merchant/products"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true"
      },
      body: jsonEncode({
        "category_id": categoryId,
        "sub_category_id": subCategoryId,
        "name": name,
        "description": description,
        "price": price,
        "mrp": mrp,
        "image_url": imageUrl
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to add product");
    }
  }

  /// Fetch products of the logged-in merchant
  Future<List<Product>> fetchMerchantProducts() async {
    final token = await authRepository.getToken();
    if (token == null) throw Exception("Merchant not logged in");

    final res = await ApiClient.get(
      Uri.parse('$baseUrl/merchant/products'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load merchant products: ${res.statusCode} ${res.body}');
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  Future<void> deleteProduct(int productId) async {
    final token = await authRepository.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("No auth token found");
    }

    final url = Uri.parse("$baseUrl/merchant/products/$productId");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      // Include response body for debugging
      throw Exception(
          "Failed to delete product: ${response.statusCode} ${response.body}");
    }
  }

  /// 2️⃣ New method to update a product
  Future<void> updateProduct(int productId, Map<String, dynamic> data) async {
    final token = await authRepository.getToken(); // get JWT token

    final url = Uri.parse("$baseUrl/merchant/products/$productId");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'name': data['name'],
        'price': data['price'],
        'mrp': data['mrp'],
      }),
    );

    if (response.statusCode == 200) {
      // success, optionally parse response if needed
      return;
    } else if (response.statusCode == 404) {
      throw Exception("Product not found");
    } else {
      throw Exception("Failed to update product: ${response.body}");
    }
  }

  /// 🔄 Toggle Product Active Status (Vendor only)
  Future<void> toggleStatus(int productId, int isActive) async {
    final token = await authRepository.getToken();
    if (token == null) throw Exception("Merchant not logged in");

    final url = Uri.parse("$baseUrl/merchant/products/$productId/toggle-status");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true"
      },
      body: jsonEncode({"is_active": isActive}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update status: ${response.body}");
    }
  }

  Future<void> updateStock(int productId, int newStock) async {
    final token = await authRepository.getToken();
    final url = Uri.parse("$baseUrl/merchant/products/$productId/stock");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true"
      },
      body: jsonEncode({"stock_quantity": newStock}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update stock: ${response.body}");
    }
  }
  Future<void> storeFlashDeals(Map<String, dynamic> payload) async {
    // 1. Updated URL to a dedicated endpoint for bulk flash deals
    final url = Uri.parse("$baseUrl/merchant/flash-deals");

    final token = await authRepository.getToken();
    if (token == null) throw Exception("Merchant not logged in");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true', // Added for ngrok compatibility
        },
        body: jsonEncode(payload),
      );

      // 2. Handle both 200 (OK) and 201 (Created)
      if (response.statusCode != 200 && response.statusCode != 201) {
        // Try to parse error message from server if available
        String errorMessage = 'Failed to save flash deals';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}

        throw Exception(errorMessage);
      }
    } catch (e) {
      // 3. Re-throw the exception so the UI can catch it
      throw Exception('Connection error: $e');
    }
  }


}
