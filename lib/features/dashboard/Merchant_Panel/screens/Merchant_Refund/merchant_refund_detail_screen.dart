import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:stoxneu/config/api_config.dart';
import '../../model/refund_model.dart';
import 'BLOC/MerchantRefundBloc.dart';
import 'BLOC/MerchantRefundEvent.dart';
import 'BLOC/MerchantRefundState.dart';

class RefundDetailScreen extends StatefulWidget {
  final RefundRequest refund;
  const RefundDetailScreen({super.key, required this.refund});

  @override
  State<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends State<RefundDetailScreen> {
  final storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  final String baseUrl = ApiConfig.baseUrl;
  List<dynamic> statusLogs = [];
  bool isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    setState(() => isLoadingLogs = true);
    try {
      String? token = await storage.read(key: 'jwt');
      final response = await http.get(
        Uri.parse("$baseUrl/merchant/refunds/${widget.refund.id}/logs"),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          statusLogs = data['data'] ?? [];
          isLoadingLogs = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      setState(() => isLoadingLogs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MerchantRefundBloc, dynamic>(
      listener: (context, state) {
        if (state is RefundActionSuccess) {
          fetchLogs(); // Refresh logs on success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        appBar: AppBar(
          title: const Text("Refund Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: _buildActions(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _summaryCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _productCard()),
                ],
              ),
              const SizedBox(height: 16),
              _reasonCard(),
              const SizedBox(height: 16),
              _buildStatusLogCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- ACTIONS ---
  List<Widget> _buildActions() {
    final status = widget.refund.status.toLowerCase();
    if (status != "pending") return [];

    return [
      _topBtn("Reject", Colors.red.shade400, () => _openDialog("reject")),
      _topBtn("Approve", const Color(0xff4F46E5), () => _openDialog("approve")),
      const SizedBox(width: 8),
    ];
  }

  Widget _topBtn(String text, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: color, textStyle: const TextStyle(fontWeight: FontWeight.bold)),
        child: Text(text),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _summaryCard() {
    return _baseCard("Summary", Column(
      children: [
        _row("ID", "#${widget.refund.id}"),
        _row("Status", widget.refund.status.toUpperCase(), isStatus: true),
        _row("Amount", "₹${widget.refund.amount}", isBold: true),
      ],
    ));
  }

  Widget _productCard() {
    return _baseCard("Product", Row(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.refund.productName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text("Quantity: ${widget.refund.quantity}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _reasonCard() {
    return _baseCard("Customer Reason", Text(
      widget.refund.reason.isEmpty ? "No reason provided" : widget.refund.reason,
      style: TextStyle(color: Colors.grey.shade800),
    ));
  }

  // --- DYNAMIC LOG TABLE ---
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

  // --- HELPERS ---
  Widget _baseCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isStatus = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          isStatus ? _statusText(value) : Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _statusText(String status) {
    Color color = status.toLowerCase() == 'approved' ? Colors.green : (status.toLowerCase() == 'pending' ? Colors.orange : Colors.red);
    return Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12));
  }

  void _openDialog(String action) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm ${action.toUpperCase()}"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Reason note...", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              context.read<MerchantRefundBloc>().add(
                  action == "approve"
                      ? ApproveRefundRequest(widget.refund.id, controller.text)
                      : RejectRefundRequest(widget.refund.id, controller.text)
              );
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}
