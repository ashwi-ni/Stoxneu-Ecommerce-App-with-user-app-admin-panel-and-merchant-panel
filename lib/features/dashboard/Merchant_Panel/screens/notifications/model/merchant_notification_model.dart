class MerchantNotificationModel {
  final int id;
  final int merchantId;
  final String title;
  final String body;
  final String type;
  final String? orderId;
  final bool isRead;
  final String createdAt;

  MerchantNotificationModel({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory MerchantNotificationModel.fromJson(Map<String, dynamic> json) {
    return MerchantNotificationModel(
      id: json['id'],
      merchantId: json['merchant_id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      orderId: json['order_id']?.toString(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }

  MerchantNotificationModel copyWith({
    int? id,
    int? merchantId,
    String? title,
    String? body,
    String? type,
    String? orderId,
    bool? isRead,
    String? createdAt,
  }) {
    return MerchantNotificationModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}