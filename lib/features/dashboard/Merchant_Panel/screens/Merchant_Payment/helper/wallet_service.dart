import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';



class WalletService {
  final String baseUrl;
  final AuthRepository authRepository;
  List<Map<String, dynamic>> savedPaymentMethods = [];

  WalletService({required this.baseUrl, required this.authRepository});

  Future<void> fetchSavedPaymentMethods() async {
    final token = await authRepository.getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/merchant/payment-methods"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // 🔥 IMPORTANT
      },
    );

    print("METHOD STATUS: ${res.statusCode}");
    print("METHOD BODY: ${res.body}");

    if (res.statusCode == 200) {
      savedPaymentMethods =
      List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } else {
      throw Exception("Failed to fetch payment methods");
    }
  }

  Future<void> savePaymentMethod(String type, Map<String, dynamic> details) async {
    final token = await authRepository.getToken();
    final res = await http.post(
      Uri.parse("$baseUrl/merchant/payment-method"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',

      },
      body: jsonEncode({'type': type, 'details': details}),
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to save payment method");
    }
    await fetchSavedPaymentMethods(); // refresh local cache
  }


  /// 🔹 Get wallet balance
  Future<double> getWalletBalance() async {
    final url = Uri.parse('$baseUrl/merchant/wallet');
    final response = await _safeGet(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final balanceRaw = data['balance'];
      // Convert to double safely
      double balance;
      if (balanceRaw is num) {
        balance = balanceRaw.toDouble();
      } else if (balanceRaw is String) {
        balance = double.tryParse(balanceRaw) ?? 0.0;
      } else {
        balance = 0.0;
      }

      return balance;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch wallet balance');
    }
  }

  /// 🔹 Request payout
  Future<String> requestPayout(double amount) async {
    final url = Uri.parse('$baseUrl/merchant/payouts');
    final response = await _safePost(url, {'amount': amount});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'] ?? 'Payout requested';
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Payout request failed');
    }
  }

  /// 🔹 Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    final token = await authRepository.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/merchant/payouts"), // ✅ correct
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    print("HISTORY STATUS: ${response.statusCode}");
    print("HISTORY BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // 👇 handle both list or wrapped response
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        return [];
      }
    } else {
      throw Exception("Failed: ${response.body}");
    }
  }

/// DELETE payout
  Future<bool> deletePayout(int payoutId) async {
    final token = await authRepository.getToken();
    final url = Uri.parse("$baseUrl/merchant/payout/$payoutId");

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',

      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete payout');
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }

  /// 🔹 Safe GET request with token
  Future<http.Response> _safeGet(Uri url) async {
    final headers = await _getHeaders();
    try {
      return await http.get(url, headers: headers);
    } on SocketException {
      throw Exception('No internet connection or cannot reach backend');
    } on HttpException {
      throw Exception('HTTP error fetching data');
    } on FormatException {
      throw Exception('Invalid response format from backend');
    }
  }

  /// 🔹 Safe POST request with token
  Future<http.Response> _safePost(Uri url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    try {
      return await http.post(url, headers: headers, body: json.encode(body));
    } on SocketException {
      throw Exception('No internet connection or cannot reach backend');
    } on HttpException {
      throw Exception('HTTP error posting data');
    } on FormatException {
      throw Exception('Invalid response format from backend');
    }
  }

  /// 🔹 Get headers with valid token
  Future<Map<String, String>> _getHeaders() async {
    final token = await authRepository.getToken();
    if (token == null) {
      throw Exception('Token missing or expired. Please login again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }
// Fetch the stats for the 4 top cards
  Future<Map<String, dynamic>> getWalletStats() async {
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/wallet/stats"),
      headers: {'Authorization': 'Bearer ${authRepository.token}', 'ngrok-skip-browser-warning': 'true'},
    );
    return jsonDecode(response.body);
  }

// Delete/Cancel a pending request
  Future<bool> deletePayoutRequest(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/merchant/payout/$id"), // Matches your app.delete("/merchant/payout/:id")
      headers: {'Authorization': 'Bearer ${authRepository.token}', 'ngrok-skip-browser-warning': 'true'},
    );
    return response.statusCode == 200;
  }

}