import '../../../config/api_config.dart';

class UserNotificationModel {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final bool isRead;
  final String createdAt;
  final String type;
  final String screen;
  final int? refId;

  UserNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    required this.type,
    required this.screen,
    this.refId,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['image_url'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
      type: json['type'] ?? '',
      screen: json['screen'] ?? '',
      refId: json['refId'],
    );
  }
  UserNotificationModel copyWith({
    bool? isRead,
  }) {

    return UserNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      screen: screen,
    );
  }
  // ✅ FIX IMAGE URL
  String get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return '';
    }

    return imageUrl!.startsWith('http')
        ? imageUrl!.replaceFirst("http://", "https://")
        : "${ApiConfig.baseUrl}$imageUrl";
  }
}