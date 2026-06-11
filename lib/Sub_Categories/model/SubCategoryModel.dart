import '../../config/api_config.dart';

class SubCategoryModel {
  final int id;
  final int categoryId;
  final String name;
  final String iconUrl;
  final String? mainCategoryName; // From JOIN
  final int priority;
  
  SubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.iconUrl,
    this.mainCategoryName,
    this.priority = 1,
  });

  String get fullIconUrl{
    return iconUrl.startsWith('http')
        ? iconUrl
        : "${ApiConfig.baseUrl}$iconUrl";
  }
  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'] as int,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      mainCategoryName: json['main_category_name'] ?? "Unknown",
      priority: json['priority'] ?? 1,
    );
  }
}
