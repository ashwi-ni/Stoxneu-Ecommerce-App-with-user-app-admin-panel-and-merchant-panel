import 'package:jwt_decoder/jwt_decoder.dart';

class AuthResponse {
  final String token;
 // final UserRole role;
  final int userId;

  AuthResponse({
    required this.token,
  //  required this.role,
    required this.userId,
  });

  factory AuthResponse.fromToken(String token) {
    final decoded = JwtDecoder.decode(token);
    return AuthResponse(
      token: token,
      userId: decoded['id'],
    //  role: UserRoleExtension.fromString(decoded['role']),
    );
  }
}