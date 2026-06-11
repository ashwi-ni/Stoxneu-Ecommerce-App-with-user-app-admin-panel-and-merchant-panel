class StaticPageModel {
  final int id;
  final String title;
  final String slug;
  final String content;

  StaticPageModel({required this.id, required this.title, required this.slug, required this.content});

  factory StaticPageModel.fromJson(Map<String, dynamic> json) {
    return StaticPageModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
    );
  }
}
