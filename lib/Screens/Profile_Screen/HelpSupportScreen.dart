import 'package:flutter/material.dart';
import 'package:stoxneu/Screens/Profile_Screen/static_page_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Help & Support"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionTitle("Support"),

          _tile(
            icon: Icons.support_agent_outlined,
            title: "Customer Support",
            subtitle: "Get help with orders and issues",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaticPageScreen(
                    slug: "support",
                  ),
                ),
              );
            },
          ),

          _tile(
            icon: Icons.info_outline,
            title: "About Us",
            subtitle: "Learn more about StoxNeu",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaticPageScreen(
                    slug: "about-us",
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          _sectionTitle("Contact Us"),

          _tile(
            icon: Icons.call_outlined,
            title: "Call Support",
            subtitle: "+91 98765 43210",
            onTap: () => _launchPhone("+919876543210"),
          ),
          _tile(
            icon: Icons.email_outlined,
            title: "Email Support",
            subtitle: "support@stoxneu.com",
            onTap: () => _launchEmail("support@stoxneu.com"),
          ),
          _tile(
            icon: Icons.chat_outlined,
            title: "WhatsApp Support",
            subtitle: "Chat with us on WhatsApp",
            onTap: () => _launchWhatsApp("+919876543210"),
          ),

          const SizedBox(height: 20),
          _sectionTitle("Legal"),

          _tile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaticPageScreen(
                    slug: "privacy-policy",
                  ),
                ),
              );
            },
          ),
          _tile(
            icon: Icons.description_outlined,
            title: "Terms & Conditions",
            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaticPageScreen(
                    slug: "terms",
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  // ---------- Helpers ----------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse("mailto:$email");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final uri = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}