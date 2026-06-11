import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../config/api_config.dart';

class AdminCommissionScreen extends StatefulWidget {
  const AdminCommissionScreen({super.key});

  @override
  State<AdminCommissionScreen> createState() => _AdminCommissionScreenState();
}

class _AdminCommissionScreenState extends State<AdminCommissionScreen> {
  final storage = const FlutterSecureStorage();
  final globalController = TextEditingController();
  List<dynamic> vendors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    try {
      final token = await storage.read(key: 'jwt');
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/commission/settings"),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true'
        },
      );

      // 🔥 CHECK THESE PRINTS IN YOUR CONSOLE
      debugPrint("Commission API Status: ${response.statusCode}");
      debugPrint("Commission API Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          // Explicitly cast to List to avoid type errors
          globalController.text = data['global_commission']?.toString() ?? "0";
          vendors = List.from(data['vendors'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }


  Future<void> updateGlobal() async {
    try {
      final token = await storage.read(key: 'jwt');
      final response = await http.post(
        // 🔥 ADDED THE PATH AT THE END
        Uri.parse("${ApiConfig.baseUrl}/admin/commission/global"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: jsonEncode({'rate': globalController.text}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Global Rate Updated Successfully"))
        );
        fetchSettings();
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Commission Setup", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            // 1. GLOBAL COMMISSION CARD
            _card(
              title: "Global Commission Percentage (%)",
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: globalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: "%"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(onPressed: updateGlobal, child: const Text("Save Default")),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. VENDOR OVERRIDES
            const Text("Vendor Specific Overrides", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Store Name")),
                  DataColumn(label: Text("Custom Rate")),
                  DataColumn(label: Text("Action")),
                ],
                rows: vendors.map((v) => DataRow(cells: [
                  // 🔥 FIX: Changed from 'shop_name' to 'name' to match your table desc
                  DataCell(Text(v['name'] ?? "No Name")),

                  DataCell(Text("${v['commission_rate'] ?? 'Using Global'}%")),

                  DataCell(IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(v),
                  )),
                ])).toList(),

              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }

  void _showEditDialog(dynamic vendor) {
    // 🔥 Use vendor['name'] here
    final name = vendor['name'] ?? "Merchant";
    final rateController = TextEditingController(text: vendor['commission_rate']?.toString() ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit rate for $name"),
        content: TextField(
            controller: rateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Percentage (%)")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                final token = await storage.read(key: 'jwt');
                final res = await http.post(
                  Uri.parse("${ApiConfig.baseUrl}/admin/commission/vendor"),
                  headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
                  body: jsonEncode({'merchant_id': vendor['merchant_id'], 'rate': rateController.text}),
                );
                if (res.statusCode == 200) {
                  Navigator.pop(ctx);
                  fetchSettings();
                }
              },
              child: const Text("Update")
          ),
        ],
      ),
    );
  }

}
