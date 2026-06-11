import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:stoxneu/Screens/Profile_Screen/HelpSupportScreen.dart';

import '../Address/ProfileAddressesScreen.dart';
import '../Auth/repository/auth_repository.dart';
import '../Favorite/favorite_screen.dart';
import '../MyOrder/myorder_Screen.dart';
import '../Payment/PaymentsRefundsScreen.dart';
import 'EditProfileScreen.dart';
import 'model/user_model.dart';
import 'api/user_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _userFuture;
  late final AuthRepository authRepository;
  bool _isRefreshing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe: check if AuthRepository is available
    try {
      authRepository = context.read<AuthRepository>();
    } catch (e) {
      debugPrint("AuthRepository not provided: $e");
      // Show an error screen if provider is missing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AuthRepository not found')),
        );
      });
      return;
    }
    _userFuture = _loadUser();
  }

  Future<User> _loadUser() async {
    try {
      final token = await authRepository.getToken();
      if (token == null) throw Exception("Not logged in");
      return await UserApi.fetchMe(token);
    } catch (e) {
      debugPrint("Error fetching user: $e");
      rethrow;
    }
  }

  Future<void> _refreshUser() async {
    setState(() => _isRefreshing = true);
    try {
      final user = await _loadUser();
      setState(() {
        _userFuture = Future.value(user);
      });
    } catch (e) {
      debugPrint("Failed to refresh user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to refresh profile')),
      );
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Widget _buildUserCard(User user) {
    final subtitle = user.phone ?? user.email ?? "Complete your profile";

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
            backgroundImage: user.avatar != null
                ? NetworkImage(user.avatar!)
                : null,
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
                  user.name.isNotEmpty ? user.name : "No Name",
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
            icon: _isRefreshing
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.keyboard_arrow_right),
            onPressed: _isRefreshing
                ? null
                : () async {
              final updatedUser = await Navigator.push<User>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    user: user,
                    authRepository: authRepository,
                  ),
                ),
              );

              if (updatedUser != null) {
                setState(() {
                  _userFuture = Future.value(updatedUser);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _logoutTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          "Logout",
          style: TextStyle(color: Colors.red),
        ),
        onTap: () async {
          await authRepository.logout();
          context.go('/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(title: const Text("My Account"), elevation: 0),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Failed to load profile\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("No user data available"),
            );
          }

          final user = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildUserCard(user),
              const SizedBox(height: 16),
              _ProfileTile(
                icon: Icons.shopping_bag_outlined,
                title: "My Orders",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyOrdersScreen()),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.favorite_border,
                title: "Wishlist",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishListScreen()),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                title: "Saved Addresses",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileAddressesScreen()),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.payment_outlined,
                title: "Payments & Refunds",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentsRefundsScreen()),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>  HelpSupportScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _logoutTile(),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
