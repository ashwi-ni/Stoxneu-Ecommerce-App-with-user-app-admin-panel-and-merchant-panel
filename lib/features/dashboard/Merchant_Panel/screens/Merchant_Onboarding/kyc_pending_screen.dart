import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import 'OnboardingLayout.dart';

class KycPendingScreen extends StatefulWidget {
  const KycPendingScreen({super.key});

  @override
  State<KycPendingScreen> createState() => _KycPendingScreenState();
}

class _KycPendingScreenState extends State<KycPendingScreen> {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Start polling every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Critical: Stop the timer when screen is closed
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return; // Prevent multiple simultaneous calls

    setState(() => _isChecking = true);
    try {
      final repo = context.read<AuthRepository>();
      final status = await repo.refreshUserStatus();

      if (status == 'approved' && mounted) {
        _timer?.cancel(); // Stop polling once approved
        context.go('/dashboard'); // Auto-redirect to dashboard
      }
    } catch (e) {
      debugPrint("Status check failed: $e");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: 2,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_bottom, size: 80),
            const SizedBox(height: 20),
            const Text("KYC Under Review"),
            const SizedBox(height: 20),

            if (_isChecking)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: _checkStatus,
                child: const Text("Check Status"),
              ),
          ],
        ),
      ),
    );
  }
}
