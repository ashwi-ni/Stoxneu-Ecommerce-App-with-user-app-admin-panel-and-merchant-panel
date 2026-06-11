// merchant_order_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';

import '../../../../config/api_config.dart';
import '../model/refund_model.dart';



class MerchantOrderApiService {
  static final String baseUrl = ApiConfig.baseUrl;
  final AuthRepository authRepository;

  MerchantOrderApiService({required this.authRepository});

  Future<Map<String, String>> _getHeaders() async {
    final token = await authRepository.getToken();
    if (token == null) throw Exception("User not logged in");
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// 📦 Get merchant orders
  /// Fetch orders for the merchant
  Future<List<Order>> fetchMerchantOrders() async {
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/orders"),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load merchant orders: ${response.body}");
    }

    final List data = json.decode(response.body);
    List<Order> orders = [];

    for (var orderJson in data) {
      // Fetch items for each order if backend has a separate endpoint
      List<OrderItem> items = [];
      try {
        final itemsResponse = await http.get(
          Uri.parse("$baseUrl/merchant/orders/${orderJson['id']}/items"),
          headers: await _getHeaders(),
        );
        if (itemsResponse.statusCode == 200) {
          final List itemsData = json.decode(itemsResponse.body);
          items = itemsData.map((e) => OrderItem.fromJson(e)).toList();
        }
      } catch (e) {
        print("Error fetching items for order ${orderJson['id']}: $e");
      }

      // Merge items into order JSON before creating Order object
      orderJson['items'] = items.map((e) => e.toJson()).toList();
      orders.add(Order.fromJson(orderJson));
    }

    return orders;
  }

  /// ✅ Confirm order
  Future<void> confirmOrder(String orderId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/merchant/orders/$orderId/confirm"),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception("Confirm order failed: ${response.body}");
    }
  }

  /// ❌ Cancel order
  Future<void> cancelOrder(String orderId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/merchant/orders/$orderId/cancel"),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception("Cancel order failed: ${response.body}");
    }
  }

  /// 📦 Mark order shipped
  Future<void> markShipped(String orderId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/merchant/orders/$orderId/shipped"),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception("Mark shipped failed: ${response.body}");
    }
  }
  /// 📦 Mark order delivered
  Future<void> markDelivered(String orderId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/merchant/orders/$orderId/delivered"),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception("Mark delivered failed: ${response.body}");
    }
  }

  Future<Order> fetchOrderDetails(String orderId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/orders/$orderId"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        return Order.fromJson(data[0]); // take first element
      } else if (data is Map<String, dynamic>) {
        return Order.fromJson(data);
      } else {
        throw Exception("Invalid response format");
      }
    } else {
      throw Exception("Failed to load order details");
    }
  }

  // ------------------ Initiate Refund API ------------------
// merchant_order_api_service.dart
  Future<bool> initiateRefund(int orderId) async {
    final url = Uri.parse("$baseUrl/merchant/orders/$orderId/return");
    final token = await authRepository.getToken();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      // body: jsonEncode({
      //   "reason": reason,
      //   "comment": comment,
      // }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Refund API failed: ${response.body}");
      return false;
    }
  }  /// Fetch all refund requests
  Future<List<RefundRequest>> fetchRefundRequests(String status) async {
    final token = await authRepository.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/merchant/refunds/$status"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    print("Refund API Response: ${response.body}"); // 👈 DEBUG
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return []; // ✅ handle empty

      final data = json.decode(response.body);

      // ✅ if backend sends []
      if (data is List) {
        return data.map((e) => RefundRequest.fromJson(e)).toList();
      }

      // ✅ if backend sends { message: "No refunds" }
      if (data is Map && data['message'] != null) {
        return [];
      }

      return [];
    } else {
      return []; // ✅ DON'T throw error for empty case
    }
  }

  /// Approve a refund request
  Future<bool> approveRefund(int id, String note) async {
    final token = await authRepository.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/merchant/refunds/$id/approve"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "note": note, // or "admin_note" (check backend)
      }),
    );

    print("APPROVE RESPONSE: ${response.body}");

    return response.statusCode == 200;
  }



  /// Reject a refund request
  Future<bool> rejectRefund(int id, String note) async {
    final token = await authRepository.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/merchant/refunds/$id/reject"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "note": note,
      }),
    );

    print("REJECT RESPONSE: ${response.body}");

    return response.statusCode == 200;
  }
}

