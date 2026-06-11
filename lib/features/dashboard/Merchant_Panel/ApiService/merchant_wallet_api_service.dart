import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';

import '../../../../config/api_config.dart';

class MerchantWalletApiService {
  static final String baseUrl = ApiConfig.baseUrl;
  final AuthRepository authRepository;

  MerchantWalletApiService({required this.authRepository});

  /// 🔹 Safe headers: ensures token is valid
  Future<Map<String, String>> _getHeaders() async {
    final token = await authRepository.getToken();
    if (token == null) {
      throw Exception("Token missing or expired. Please login again.");
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// 🔹 Get current wallet balance
  Future<double> getWalletBalance() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/wallet"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['balance'] as num).toDouble();
    } else {
      throw Exception("Failed to fetch wallet balance: ${response.body}");
    }
  }

  /// 🔹 Request payout
  Future<String> requestPayout(double amount) async {
    final token = await authRepository.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/merchant/payouts"), // ✅ CORRECT
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({'amount': amount}),
    );

    print("PAYOUT STATUS: ${response.statusCode}");
    print("PAYOUT BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'];
    } else {
      throw Exception(response.body);
    }
  }

  /// 🔹 Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/payouts"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to fetch payout history: ${response.body}");
    }
  }


}