import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:stoxneu/config/api_config.dart';

class AdminKycReviewScreen extends StatefulWidget {
  final Map<String, dynamic> kycData;
  const AdminKycReviewScreen({super.key, required this.kycData});

  @override
  State<AdminKycReviewScreen> createState() => _AdminKycReviewScreenState();
}

class _AdminKycReviewScreenState extends State<AdminKycReviewScreen> {
  final storage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.baseUrl;
  final Color primaryColor = const Color(0xff0055D3);
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final k = widget.kycData;
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        title: const Text("Vendor Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildVendorHeaderCard(k),
            const SizedBox(height: 24),
            _buildMainInfoGrid(k),
            const SizedBox(height: 24),
            _buildDocumentSection(k), // Keep documents below
          ],
        ),
      ),
    );
  }

  /// 1. Top Header Card (Matches Reference Image)
  Widget _buildVendorHeaderCard(Map k) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo/Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade100,
            child: Icon(Icons.storefront, size: 40, color: primaryColor),
          ),
          const SizedBox(width: 24),
          // Name and Rating info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k['shop_name'] ?? 'N/A',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Row(
                //   children: [
                //     const Icon(Icons.star, color: Colors.amber, size: 18),
                //     const SizedBox(width: 4),
                //     Text("5.0 Ratings", style: TextStyle(color: Colors.grey.shade600)),
                //     const SizedBox(width: 12),
                //     Text("1 Reviews", style: TextStyle(color: Colors.grey.shade600)),
                //   ],
                // ),
                // const SizedBox(height: 16),
                // OutlinedButton.icon(
                //   onPressed: () {},
                //   icon: const Icon(Icons.visibility, size: 16),
                //   label: const Text("View live"),
                //   style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
                // )
              ],
            ),
          ),
          // Action and Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _actionButton(k['status']),
              const SizedBox(height: 20),
              _statsBox("Total products", k['total_products']?.toString() ?? "0"),
              _statsBox("Total orders", k['total_orders']?.toString() ?? "0"),
            ],
          )
        ],
      ),
    );
  }

  /// 2. The 3-Column Info Grid
  Widget _buildMainInfoGrid(Map k) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _infoColumn("Shop Information", {
            "Shop name": k['shop_name'],
            "Phone": k['contact'],
            "Address": k['address'],
            "Status": k['status'],
          })),
          const VerticalDivider(),
          Expanded(child: _infoColumn("Vendor Information", {
            "Owner name": k['merchant_name'],
            "Email": k['email'],
            "Phone":  k['phone'],
          })),
          const VerticalDivider(),
          Expanded(child: _infoColumn("Bank Information", {
            "Bank name": "No data found",
            "Holder name": k['account_holder'],
            "Branch": "No data found",
            "A/C No": k['account_number'],
          })),
        ],
      ),
    );
  }

  /// 3. Wallet Section
  // Widget _buildWalletSection(Map k) {
  //   return Row(
  //     children: [
  //       _walletCard("Pending Withdraw", "\$0.00", Icons.account_balance_wallet_outlined),
  //       const SizedBox(width: 20),
  //       _walletCard("Total Commission Given", "\$0.00", Icons.monetization_on_outlined),
  //     ],
  //   );
  // }

  // --- HELPER WIDGETS ---

  Widget _statsBox(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade50), color: Colors.blue.shade50.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoColumn(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        ...data.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text("${e.key} :", style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
              Expanded(child: Text(e.value?.toString() ?? "Not Added", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
        )).toList(),
      ],
    );
  }

  // Widget _walletCard(String label, String amount, IconData icon) {
  //   return Expanded(
  //     child: Container(
  //       padding: const EdgeInsets.all(24),
  //       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(amount, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
  //               Text(label, style: TextStyle(color: Colors.grey.shade600)),
  //             ],
  //           ),
  //           Icon(icon, size: 40, color: Colors.orange.shade300),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _actionButton(String status) {
    final String currentStatus = status.toLowerCase();

    // 1. PENDING STATUS: Show both Approve and Reject buttons
    if (currentStatus == "pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionBtn(
            label: "Reject",
            color: Colors.red,
            isOutlined: true,
            onTap: () => _updateStatus('rejected', reason: "Invalid Documents"),
          ),
          const SizedBox(width: 12),
          _buildActionBtn(
            label: "Approve Vendor",
            color: Colors.green,
            isOutlined: false,
            onTap: () => _updateStatus('approved'),
          ),
        ],
      );
    }

    // 2. APPROVED STATUS: Show only Suspend button (in place of approved)
    if (currentStatus == "approved") {
      return _buildActionBtn(
        label: "Suspend this vendor",
        color: Colors.red,
        isOutlined: false,
        onTap: () => _updateStatus('rejected', reason: "Suspended by Admin"),
      );
    }

    // 3. REJECTED STATUS: Show Re-Approve button
    return _buildActionBtn(
      label: "Re-Approve Vendor",
      color: Colors.green,
      isOutlined: false,
      onTap: () => _updateStatus('approved'),
    );
  }

  /// Professional button builder helper
  Widget _buildActionBtn({
    required String label,
    required Color color,
    required bool isOutlined,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: isOutlined
          ? OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      )
          : ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }


  Widget _buildDocumentSection(Map k) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Identity Verification Documents",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: _docPreviewItem("PAN Card Image", k['pan_image'])),
              const SizedBox(width: 24),
              Expanded(child: _docPreviewItem("Aadhaar Card Image", k['aadhaar_image'])),
            ],
          )
        ],
      ),
    );
  }

  Widget _docPreviewItem(String title, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              "$baseUrl/uploads/$imageUrl",
              fit: BoxFit.contain,
              // Bypass ngrok warning
              headers: const {'ngrok-skip-browser-warning': 'true'},
              // 1. Placeholder while loading
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              // 2. Placeholder if image fails to load (404, 500, etc.)
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder("Image not found");
              },
            ),
          )
              : _buildImagePlaceholder("No document uploaded"),
        )
      ],
    );
  }

  // Common Placeholder Widget
  Widget _buildImagePlaceholder(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 40),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Future<void> _updateStatus(String status, {String? reason}) async {
    setState(() => isProcessing = true);
    try {
      final token = await storage.read(key: 'jwt');
      final response = await http.post(
        Uri.parse("$baseUrl/admin/kyc/update-status"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          // 🔥 CRITICAL: This bypasses the ngrok warning page
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'merchant_id': widget.kycData['merchant_id'],
          'status': status,
          'reason': reason,
        }),
      );

      debugPrint("Response Status: ${response.statusCode}");

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("KYC marked as $status"),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      } else {
        // Log the body to see what the server actually sent
        debugPrint("Server Error Body: ${response.body}");
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: Check your ngrok tunnel")),
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }


}
