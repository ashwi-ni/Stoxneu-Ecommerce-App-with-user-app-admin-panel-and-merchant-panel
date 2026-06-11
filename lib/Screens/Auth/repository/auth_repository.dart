import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stoxneu/core/constants/user_role.dart';
import '../../../config/api_config.dart';
import '../services/auth_service.dart';

class AuthRepository extends ChangeNotifier {
  final AuthApiService api;
  final FlutterSecureStorage storage;
  String? _userName;
  String? get userName => _userName;
  String? _email;
  String? get email => _email;
  String? _phone;
  String? get phone => _phone;
  String? _avatar;
  String? get avatar => _avatar;
  String? _token;
  String? get token => _token;
  bool? hasShop;
  String? kycStatus; // not_submitted | pending | approved | rejected
  String? subscriptionStatus;   // active / expired / none
  String? subscriptionPlan;     // basic / pro / premium
  DateTime? subscriptionExpiry;


  AuthRepository({
    required this.api,
    FlutterSecureStorage? storage,
  }) : storage = storage ??
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  void updateUserProfile({
    required String name,
    String? email,
    String? avatar,

  }) {
    _userName = name;
    _email = email;

    /// ✅ FIX: ensure avatar is valid string
    if (avatar != null && avatar.isNotEmpty) {
      _avatar = avatar;
    } else {
      _avatar = null;
    }

    notifyListeners();
  }

  /// EMAIL LOGIN
  Future<String> emailLogin(String email, String password) async {
    try {
      final res = await api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final token = res['token'];
      final userData = res['user'];

      if (token != null && userData != null) {
        // 1. Save Token first
        await _saveToken(token);

        // 2. Safely map values with defaults to prevent "Type Error" crashes
        this.hasShop = userData['hasShop'] ?? false;
        this.kycStatus = userData['kycStatus'] ?? 'not_submitted';
        this._userName = userData['name']?.toString() ?? "User";
        this._email = userData['email']?.toString() ?? email;

        notifyListeners();
        return token;
      } else {
        throw Exception("Invalid server response format");
      }
    } catch (e) {
      debugPrint(
          "Login Crash/Error: $e"); // 👈 This will tell you the EXACT error in console
      rethrow;
    }
  }


  /// OTP VERIFY
  Future<String> verifyOtp(String phone, String otp) async {
    final res = await api.post('/auth/otp-verify', {
      'phone': phone,
      'otp': otp,
    });

    final token = res['token'];
    if (token == null || token.isEmpty) {
      throw Exception('Token missing');
    }

    await _saveToken(token);
    return token;
  }

  /// GOOGLE LOGIN
  Future<String> googleLogin(String idToken) async {
    final res = await api.post('/auth/google-login', {
      'idToken': idToken,
    });

    final token = res['token'];
    if (token == null || token.isEmpty) {
      throw Exception('Token missing');
    }

    await _saveToken(token);
    return token;
  }

  /// SAVE TOKEN (single source of truth)
  Future<void> _saveToken(String token) async {
    _token = token;

    try {
      final decoded = JwtDecoder.decode(token);

      // 1. Extract name and email
      _userName = decoded['name'] ?? decoded['email'] ?? "User";
      _email = decoded['email'];

      // 2. 🔥 FIX THE TYPE MISMATCH HERE
      final roleString = decoded['role']?.toString() ?? 'user';
      _currentRole = UserRoleExtension.fromString(roleString);


      debugPrint("✅ Role set to: $_currentRole");
    } catch (e) {
      debugPrint("❌ Token Decode Error: $e");
      _currentRole = UserRole.user; // Default fallback
    }

    await storage.write(key: 'jwt', value: token);
    notifyListeners();
  }


  /// GET TOKEN
  Future<String?> getToken() async {
    // Read from secure storage if _token is null
    _token ??= await storage.read(key: 'jwt');

    if (_token != null) {
      try {
        final decoded = JwtDecoder.decode(_token!);

        final roleString = decoded['role'];
        if (roleString != null) {
          _currentRole = UserRoleExtension.fromString(roleString);
        }
      } catch (_) {
        // Invalid token, remove it
        await logout();
        return null;
      }
    }

    return _token;
  }

  UserRole? _currentRole;



  UserRole? get currentRole => _currentRole;

  /// LOGOUT
  Future<void> logout() async {
    _token = null;
    await storage.delete(key: 'jwt');
    notifyListeners(); // 🔥 LOGOUT NOTIFICATION
  }

  /// UPDATE PROFILE (IMPROVED)

  /// AUTH STATE
  bool get isLoggedIn => _token != null && !_isTokenExpired(_token!);


  /// JWT EXPIRY CHECK
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      final expiry =
      DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  /// AUTO LOGIN (used in main.dart)
  /// AUTO LOGIN (used in main.dart)
  Future<bool> autoLogin() async {
    final storedToken = await storage.read(key: 'jwt');

    if (storedToken == null || _isTokenExpired(storedToken)) {
      _token = null;
      return false;
    }

    _token = storedToken;
    await _saveToken(storedToken);

    if (_currentRole == UserRole.merchant) {
      // Fetch core status alongside subscription parameters sequentially
      await loadMerchantStatus();
      await loadSubscriptionStatus();
    }

    notifyListeners();
    return true;
  }

  Future<void> loadMerchantStatus() async {
    try {
      final currentToken = _token ?? await storage.read(key: 'jwt');

      if (currentToken == null) return;

      final res = await api.get(
        '/merchant/status',
        headers: {
          "Authorization": "Bearer $currentToken",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (res != null) {
        // ✅ Restore Profile
        _userName = res['name'] ?? "User";
        _email = res['email'];

        // ✅ FIXED KEYS
        hasShop = res['hasShop'] ?? false;
        kycStatus = res['kycStatus'] ?? 'not_submitted';

        debugPrint("========== MERCHANT STATUS ==========");
        debugPrint("Name: $_userName");
        debugPrint("Email: $_email");
        debugPrint("hasShop: $hasShop");
        debugPrint("kycStatus: $kycStatus");
        debugPrint("=====================================");
      }
    } catch (e) {
      debugPrint("Status Error: $e");
    } finally {
      notifyListeners();
    }
  }



  /// REGISTER
  Future<String> register(String email, String password, String role) async {
    final data = await api.post('/auth/register', {
      "email": email,
      "password": password,
      'role': role, // send role to backend

    });

    return data['token'];
  }

  /// SEND OTP
  Future<String> sendOtp(String phone) async {
    final res = await api.post('/auth/otp-send', {
      'phone': phone,
    });

    return res['message'] ?? 'OTP sent';
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  Future<bool> getOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_done') ?? false;
  }




  Future<void> saveShop({
    required String name,
    required String contact,
    required String address,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw Exception("User token not found");
    }

    // Send data to backend
    await api.post(
      '/merchant/shop',
      {
        "name": name,
        "contact": contact,
        "address": address,
      },
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    // ✅ Update repository state after successful save
    hasShop = true;
    kycStatus = 'not_submitted';
    notifyListeners();

    debugPrint(
        "Shop saved. hasShop=$hasShop, kycStatus=$kycStatus");
  }

  // AuthRepository.dart

  // Change File to Uint8List for cross-platform compatibility
  Future<void> saveKycData({
    required String pan,
    required String aadhaar,
    required String accountHolder,
    required String accountNumber,
    required String ifsc,
    required Uint8List panImageBytes,
    required Uint8List aadhaarImageBytes,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('${AuthApiService.baseUrl}/merchant/kyc');

    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['pan'] = pan;
    request.fields['aadhaar'] = aadhaar;
    request.fields['account_holder'] = accountHolder;
    request.fields['account_number'] = accountNumber;
    request.fields['ifsc'] = ifsc;

    request.files.add(http.MultipartFile.fromBytes(
        'pan_image', panImageBytes, filename: 'pan.jpg'));
    request.files.add(http.MultipartFile.fromBytes(
        'aadhaar_image', aadhaarImageBytes, filename: 'aadhaar.jpg'));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.body.startsWith('<!DOCTYPE')) {
      debugPrint("HTML Error Received: ${response.body}");
      throw Exception("Server returned an HTML error instead of JSON.");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 🔥 UPDATE STATE LOCALLY
      kycStatus = 'pending';

      // 🔥 TRIGGER ROUTER/UI REFRESH
      notifyListeners();

      debugPrint("KYC Submitted Successfully. Local status set to pending.");
    } else {
      throw Exception("KYC failed with status: ${response.statusCode}");
    }
  }

  Future<String> refreshUserStatus() async {
    try {
      final currentToken = _token ?? await storage.read(key: 'jwt');

      final response = await http.get(
        Uri.parse('${AuthApiService.baseUrl}/merchant/status'),
        headers: {
          'Authorization': 'Bearer $currentToken',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Use local variables first to avoid triggering the router mid-update
        final bool newHasShop = data['hasShop'] ?? false;
        final String newKycStatus = data['kycStatus'] ?? 'not_submitted';

        // ✅ Update class variables together
        this.hasShop = newHasShop;
        this.kycStatus = newKycStatus;

        notifyListeners(); // Now GoRouter sees the complete state
        return newKycStatus;
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Refresh Status Error: $e");
      rethrow;
    }
  }


  Future<void> fetchUserProfile() async {
    final token = await getToken();
    if (token == null) return;

    try {
      final res = await api.get(
        '/merchant/me',
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      _userName = res['name'] ?? "User";
      _email = res['email'];
      _avatar = res['avatar'];
      _phone = res['phone'];

      notifyListeners();
    } catch (e) {
      debugPrint("fetchUserProfile error: $e");
    }
  }

  // Inside your AuthRepository class
  Future<void> updateAdminProfile({
    required String name,
    required String email,
    required String phone,
    XFile? avatarXFile,
  }) async {
    try {
      final token = await getToken();

      // 🔥 Ensure the URL is EXACTLY this. No extra spaces or slashes.
      var uri = Uri.parse("${ApiConfig.baseUrl}/admin/me");

      var request = http.MultipartRequest('PUT', uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true", // Required to bypass ngrok warning page
      });

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone'] = phone;

      if (avatarXFile != null) {
        final bytes = await avatarXFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: avatarXFile.name,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // If you get HTML here, we print it to see why the router failed
      if (response.body.contains("<!DOCTYPE")) {
        debugPrint("URL HIT: $uri"); // Check this in console!
        debugPrint("SERVER ERROR HTML: ${response.body}");
        throw Exception("Server returned HTML. Check Node.js console for crashes.");
      }

      final res = jsonDecode(response.body);
      _userName = res['name'];
      _email = res['email'];
      _phone = res['phone']?.toString();
      _avatar = res['avatar'];

      notifyListeners();
    } catch (e) {
      debugPrint("Upload Error: $e");
      rethrow;
    }
  }


  Future<Map<String, dynamic>> fetchAdminProfile() async {
    final token = await getToken();
    final res = await api.get('/admin/me', headers: {"Authorization": "Bearer $token"});

    // Safety check: Backend sends rows[0], so 'res' should be a Map
    Map<String, dynamic> data;
    if (res is List && res.isNotEmpty) {
      data = res[0];
    } else if (res is Map<String, dynamic>) {
      data = res;
    } else {
      throw Exception("Invalid data format received from server");
    }

    // Sync variables
    _userName = data['name']?.toString();
    _email = data['email']?.toString();
    _phone = data['phone']?.toString();

    notifyListeners();
    return data;
  }

  Future<void> changePassword(
      {required String oldPassword, required String newPassword}) async {
    final token = await getToken();
    await api.put(
      '/auth/change-password',
      {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      headers: {"Authorization": "Bearer $token"},
    );
  }

  // Inside your AuthRepository class:
  Future<void> loadSubscriptionStatus() async {
    try {
      final token = await getToken();
      if (token == null) {
        subscriptionStatus = 'none';
        notifyListeners();
        return;
      }

      final res = await api.get(
        '/merchant/subscription-status',
        headers: {"Authorization": "Bearer $token"},
      );

      // 🔬 DEBUG PRINT: See exactly what keys your backend is sending
      debugPrint("📢 SUBSCRIPTION API RAW RESPONSE: ${res.toString()}");

      // 🧠 CHECK BOTH COMMON BACKEND CASINGS ('status' vs 'subscriptionStatus')
      subscriptionStatus = res['subscriptionStatus'] ?? res['status'] ?? 'none';
      subscriptionPlan = res['plan'] ?? 'none';

      if (res['expiry'] != null) {
        subscriptionExpiry = DateTime.tryParse(res['expiry'].toString());
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Subscription load error: $e");
      subscriptionStatus = 'none';
      notifyListeners();
    }
  }



}

