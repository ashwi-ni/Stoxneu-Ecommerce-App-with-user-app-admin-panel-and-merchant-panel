import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import 'OnboardingLayout.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final pan = TextEditingController();
  final aadhaar = TextEditingController();
  final account = TextEditingController();
  final ifsc = TextEditingController();
  final accountHolder = TextEditingController();

  Uint8List? _panBytes;
  Uint8List? _aadhaarBytes;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Pick PAN image
  Future<void> pickPanImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _panBytes = bytes);
    }
  }

  // Pick Aadhaar image
  Future<void> pickAadhaarImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _aadhaarBytes = bytes);
    }
  }

  // Submit KYC
// In KycScreen.dart
  Future<void> submitKyc() async {
    // 1. Validate fields and images first
    if (pan.text.isEmpty || aadhaar.text.isEmpty || _panBytes == null || _aadhaarBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload all images")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Grab the repo reference before any 'await'
    final authRepo = context.read<AuthRepository>();

    try {
      await authRepo.saveKycData(
        pan: pan.text.trim(),
        aadhaar: aadhaar.text.trim(),
        accountNumber: account.text.trim(),
        ifsc: ifsc.text.trim(),
        accountHolder: accountHolder.text.trim(),
        panImageBytes: _panBytes!,
        aadhaarImageBytes: _aadhaarBytes!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("KYC Submitted Successfully")),
        );
        context.go('/kyc-pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: 1,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: ListView(
          children: [
            const Text(
              "KYC Verification",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _input("PAN Number", pan),
            _input("Aadhaar Number", aadhaar),
            _input("Account Number", account),
            _input("IFSC Code", ifsc),
            _input("Account Holder Name", accountHolder),
            const SizedBox(height: 20),
            _imagePicker(
              label: "Upload PAN Card",
              onTap: pickPanImage,
              imageBytes: _panBytes,
            ),
            const SizedBox(height: 20),
            _imagePicker(
              label: "Upload Aadhaar Card",
              onTap: pickAadhaarImage,
              imageBytes: _aadhaarBytes,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : submitKyc,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit KYC"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker({
    required String label,
    required VoidCallback onTap,
    required Uint8List? imageBytes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageBytes != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text("Tap to upload"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}