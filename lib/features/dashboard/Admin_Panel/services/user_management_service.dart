import 'dart:convert';

import 'package:http/http.dart' as http;

class UserManagementService {
  final String baseUrl;

  UserManagementService(this.baseUrl);

  Future<List<dynamic>> getAllUsers(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/users"),
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );
    return jsonDecode(response.body);
  }

  Future<bool> toggleBlock(String token, int userId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/users/$userId/toggle-block"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteUser(String token, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/admin/users/$userId"),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print("DELETE STATUS: ${response.statusCode}");
      print("DELETE BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Service Delete Error: $e");
      return false;
    }
  }

}