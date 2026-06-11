import '../../../config/api_config.dart';

class Product {
  final int id;
  final int? categoryId;
  final int? subCategoryId;
  final String sku;
  final String name;
  final String imageUrl;
  final double price;       // original price
  final double mrp;
  final int? flashPercentage;
  final double? dealPrice;  // ✅ flash_price
  final DateTime? flashStartTime;
  final DateTime? flashEndTime;
  final String? description;

  // --- NEW FIELDS ---
  int isActive;
  final String requestStatus;
  final int stockQuantity;
  final int lowStockThreshold;

  Product({
    required this.id,
    this.subCategoryId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.mrp,
    this.flashPercentage,
    this.flashStartTime,
    this.flashEndTime,
    this.description,
    this.dealPrice,
    this.categoryId,
    required this.sku,
    this.isActive = 0,
    this.requestStatus = 'pending',
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
  });

  // ✅ FULL IMAGE URL
  String get fullImageUrl {
    return imageUrl.startsWith('http')
        ? imageUrl
        : "${ApiConfig.baseUrl}$imageUrl";
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    double toDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    return Product(
      id: toInt(json['id'] ?? json['product_id']),
      sku: json['sku']?.toString() ?? "",
      name: json['name']?.toString() ?? "",
      description: json['description']?.toString(),

      // ✅ IMPORTANT FIX
      price: toDouble(json['price'] ?? json['original_price']),
      mrp: toDouble(json['mrp'] ?? json['price']),

      // ✅ FLASH DEAL SUPPORT
      dealPrice: json['flash_price'] != null
          ? toDouble(json['flash_price'])
          : (json['deal_price'] != null ? toDouble(json['deal_price']) : null),

      flashPercentage: json['flash_percentage'] != null
          ? toInt(json['flash_percentage'])
          : null,

      flashStartTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString())
          : null,

      flashEndTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString())
          : null,

      // ✅ IMAGE FIX
      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          "",

      subCategoryId: json['sub_category_id'] != null
          ? toInt(json['sub_category_id'])
          : null,

      categoryId: json['category_id'] != null
          ? toInt(json['category_id'])
          : null,

      // --- EXTRA FIELDS ---
      isActive: toInt(json['is_active']),
      requestStatus: json['request_status']?.toString() ?? 'pending',
      stockQuantity: toInt(json['stock_quantity']),
      lowStockThreshold:
      toInt(json['low_stock_threshold'], defaultValue: 5),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sub_category_id': subCategoryId,
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'image_url': imageUrl,
      'price': price,
      'mrp': mrp,
      'flash_percentage': flashPercentage,
      'deal_price': dealPrice,
      'start_time': flashStartTime?.toIso8601String(),
      'end_time': flashEndTime?.toIso8601String(),
      'description': description,
      'is_active': isActive,
      'request_status': requestStatus,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  // ✅ FLASH DEAL ACTIVE CHECK
  bool get isFlashDealActive {
    final now = DateTime.now();

    // if API already gives flash_price → treat as active
    if (dealPrice != null && dealPrice! > 0) return true;

    if (flashStartTime == null || flashEndTime == null) return false;

    return now.isAfter(flashStartTime!) &&
        now.isBefore(flashEndTime!);
  }

  // ✅ FINAL PRICE (MOST IMPORTANT)
  double get currentPrice {
    if (dealPrice != null && dealPrice! > 0) {
      return dealPrice!;
    }

    if (isFlashDealActive && flashPercentage != null) {
      return price * (1 - flashPercentage! / 100);
    }

    return price;
  }

  // ✅ DISCOUNT %
  int get discountPercentage {
    if (flashPercentage != null) {
      return flashPercentage!;
    }

    if (mrp > currentPrice) {
      return ((mrp - currentPrice) / mrp * 100).round();
    }

    return 0;
  }
}