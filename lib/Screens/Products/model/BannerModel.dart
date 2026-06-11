import '../../../config/api_config.dart';

class BannerModel {
  final int id;
  final String imageUrl;
  final String createdAt;

  // These fields are NOT in your DB yet, so we give them default values
  String type;
  String link;
  bool isPublished;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    this.type = "Main Section Banner", // Default mock value
    this.link = "/home",              // Default mock value
    this.isPublished = true,          // Default mock value
  });

  String get fullImageUrl {
    if (imageUrl.isEmpty) return "";

    // If already full URL
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    // Remove extra slash if present
    String cleanPath =
    imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

    // Join properly
    return "${ApiConfig.baseUrl}/$cleanPath";
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? "",
      createdAt: json['created_at'] ?? "",
      // If these don't exist in API, they will use the defaults above
      type: json['type'] ?? "Main Section Banner",
      link: json['link'] ?? "/home",
      isPublished: json['is_published'] == 1 || json['is_published'] == true,
    );
  }
}
