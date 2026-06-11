class User {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String role;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'User',
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
    );
  }
}

// Map<String, dynamic> toJson() => {
//     'id': id,
//     'email': email,
//     'password': password,
//     'phone': phone,
//     'google_id': googleId,
//     'name': name,
//     'avatar': avatar,
//     'role': role,
//   };
//}
