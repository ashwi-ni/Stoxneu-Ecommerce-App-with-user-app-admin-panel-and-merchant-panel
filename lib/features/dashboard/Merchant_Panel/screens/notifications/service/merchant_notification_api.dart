import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../../../config/api_config.dart';
import '../../../../../../core/network/api_client.dart';
import '../model/merchant_notification_model.dart';

class MerchantNotificationApi {

final String baseUrl = ApiConfig.baseUrl;

  Future<List<MerchantNotificationModel>>
  fetchNotifications() async {

    final response = await ApiClient.get(
      Uri.parse("$baseUrl/merchant/notifications"),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {

      final List data = jsonDecode(response.body);

      return data.map((e) {

        return MerchantNotificationModel
            .fromJson(e);

      }).toList();
    }

    throw Exception("Failed to fetch notifications");
  }

  // =========================
  // MARK AS READ (FIXED)
  // =========================
  Future<void> markAsRead(int id) async {
    final token = await ApiClient.getToken(); // or your storage method

    final res = await http.put(
      Uri.parse("$baseUrl/merchant/notifications/$id/read"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",   // ✅ REQUIRED
      },
    );

    print("MARK READ STATUS: ${res.statusCode}");
    print("MARK READ BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Failed to mark as read");
    }
  }
  // =========================
  // DELETE (FIXED)
  // =========================
  Future<void> deleteNotification(int id) async {
    final token = await FlutterSecureStorage().read(key: 'jwt');

    final res = await http.delete(
      Uri.parse("$baseUrl/merchant/notifications/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception("Failed to delete notification");
    }
  }
  Future<int> fetchUnreadCount() async {

    final response = await ApiClient.get(
      Uri.parse("$baseUrl/merchant/notifications/unread-count"),
    );

    print("UNREAD STATUS: ${response.statusCode}");
    print("UNREAD BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return data['count'] ?? 0;
    }

    return 0;
  }
}