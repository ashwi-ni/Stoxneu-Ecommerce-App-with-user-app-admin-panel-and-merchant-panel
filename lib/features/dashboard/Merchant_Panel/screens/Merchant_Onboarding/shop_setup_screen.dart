import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import 'OnboardingLayout.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final name = TextEditingController();
  final contact = TextEditingController();
  final address = TextEditingController();

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter Shop Details",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _input("Shop Name", name, "Enter shop name"),
            _input("Contact Number", contact, "Enter contact number"),
            _input("Shop Address", address, "Enter shop address"),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitData,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save & Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Input Field
  Widget _input(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Submit Logic
  Future<void> _submitData() async {
    if (name.text.isEmpty || contact.text.isEmpty || address.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = context.read<AuthRepository>();

      // Save shop and update repo automatically
      await repo.saveShop(
        name: name.text.trim(),
        contact: contact.text.trim(),
        address: address.text.trim(),
      );

      // Navigate to KYC
      if (mounted) context.go('/kyc');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}