import'package:flutter/material.dart';
import 'package:stoxneu/Screens/Profile_Screen/model/user_model.dart';
class UserInfoCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserInfoCard({
  super.key,
  required this.user,
  required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = user.phone ?? user.email ?? "Tap to complete profile";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
            user.avatar != null ? NetworkImage(user.avatar!) : null,
            child: user.avatar == null
                ? const Icon(Icons.person, size: 36, color: Colors.white)
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
