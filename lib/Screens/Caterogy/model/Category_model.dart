import '../../../config/api_config.dart';

class CategoryModel {
  final int id;
  final String name;
  final String iconUrl;
  final DateTime? createdAt;
  final int priority;
  bool homeStatus;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    this.createdAt,
    this.priority = 1,
    this.homeStatus = false,
  });
// Inside your CategoryModel class
  String get fullIconUrl{
    return iconUrl.startsWith('http')
        ? iconUrl
        : "${ApiConfig.baseUrl}$iconUrl";
  }

// Category_model.dart
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    print(json);
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '', // Check if backend sends 'name' or 'category_name'
      iconUrl: json['icon_url'] ?? '',
      priority: int.tryParse(json['priority']?.toString() ?? '1') ?? 1, // Ensure this is mapped
      homeStatus:
      json['home_status'].toString() == "1",


    );
  }
}
