import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';


class OnboardingLayout extends StatelessWidget {
  final Widget child;
  final int currentStep; // 0=shop, 1=kyc, 2=done

  const OnboardingLayout({
  super.key,
  required this.child,
  required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // 🔹 SIDEBAR (COMMON)
          Container(
            width: 260,
            padding: const EdgeInsets.all(20),
            color: Colors.grey.shade100,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 USER HEADER
                  Consumer<AuthRepository>(
                    builder: (context, auth, _) {
                      final userName = auth.userName ?? "User";
                      final email = auth.email ?? "";
                      final avatar = auth.avatar;

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage:
                            (avatar != null && avatar.isNotEmpty)
                                ? NetworkImage(avatar)
                                : null,
                            child: (avatar == null || avatar.isEmpty)
                                ? Text(userName[0].toUpperCase())
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName,
                                    overflow: TextOverflow.ellipsis),
                                if (email.isNotEmpty)
                                  Text(email,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Smaller padding
                              minimumSize: const Size(0, 0), // Allows it to shrink to content size
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes extra touch target margin
                            ),
                            onPressed: () async {
                              await context.read<AuthRepository>().logout();
                              if (context.mounted) context.go('/login');
                            },
                            child: const Text(
                              "Logout",
                              style: TextStyle(fontSize: 12), // Smaller text
                            ),
                          )

                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  const Divider(),

                  // 🔹 STEPS
                  _step("Shop Details", 0),
                  _step("KYC Verification", 1),
                  _step("Complete", 2),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // 🔹 RIGHT SIDE (DYNAMIC SCREEN)
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _step(String title, int stepIndex) {
    final isActive = stepIndex == currentStep;
    final isDone = stepIndex < currentStep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: isDone
                ? Colors.green
                : isActive
                ? Colors.blue
                : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}