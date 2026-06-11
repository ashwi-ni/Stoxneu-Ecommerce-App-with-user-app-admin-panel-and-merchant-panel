class Merchant {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String role;

  Merchant({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    required this.role,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'],
      name: json['name'] ?? 'User',
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
    );
  }



  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "id": id,
      "phone": phone,
      "email": email,
      "avatar": avatar,
      'role':role,
    };
  }
}