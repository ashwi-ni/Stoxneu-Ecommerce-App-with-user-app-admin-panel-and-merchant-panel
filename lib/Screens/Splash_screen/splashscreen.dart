import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/user_role.dart';
import '../Auth/repository/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    final authRepo = context.read<AuthRepository>();
    final onboardingDone = await authRepo.getOnboardingDone();

    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 2));

    if (!onboardingDone) {
      context.go('/onboarding');
      return;
    }

    // 1. Check if token exists and restore role
    final isLoggedIn = await authRepo.autoLogin();

    if (!mounted) return;

    if (isLoggedIn) {
      final role = authRepo.currentRole;

      if (role == UserRole.merchant) {
        // 🔥 2. FOR MERCHANTS: Fetch KYC Status before navigating
        await authRepo.loadMerchantStatus();

        if (!mounted) return;

        // 🔥 3. Navigate Merchant based on their specific status
        if (authRepo.hasShop == false) {
          context.go('/shop-setup');
        } else if (authRepo.kycStatus == 'pending') {
          context.go('/kyc-pending');
        } else if (authRepo.kycStatus == 'approved') {
          context.go('/merchant-dashboard');
        } else {
          context.go('/kyc'); // Default: not_submitted
        }
      } else if (role == UserRole.user) {
        // 4. FOR REGULAR USERS: Just go to main
        context.go('/main');
      } else if (role == UserRole.admin) {
        context.go('/admin-dashboard');
      } else {
        context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }



  // String _getNextRoute(AuthRepository authRepo) {
  //   // Wait until data loads
  //   if (authRepo.hasShop == null || authRepo.kycStatus == null) return '/';
  //
  //   if (!authRepo.isLoggedIn) return '/login';
  //
  //   // Merchant flow
  //   if (authRepo.hasShop == false) return '/shop-setup';
  //   if (authRepo.kycStatus == 'not_submitted') return '/kyc';
  //   if (authRepo.kycStatus == 'pending') return '/kyc-pending';
  //   if (authRepo.kycStatus == 'approved') return '/merchant-dashboard';
  //
  //   // Default fallback
  //   return '/login';
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 250,
          child: Image.asset('assets/images/brandlogo.png'),
        ),
      ),
    );
  }
}