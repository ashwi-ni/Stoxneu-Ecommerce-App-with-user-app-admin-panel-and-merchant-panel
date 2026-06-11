import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminDashboardService {
  final String baseUrl;
  AdminDashboardService(this.baseUrl);

  Future<Map<String, dynamic>> getDashboard(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/dashboard"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true', // 🔥 Critical for ngrok
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Auth Error: ${response.statusCode}");
    }
  }

}
