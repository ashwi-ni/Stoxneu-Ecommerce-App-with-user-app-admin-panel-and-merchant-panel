import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:stoxneu/config/api_config.dart';
import 'package:stoxneu/features/dashboard/Merchant_Panel/model/refund_model.dart';

import '../../../../Screens/MyOrder/model/order_model.dart';
import '../orders/adminorder_detail_screen.dart';

class AdminRefundDetailScreen extends StatefulWidget {
  final RefundRequest request;
  const AdminRefundDetailScreen({super.key, required this.request});



  @override
  State<AdminRefundDetailScreen> createState() => _AdminRefundDetailScreenState();
}

class _AdminRefundDetailScreenState extends State<AdminRefundDetailScreen> {
  final storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  final String baseUrl = ApiConfig.baseUrl;
  List<dynamic> statusLogs = [];

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  // 1. FETCH LOGS
  Future<void> fetchLogs() async {
    print("📡 Fetching Logs for ID: ${widget.request.id}");
    try {
      String? token = await storage.read(key: 'jwt');
      final response = await http.get(
        Uri.parse("$baseUrl/merchant/refunds/${widget.request.id}/logs"),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          statusLogs = data['data'] ?? [];
        });
      }
    } catch (e) {
      print("Error fetching logs: $e");
    }
  }

  Future<void> _updateStatus(String endpointAction, {String note = ""}) async {
    // 1. Construct the URL into a variable so we can print it
    final String fullUrl = "$baseUrl/merchant/refunds/${widget.request.id}/$endpointAction";

    // 2. Debug Prints
    print("🌍 FULL URL: $fullUrl");
    print("📦 SENDING NOTE: $note");

    try {
      String? token = await storage.read(key: 'jwt');
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'note': note}),
      );

      // 3. Print the server response status
      print("📡 SERVER RESPONSE CODE: ${response.statusCode}");
      print("📡 SERVER RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Success!"), backgroundColor: Colors.green),
        );
        fetchLogs();
      } else {
        // This will tell you if it's 404 (URL wrong) or 401 (Token issue)
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ FLUTTER ERROR: $e");
      _showError("Error: $e");
    }
  }

  void _showReasonDialog(String action) {
    final TextEditingController noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${action.toUpperCase()} Note"),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(hintText: "Enter $action reason here..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              String note = noteController.text;
              // DEBUG: This should print in your Flutter console
              print("🚀 SUBMITTING $action WITH NOTE: $note");
              Navigator.pop(context);
              // CRITICAL: This is the trigger for the POST request
              _updateStatus(action, note: note);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text("Refund Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white, elevation: 0.5, iconTheme: const IconThemeData(color: Colors.black),
        actions: _buildStatusActions(),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- TOP SECTION: Summary and Product ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildRefundSummaryCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildProductDetailsCard()),
              ],
            ),
            const SizedBox(height: 20),

            // --- MIDDLE SECTION: Reason, Vendor ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildReasonCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildVendorCard()),
                // const SizedBox(width: 20),
                // Expanded(child: _buildDeliveryCard()),
              ],
            ),
            const SizedBox(height: 20),

            // --- BOTTOM SECTION: Status Log ---
            _buildStatusLogCard(),
          ],
        ),
      ),
    );
  }

  // 1. Refund Summary Card
  Widget _buildRefundSummaryCard() {
    return _whiteCard(
      title: "Refund summary",
      child: Column(
        children: [
          _infoRow("Refund id", "${widget.request.id}"),
          _infoRow("Refund Requested Date", DateFormat('dd MMM yyyy, hh:mm:a').format(DateTime.now())),
          _infoRow("Refund status", widget.request.status, isStatus: true),
          _infoRow("Payment method", "stripe"),
          // const SizedBox(height: 10),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Align(
          //     alignment: Alignment.centerLeft,
          //     child: TextButton(
          //       onPressed: () => _viewOrderDetails(widget.request.orderId.toString()),
          //       child: const Text(
          //         "View Order Details",
          //         style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          //       ),
          //     ),
          //   ),
          //
          // ),




        ],
      ),
    );
  }

  // 2. Product Details Card
  // 2. Product Details Card
  Widget _buildProductDetailsCard() {
    // Construct the correct URL logic
    String path = widget.request.imageUrl ?? "";
    String finalUrl = "";

    if (path.startsWith('http')) {
      finalUrl = path;
    } else {
      // Remove leading slash if it exists to avoid double slashes with baseUrl
      String cleanPath = path.startsWith('/') ? path.substring(1) : path;
      finalUrl = "$baseUrl/$cleanPath";
    }

    return _whiteCard(
      title: "Product details",
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and Name
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80, height: 80,
                    color: Colors.grey.shade100,
                    child: Image.network(
                      finalUrl,
                      fit: BoxFit.cover,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      // Placeholder while loading
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      },
                      // Error Fallback
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported, color: Colors.grey),
                          Text(widget.request.productName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.request.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Refund ID: #${widget.request.id}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Price Table
          SizedBox(
            width: 200,
            child: Column(
              children: [
                _priceRow("QTY", "${widget.request.quantity}"),
                _priceRow("Total price", "₹${widget.request.amount}"),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // 3. Reason Card
  Widget _buildReasonCard() {
    return _whiteCard(
      title: "Refund Reason By Customer",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.request.reason.isEmpty ? "No specific reason provided." : widget.request.reason, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 15),
          Row(
            children: [
              _imgPlaceholder(),
              const SizedBox(width: 10),
              _imgPlaceholder(),
            ],
          )
        ],
      ),
    );
  }

  // 4. Vendor Info Card
  Widget _buildVendorCard() {
    return _whiteCard(
      title: "Vendor Info",
      child: Column(
        children: [
          _infoRow("Shop Name", widget.request.shopName),
          _infoRow("Email Address", widget.request.vendorEmail),
          _infoRow("Phone Number", widget.request.vendorPhone),
        ],
      ),
    );
  }


  // // 5. Deliveryman Info Card
  // Widget _buildDeliveryCard() {
  //   return _whiteCard(
  //     title: "Deliveryman Info",
  //     child: const Center(
  //       child: Padding(
  //         padding: EdgeInsets.symmetric(vertical: 40.0),
  //         child: Text("No delivery man assigned", style: TextStyle(color: Colors.grey)),
  //       ),
  //     ),
  //   );
  // }

  // 6. Status Log Table
  Widget _buildStatusLogCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Refund status changed log",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 30),

          // Use SizedBox to force the table to take full width
          SizedBox(
            width: double.infinity,
            child: DataTable(
              dataRowMaxHeight: 60,
              horizontalMargin: 12,
              columnSpacing: 24, // Adjusted spacing
              headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
              columns: const [
                DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Changed By', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))), // New Column
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: statusLogs.asMap().entries.map((e) {
                final log = e.value;
                final status = log['status']?.toString().toLowerCase() ?? '';

                // Formatting the date from DB
                String formattedDate = "N/A";
                if (log['created_at'] != null) {
                  DateTime dt = DateTime.parse(log['created_at'].toString());
                  formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                }

                return DataRow(cells: [
                  DataCell(Text("${e.key + 1}")),
                  DataCell(Text(log['changed_by'].toString().toUpperCase(),
                      style: const TextStyle(fontSize: 13))),
                  DataCell(Text(formattedDate, style: const TextStyle(fontSize: 13))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'approved' ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            color: status == 'approved' ? Colors.blue : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 250, // Limits note width to prevent overflow
                      child: Text(log['note'] ?? "-",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13)
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  // --- UI COMPONENTS ---
  Widget _whiteCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 15),
        child,
      ]),
    );
  }

  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          const Text(":  "),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isStatus ? Colors.orange : Colors.black)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _topActionBtn(String label, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade200)), child: const Icon(Icons.image, size: 20, color: Colors.grey));

  List<Widget> _buildStatusActions() {
    String status = widget.request.status.trim().toLowerCase();

    List<Widget> actions = [];

    if (status == 'pending') {
      actions.addAll([
        _topActionBtn("Reject", Colors.red, () => _showReasonDialog("reject")),
        _topActionBtn("Approve", Colors.cyan, () => _showReasonDialog("approve")),
        _topActionBtn("Approve & Refund", Colors.green, () => _showReasonDialog("refund")),
      ]);
    }

    else if (status == 'approved') {
      actions.addAll([
        _topActionBtn("Reject", Colors.red, () => _showReasonDialog("reject")),
        _topActionBtn("Approve & Refund", Colors.green, () => _showReasonDialog("refund")),
      ]);
    }

    else if (status == 'rejected') {
      actions.addAll([
        _topActionBtn("Approve", Colors.cyan, () => _showReasonDialog("approve")),
        _topActionBtn("Approve & Refund", Colors.green, () => _showReasonDialog("refund")),
      ]);
    }

    else if (status == 'refunded' || status == 'refund') {
      // No buttons
    }

    return actions;
  }

}
