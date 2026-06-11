import 'dart:convert';

import '../../../config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/user_notification_model.dart';

class UserNotificationApi {

  // =====================================================
  // FETCH USER NOTIFICATIONS
  // =====================================================
  Future<List<UserNotificationModel>>
  fetchNotifications() async {

    try {

      final response = await ApiClient.get(

        Uri.parse(
          '${ApiConfig.baseUrl}/user/notifications',
        ),
      );

      print(
        "NOTIFICATION STATUS CODE => ${response.statusCode}",
      );

      print(
        "NOTIFICATION RESPONSE => ${response.body}",
      );

      if (response.statusCode == 200) {

        final decoded =
        jsonDecode(response.body);

        // ==========================================
        // HANDLE DIFFERENT RESPONSE STRUCTURES
        // ==========================================
        final List<dynamic> data =

        decoded is List

            ? decoded

            : decoded['data'] ?? [];

        return data.map((json) {

          return UserNotificationModel.fromJson(
            json,
          );

        }).toList();
      }

      throw Exception(
        "Failed to load notifications",
      );

    } catch (e) {

      print(
        "FETCH NOTIFICATION ERROR => $e",
      );

      rethrow;
    }
  }
  Future<void> deleteNotification(int id) async {

    final response = await ApiClient.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/user/notifications/$id',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete notification");
    }
  }
  Future<void> markAsRead(int id) async {

    final response = await ApiClient.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/user/notifications/read',
      ),
      body: jsonEncode({
        "id": id
      }),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to mark notification as read");
    }
  }
}