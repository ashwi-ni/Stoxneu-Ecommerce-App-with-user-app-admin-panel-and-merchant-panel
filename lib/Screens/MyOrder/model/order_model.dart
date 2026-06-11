import '../../../config/api_config.dart';

class Order {
  final int? id;
  final int? userId;
  final int? merchantId;
  final int? productId;
  final String orderId;
  final DateTime date;
  final double totalAmount;
  final List<OrderItem> items;
  final String status;
  final String address;
  final String paymentMethod; // ONLINE / COD
  final String paymentStatus; // PAID / PENDING
  String refundStatus;        // NONE / REQUESTED / COMPLETED
  final double refundAmount;
  final String? paymentId;

  Order({
     this.id,
     this.userId,
    this.merchantId,
     this.productId,
    required this.orderId,
    required this.date,
    required this.totalAmount,
    required this.items,
    required this.status,
    required this.address,
    required this.paymentMethod,
    required this.paymentStatus,
    this.refundStatus = "NONE",
    this.refundAmount = 0,
    this.paymentId,



  });
  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] ?? 0, // ✅ NULL SAFE
    userId: json['user_id'] ?? 0, // ✅ FIXED HERE
    merchantId: json['merchant_id'] ?? 0,
    productId: json['product_id'] ?? 0,
    orderId: json['orderId'] ?? json['order_id'] ?? '',
    date: DateTime.parse(json['created_at'] ?? json['date']),
    totalAmount: double.tryParse(
        json['totalAmount']?.toString() ??
            json['total_amount']?.toString() ??
            '0') ??
        0.0,
    status: json['status'] == "placed"
        ? "Pending"
        : json['status'],
    paymentMethod: json['paymentMethod'] ?? json['payment_method'] ?? '',
    paymentStatus: json['paymentStatus'] ?? json['payment_status'] ?? '',
    refundStatus: json['refundStatus'] ?? json['refund_status'] ?? 'NONE',
    address: json['address'] ?? '',
    items: (json['items'] as List?)
        ?.map((e) => OrderItem.fromJson(e))
        .toList() ??
        [],

  );

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'date': date.toIso8601String(),
    'totalAmount': totalAmount,
    'status': status,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'refundStatus': refundStatus,
    'address': address,
    'merchant_id': merchantId,
    'items': items.map((e) => e.toJson()).toList(),
  };
}
class OrderItem {
  final int productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  String get fullImageUrl {
    return imageUrl.startsWith('http')
        ? imageUrl
        : "${ApiConfig.baseUrl}$imageUrl";
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['product_id'] ?? 0,
    name: json['name'] ?? '',
    imageUrl: json['image_url'] ?? '',
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    quantity: json['quantity'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'imageUrl': imageUrl,
    'price': price,
    'quantity': quantity,
  };
}
