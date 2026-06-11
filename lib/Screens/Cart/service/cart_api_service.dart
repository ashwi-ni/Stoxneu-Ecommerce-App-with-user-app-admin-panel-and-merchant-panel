import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stoxneu/config/api_config.dart';
import '../../Auth/repository/auth_repository.dart';
import '../../Products/model/product_model.dart';
import '../model/cart_item_model.dart';

class CartApiService {
  final AuthRepository authRepository;
 final String baseUrl = ApiConfig.baseUrl;

  CartApiService({required this.authRepository});

  Future<Map<String, String>> _getHeaders() async {
    final token = await authRepository.getToken();
    if (token == null) throw Exception("User not logged in");
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch cart
  Future<List<CartItem>> fetchCart() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/cart'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load cart: ${response.body}');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) {
      final product = Product(
        id: e['product_id'] is String ? int.parse(e['product_id']) : e['product_id'],
        name: e['name'] ?? '',
        price: double.parse(e['price'].toString()),
        mrp: double.parse(e['mrp'].toString()),
        imageUrl: e['image_url'] ?? '',
        subCategoryId: e['sub_category_id'],
        categoryId: e['category_id'],
        sku: e['sku'] ?? '',
      );

      return CartItem(
        product: product,
        quantity: e['quantity'] is String ? int.parse(e['quantity']) : e['quantity'],
      );
    }).toList();
  }

  // Add to cart
  Future<void> addToCart(int productId, int quantity) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: headers,
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add to cart: ${response.body}');
    }
  }

  // Update quantity
  Future<void> updateCartItem(int productId, int change) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/cart/update'),
      headers: headers,
      body: jsonEncode({'product_id': productId, 'change': change}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update cart item');
    }
  }

  // Delete item
  Future<void> deleteFromCart(int productId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete item');
    }
  }

  // Clear cart
  Future<void> emptyCart() async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/cart'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to clear cart');
    }
  }
}