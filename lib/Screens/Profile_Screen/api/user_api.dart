import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import '../../../config/api_config.dart';
import '../../Auth/services/auth_service.dart';
import '../model/user_model.dart';

class UserApi {
  static final String baseUrl = ApiConfig.baseUrl; // Emulator URL

  /// Fetch logged-in user details
  static Future<User> fetchMe(String token) async {
    debugPrint("FETCH ME TOKEN => $token");

    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("STATUS => ${res.statusCode}");
    debugPrint("BODY => ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Unable to fetch user");
    }

    return User.fromJson(jsonDecode(res.body));
  }

////updateUser///////
  /// Updates user profile with optional avatar
  static Future<User> updateUser({
    required String name,
    String? email,
    String? phone,
    File? avatarFile,
    required String token,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/me');

      // Since backend does NOT handle avatar, send JSON only
      var body = {
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };

      debugPrint('Sending update: $body');

      final res = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      if (res.statusCode == 200) {
        return User.fromJson(jsonDecode(res.body));
      } else {
        throw Exception('Failed to update user: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error in updateUser: $e');
      throw Exception('Error in updateUser: $e');
    }
  }

}


