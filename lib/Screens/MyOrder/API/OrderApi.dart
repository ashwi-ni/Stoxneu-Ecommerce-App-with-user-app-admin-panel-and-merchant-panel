import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stoxneu/config/api_config.dart';
import '../model/order_model.dart';
import '../../Auth/repository/auth_repository.dart';

class OrderApiService {
  static final String baseUrl = ApiConfig.baseUrl;
  final AuthRepository authRepository;

  OrderApiService({required this.authRepository});

  /// Helper to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await authRepository.getToken();
    if (token == null) {
      throw Exception("User not logged in");
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // ⭐ IMPORTANT

    };
  }

  /// 📦 GET MY ORDERS
  Future<List<Order>> fetchOrders() async {
    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
      headers: await _getHeaders(),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load orders: ${response.body}");
    }
  }

  /// ➕ CREATE ORDER
  Future<void> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse("$baseUrl/orders"),
      headers: await _getHeaders(),
      body: json.encode(order.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception("Order creation failed: ${response.body}");
    }
  }

  /// 💸 REQUEST REFUND
  /// 💸 REQUEST REFUND
  Future<void> requestRefund(String orderId, String reason, int productId) async { // Added reason param
    final response = await http.post(
      Uri.parse("$baseUrl/orders/$orderId/refund"),
      headers: await _getHeaders(),
      body: json.encode({"reason": reason,"productId": productId, }), // Pass reason to backend
    );

    if (response.statusCode != 200) {
      throw Exception("Refund request failed: ${response.body}");
    }
  }
}
