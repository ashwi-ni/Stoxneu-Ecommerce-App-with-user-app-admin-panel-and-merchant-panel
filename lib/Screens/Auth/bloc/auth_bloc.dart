import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stoxneu/core/constants/user_role.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    // Email login
    // Email login
    on<EmailLoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final token = await _authRepository.emailLogin(event.email, event.password);
        final decoded = JwtDecoder.decode(token);
        final userId = decoded['id'];
        final userRoleString = decoded['role'] as String; // string from JWT
        final userRole = UserRoleExtension.fromString(userRoleString); // convert to enum

        emit(AuthSuccess(token: token, userId: userId, role: userRole));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // Email register
    // auth_bloc.dart (inside AuthBloc constructor)
    on<EmailRegisterEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        // Call the API
        await _authRepository.register(
          event.email,
          event.password,
          event.role.name,
        );

        // Emit RegistrationSuccess.
        // Because this isn't "AuthSuccess", your Router redirect won't trigger!
        emit(RegistrationSuccess());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });



// Send OTP
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authRepository.sendOtp(event.phone);
        emit(OtpSentState());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

// Verify OTP
    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final token = await _authRepository.verifyOtp(event.phone, event.otp);
        final decoded = JwtDecoder.decode(token);
        final userId = decoded['id'];
        final userRole = decoded['role'];
        emit(AuthSuccess(token: token, userId: userId, role: userRole));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });


    // Google
    on<GoogleLoginEvent>((event, emit) async {
      print("[AuthBloc] GoogleLoginEvent");
      emit(AuthLoading());
      try {
        final token = await _authRepository.googleLogin(event.googleToken);
        final decoded = JwtDecoder.decode(token);
        final userId = decoded['id'];
        final userRole = decoded['role'];
        print("[AuthBloc] Google Login Success: $token");
        emit(AuthSuccess(token: token, userId: userId, role: userRole));
      } catch (e) {
        print("[AuthBloc] Google Login Error: $e");
        emit(AuthError(e.toString()));
      }
    }
    );

    // inside AuthBloc constructor
    on<AuthCheckRequested>((event, emit) async {
      final token = await _authRepository.getToken();

      if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);
        final userId = decoded['id'];
        final roleString = decoded['role'] as String; // string from JWT
        final userRole = UserRoleExtension.fromString(roleString); // convert to enum

        emit(AuthSuccess(token: token, userId: userId, role: userRole));
      } else {
        emit(AuthInitial());
      }
    });

    on<AuthLoggedOut>((event, emit) async {
      await _authRepository.logout();
      emit(AuthInitial());
    });

    // Inside AuthBloc constructor
    on<FetchUserProfile>((event, emit) async {
      emit(AuthLoading());
      try {
        // This MUST call the API and return the row from your 'users' table
        final Map<String, dynamic> data = await _authRepository.fetchAdminProfile();

        // Ensure these keys ('name', 'email', 'phone') match what you
        // used in the listener above!
        emit(ProfileLoadedState(data));
      } catch (e) {
        emit(AuthError("Failed to fetch: $e"));
      }
    });


    on<UpdateProfileRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authRepository.updateAdminProfile(
          name: event.name,
          email: event.email,
          phone: event.phone,
          // 🔥 CHANGE THIS: from 'avatarFile' to 'avatarXFile'
          avatarXFile: event.avatarXFile,
        );

        final token = await _authRepository.getToken();
        if (token != null) {
          final decoded = JwtDecoder.decode(token);
          emit(AuthSuccess(
              token: token,
              userId: decoded['id'],
              role: UserRole.admin
          ));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });


    on<ChangePasswordRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // 1. Call the repository to change the password in MySQL
        await _authRepository.changePassword(
          oldPassword: event.oldPassword,
          newPassword: event.newPassword,
        );

        // 2. Fetch current session data to satisfy the AuthSuccess state
        final token = await _authRepository.getToken();

        if (token != null) {
          final decoded = JwtDecoder.decode(token);
          final userId = decoded['id'];
          final roleString = decoded['role']?.toString() ?? 'user';
          final userRole = UserRoleExtension.fromString(roleString);

          // Now these variables are defined in this specific block
          emit(AuthSuccess(token: token, userId: userId, role: userRole));
        } else {
          emit(AuthError("Session expired. Please login again."));
        }
      } catch (e) {
        // This catches "Current password is incorrect" or network errors
        emit(AuthError(e.toString()));
      }
    });


  }
}


