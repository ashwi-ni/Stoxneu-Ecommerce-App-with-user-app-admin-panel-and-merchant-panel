import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:stoxneu/config/api_config.dart';

import '../../../../Screens/Auth/repository/auth_repository.dart';


class CouponApiService {
  final AuthRepository authRepository;
  final String baseUrl = ApiConfig.baseUrl;

  CouponApiService({required this.authRepository});

  Future<void> createCoupon(Map<String, dynamic> couponData) async {
    final token = await authRepository.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/merchant/coupons"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true"
      },
      body: jsonEncode(couponData),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Failed to create coupon");
    }
  }

  // 📋 Fetch Coupons for the list
  Future<List<dynamic>> fetchMerchantCoupons() async {
    final token = await authRepository.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/coupons"),
      headers: {
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load coupons");
    }
  }
// Inside CouponApiService class

  Future<void> toggleCouponStatus(int id, int status) async {
    final token = await authRepository.getToken();
    final response = await http.patch(
      Uri.parse("$baseUrl/merchant/coupons/$id/status"),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json", "ngrok-skip-browser-warning": "true"},
      body: jsonEncode({"status": status}),
    );
    if (response.statusCode != 200) throw Exception("Status update failed");
  }

  Future<void> deleteCoupon(int id) async {
    final token = await authRepository.getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/merchant/coupons/$id"),
      headers: {"Authorization": "Bearer $token", "ngrok-skip-browser-warning": "true"},
    );
    if (response.statusCode != 200) throw Exception("Delete failed");
  }

  Future<void> updateCoupon(int id, Map<String, dynamic> data) async {
    final token = await authRepository.getToken();

    final response = await put(
      Uri.parse("$baseUrl/merchant/coupons/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update coupon: ${response.body}");
    }
  }

}
