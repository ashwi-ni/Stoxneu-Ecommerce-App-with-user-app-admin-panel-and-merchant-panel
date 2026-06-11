import '../../../core/constants/user_role.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSentState extends AuthState {}
class AuthSuccess extends AuthState {
  final String token;
  final int userId;
  final UserRole role;


  AuthSuccess({required this.token,
    required this.userId, required this.role,

  });
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class EmailRegisterState extends AuthState {
  final String email;
  final String password;
  final UserRole role; // enum

  EmailRegisterState  (this.email, this.password, this.role);

}
class RegistrationSuccess extends AuthState {}

class ProfileLoadedState extends AuthState { // Added
  final Map<String, dynamic> userData;
  ProfileLoadedState(this.userData);
}