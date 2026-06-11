import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../config/api_config.dart';

class AdminPayoutApprovalScreen extends StatefulWidget {
  const AdminPayoutApprovalScreen({super.key});

  @override
  State<AdminPayoutApprovalScreen> createState() => _AdminPayoutApprovalScreenState();
}

class _AdminPayoutApprovalScreenState extends State<AdminPayoutApprovalScreen> {
  final storage = const FlutterSecureStorage();
  List<dynamic> requests = [];
  bool isLoading = true;
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final token = await storage.read(key: 'jwt');
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/payouts/pending"),
        headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        setState(() {
          requests = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showActionDialog(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Withdrawal Request from ${req['shop_name']}"),
        content: Text("Amount: ₹${req['amount']}\nStatus: ${req['status']}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { Navigator.pop(ctx); _handleAction(req, 'rejected'); },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () { Navigator.pop(ctx); _handleAction(req, 'approved'); },
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(Map<String, dynamic> req, String status) async {
    try {
      final token = await storage.read(key: 'jwt');
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/admin/payouts/update-status"),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({
          'payout_id': req['id'],
          'merchant_id': req['merchant_id'],
          'amount': req['amount'],
          'status': status
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payout $status")));
        fetchRequests();
      } else {
        debugPrint("Server Response: ${response.body}");
      }
    } catch (e) { debugPrint("App Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F5F9),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Withdraw", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTableCard(),
          ],
        ),
      ),
    );
  }

  // Replace your _buildTableCard method with this one
  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text("Withdraw Request Table (${requests.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                // ... Search bar code ...
              ],
            ),
          ),
          LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                      const Color(0xffF8F9FB)),
                  columns: const [
                    DataColumn(label: Text("SL")),
                    DataColumn(label: Text("Amount")),
                    DataColumn(label: Text("Shop")),
                    DataColumn(label: Text("Request Time")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: requests
                      .asMap()
                      .entries
                      .map((entry) {
                    int index = entry.key + 1;
                    var r = entry.value;

                    // 🔥 SAFE DATE PARSING
                    String formattedDate = "N/A";
                    try {
                      if (r['requested_at'] != null) {
                        formattedDate = DateFormat('yyyy-MM-dd HH:mm')
                            .format(
                            DateTime.parse(r['requested_at'].toString()));
                      }
                    } catch (e) {
                      formattedDate = "Invalid Date";
                    }

                    return DataRow(cells: [
                      DataCell(Text(index.toString())),
                      // 🔥 SAFE AMOUNT
                      DataCell(Text("₹${r['amount'] ?? '0.00'}",
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      // 🔥 SAFE SHOP NAME
                      DataCell(
                          Text(r['shop_name']?.toString() ?? "Unknown Shop")),
                      DataCell(Text(formattedDate)),
                      // 🔥 SAFE STATUS BADGE
                      DataCell(
                          _statusBadge(r['status']?.toString() ?? "pending")),
                      DataCell(
                          IconButton(
                              icon: const Icon(
                                  Icons.visibility, color: Colors.blue,
                                  size: 20),
                              onPressed: () => _showActionDialog(r)
                          )),
                    ]);
                  }).toList(),
                ),
              ),
            );
          }
          ),
        ],
      ),
    );
  }

// 🔥 SAFE STATUS BADGE HELPER
  Widget _statusBadge(String status) {
    status = status.toLowerCase(); // Ensure it's lowercase for comparison
    Color color = status == 'pending' ? Colors.blue : status == 'completed' ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(
          status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)
      ),
    );
  }


}
