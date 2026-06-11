import '../../../../config/api_config.dart';

class RefundRequest {
  final int id;
  final int orderId;
  final int merchantId;
  final double amount;
  final String reason;
  final String status;
  final String productName;
  final String imageUrl;
  final int quantity;
  final String shopName;
  final String vendorEmail;
  final String vendorPhone;

  RefundRequest(
     {
    required this.id,
    required this.orderId,
    required this.merchantId,
    required this.amount,
    required this.reason,
    required this.status,
       required this.productName,
       required this.imageUrl,
       required this.quantity,
       required this.shopName,
       required this.vendorEmail,
       required this.vendorPhone,
     });


  String get fullImageUrl {
    return imageUrl.startsWith('http')
        ? imageUrl
        : "${ApiConfig.baseUrl}$imageUrl";
  }

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Helper to safely convert to int
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }


    return RefundRequest(
      id: toInt(json['refund_id'] ?? json['id']),
      orderId: toInt(json['numeric_order_id'] ?? json['order_id']), // matches server
      merchantId: toInt(json['merchant_id']),
      amount: toDouble(json['amount']),
      reason: json['reason']?.toString() ?? "",
      status: json['status']?.toString() ?? "pending",
      productName: json['product_name']?.toString() ?? "Unknown Product",
      imageUrl: json['image_url']?.toString() ?? "",
      quantity: toInt(json['quantity']),
      shopName: json['shop_name']?.toString() ?? "Unknown Shop",
      vendorPhone: json['vendor_phone']?.toString() ?? "N/A",
      vendorEmail: json['vendor_email']?.toString() ?? "N/A",
    );
  }
}



