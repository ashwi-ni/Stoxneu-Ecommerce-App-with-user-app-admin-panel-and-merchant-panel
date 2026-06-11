import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:stoxneu/core/constants/user_role.dart';

abstract class AuthEvent {}

class EmailLoginEvent extends AuthEvent {
  final String email;
  final String password;
  EmailLoginEvent(this.email, this.password);
}

class SendOtpEvent extends AuthEvent {
  final String phone;
  SendOtpEvent(this.phone);
}

class VerifyOtpEvent extends AuthEvent {
  final String phone;
  final String otp;
  VerifyOtpEvent(this.phone, this.otp);
}

class GoogleLoginEvent extends AuthEvent {
  final String googleToken;
  GoogleLoginEvent(this.googleToken);
}


class AuthSuccessEvent extends AuthEvent {
  final String token;
  AuthSuccessEvent(this.token);
}

class AuthErrorEvent extends AuthEvent {
  final String message;
  AuthErrorEvent(this.message);
}
class EmailRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final UserRole role;

  EmailRegisterEvent(this.email, this.password,  this.role, );
}

//.........................................................//
class AuthCheckRequested extends AuthEvent {}

class AuthLoggedIn extends AuthEvent {
  final String token;
  AuthLoggedIn(this.token);
}

class AuthLoggedOut extends AuthEvent {}

class FetchUserProfile extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String name;
  final String phone;
  final String email;
  final XFile? avatarXFile;
  UpdateProfileRequested({required this.name, required this.phone, required this.email, this.avatarXFile});
}

class ChangePasswordRequested extends AuthEvent {
  final String newPassword;
  final  String oldPassword;
  ChangePasswordRequested({required this.newPassword, required this.oldPassword});
}
