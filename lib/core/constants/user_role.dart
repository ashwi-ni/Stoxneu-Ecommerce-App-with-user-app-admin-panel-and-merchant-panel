// core/constants/user_role.dart
enum UserRole {
  user,
  merchant,
  admin,
}

extension UserRoleExtension on UserRole {
  String get name => toString().split('.').last;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'merchant':
        return UserRole.merchant;
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}