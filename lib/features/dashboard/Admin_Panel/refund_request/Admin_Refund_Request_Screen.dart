  import 'dart:convert';
  import 'dart:typed_data';
  import 'package:excel/excel.dart' as ex; // Prefix excel to avoid conflicts
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart'; // No longer hiding Border
  import 'package:http/http.dart' as http;
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:stoxneu/features/dashboard/Merchant_Panel/model/refund_model.dart';
    import 'package:universal_html/html.dart' as html;
  import '../../../../config/api_config.dart';
import 'Admin_RefundDetail_Screen.dart';


  class AdminRefundRequestScreen extends StatefulWidget {
    final String status; // e.g. "Pending", "Approved", "Refunded", "Rejected"
    const AdminRefundRequestScreen({super.key, required this.status});

    @override
    State<AdminRefundRequestScreen> createState() => _AdminRefundRequestScreenState();
  }

  class _AdminRefundRequestScreenState extends State<AdminRefundRequestScreen> {
    bool isLoading = true;
    List<RefundRequest> refundRequests = [];
    final String baseUrl = ApiConfig.baseUrl; // Update this
    final storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    bool loading = true;
    List<RefundRequest> filteredRequests = []; // For Search and Filter
    final TextEditingController _searchController = TextEditingController();


    @override

    void initState() {
      super.initState();
    }

    @override
    void didUpdateWidget(AdminRefundRequestScreen oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (oldWidget.status != widget.status) {
        fetchRefundRequests();
      }
    }
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      fetchRefundRequests(); // Refresh data whenever the route status changes
    }

  // --- SEARCH LOGIC ---
    void _runSearch(String query) {
      setState(() {
        filteredRequests = refundRequests.where((req) {
          final idMatch = req.id.toString().contains(query);
          final orderMatch = req.orderId.toString().contains(query);
          final nameMatch = req.productName.toLowerCase().contains(query.toLowerCase());
          return idMatch || orderMatch || nameMatch;
        }).toList();
      });
    }


    Future<void> _exportToExcel() async {
      var excel = ex.Excel.createExcel();

      // 1. Rename the default sheet instead of creating a new one
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, 'Refunds');
      ex.Sheet sheet = excel['Refunds'];

      // Headers
      sheet.appendRow([
        ex.TextCellValue('Refund ID'),
        ex.TextCellValue('Order ID'),
        ex.TextCellValue('Product'),
        ex.TextCellValue('Amount'),
        ex.TextCellValue('Status')
      ]);

      // Data
      for (var req in filteredRequests) {
        sheet.appendRow([
          ex.IntCellValue(req.id),
          ex.IntCellValue(req.orderId),
          ex.TextCellValue(req.productName),
          ex.DoubleCellValue(req.amount),
          ex.TextCellValue(req.status)
        ]);
      }

      var fileBytes = excel.save();
      if (kIsWeb && fileBytes != null) {
        final blob = html.Blob([Uint8List.fromList(fileBytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "Refunds_${widget.status}.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      }
      _showSnackBar("Exported Successfully", Colors.green);
    }


    Future<void> fetchRefundRequests() async {
      if (!mounted) return;
      setState(() => loading = true);

      try {
        String? token = await storage.read(key: 'jwt');
        final response = await http.get(
          Uri.parse("$baseUrl/admin/refunds?status=${widget.status.toLowerCase()}"),
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          if (jsonResponse['success'] == true) {
            final List<dynamic> dataList = jsonResponse['data'] ?? [];

            setState(() {
              // 1. Map the data to your model
              refundRequests = dataList.map((json) => RefundRequest.fromJson(json)).toList();

              // 🔥 2. CRITICAL: Update the list that the DataTable actually uses!
              filteredRequests = List.from(refundRequests);

              loading = false;
            });
            print("UI Logic: Displaying ${filteredRequests.length} rows");
          }
        } else {
          setState(() => loading = false);
          _showSnackBar("Server Error: ${response.statusCode}", Colors.red);
        }
      } catch (e) {
        print("Flutter Error: $e");
        setState(() => loading = false);
      }
    }



    // 5. Added the missing _showSnackBar method
    void _showSnackBar(String msg, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
      );
    }

  // Helper to call any refund status update API
    Future<void> _updateRefundStatus(int refundId, String action, double amount, String note) async {
      try {
        String? token = await storage.read(key: 'jwt');
        String actionClean = action.toLowerCase().trim();

        // 🔥 This single request handles updating tables, logs, and notification emitters
        final response = await http.post(
          Uri.parse("$baseUrl/merchant/refunds/$refundId/$actionClean"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'note': note}),
        );

        if (response.statusCode == 200) {
          _showSnackBar("Refund status updated successfully!", Colors.green);
          fetchRefundRequests(); // Safely refreshes the data grid layout
        } else {
          _showSnackBar("Failed to execute update: ${response.body}", Colors.red);
        }

      } catch (e) {
        _showSnackBar("System Network Error: $e", Colors.red);
      }
    }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xffF9F9FB),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // Container for the Table
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    loading
                        ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
                        : _buildDataTable(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildTableHeader() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text("${widget.status} Refund Requests",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _badge(refundRequests.length),
            const Spacer(),
            _searchField(),

            const SizedBox(width: 8),
            _outlinedBtn(Icons.download, "Export", onTap: _exportToExcel),
          ],
        ),
      );
    }

    Widget _buildDataTable() {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // Forces the table to be at least as wide as the container
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                dataRowMaxHeight: 60, // Increase this value (default is usually 48-52)
                horizontalMargin: 12,
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
                columns: const [
                  DataColumn(label: Text('SL')),
                  DataColumn(label: Text('Refund ID')),
                  DataColumn(label: Text('Order ID')),
                  DataColumn(label: Text('Product   Info')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Action')),
                ],
                rows: filteredRequests.asMap().entries.map((entry) {

                  int index = entry.key;
                  RefundRequest request = entry.value;
                  return DataRow(cells: [
                    DataCell(Text("${index + 1}")),
                    DataCell(Text("${request.id}")),
                    DataCell(Text("${request.orderId}")),
                    DataCell(_productInfoCell(request)),
                    DataCell(Text("₹${request.amount.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(SizedBox(
                        width: 150,
                        child: Text(request.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12))
                    )),
                    DataCell(_actionButtons(request)),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      );
    }
    Widget _productInfoCell(RefundRequest request) {
      // Use the fixed getter from the model
      final String imageUrl = request.fullImageUrl;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              // Your dynamic image URL

              request.fullImageUrl,
              width: 35,
              height: 35,
              fit: BoxFit.cover,
              headers: const {'ngrok-skip-browser-warning': 'true'}, // Necessary for ngrok

              // 1. Placeholder while loading
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 35,
                  height: 35,
                  color: Colors.grey.shade100,
                  child: const Center(
                      child: SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2,)
                      )
                  ),
                );

              },

              // 2. Placeholder if image fails to load (404, invalid URL, etc.)
              errorBuilder: (context, error, stackTrace) {
                return _buildInitialsPlaceholder(request.productName);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Use Column without Expanded if it's inside a Row inside a DataCell
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(request.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("QTY: ${request.quantity}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )
        ],
      );
    }
    Widget _actionButtons(RefundRequest request) {
      String status = request.status.trim().toLowerCase();

      return Row(
        children: [
          // 👁 Always visible
          _iconBtn(Icons.visibility, Colors.blue, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminRefundDetailScreen(request: request),
              ),
            );
          }),

          const SizedBox(width: 6),

          // 🔥 STATUS-WISE ICON CONTROL

          if (status == 'pending') ...[
            // 🔄 Refund
            _iconBtn(Icons.cached, Colors.orange, () {
              _showReasonDialog("refund", request.id, request.amount);
            }),
            const SizedBox(width: 6),

            // ❌ Reject
            _iconBtn(Icons.close, Colors.red, () {
              _showReasonDialog("reject", request.id, request.amount);
            }),
            const SizedBox(width: 6),

            // ✅ Approve
            _iconBtn(Icons.check, Colors.green, () {
              _showReasonDialog("approve", request.id, request.amount);
            }),
          ]

          else if (status == 'approved') ...[
            // ❌ Reject
            _iconBtn(Icons.close, Colors.red, () {
              _showReasonDialog("reject", request.id, request.amount);
            }),
            const SizedBox(width: 6),

            // 🔄 Refund
            _iconBtn(Icons.cached, Colors.orange, () {
              _showReasonDialog("refund", request.id, request.amount);
            }),
          ]

          else if (status == 'rejected') ...[
              // ✅ Approve
              _iconBtn(Icons.check, Colors.green, () {
                _showReasonDialog("approve", request.id, request.amount);
              }),
              const SizedBox(width: 6),

              // 🔄 Refund
              _iconBtn(Icons.cached, Colors.orange, () {
                _showReasonDialog("refund", request.id, request.amount);
              }),
            ]

            else if (status == 'refunded' || status == 'refund') ...[
                // 🚫 No actions (only view)
              ],
        ],
      );
    }

    // --- UI Styled Helpers ---

    Widget _badge(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Text("$count", style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)));

    Widget _searchField() => SizedBox(
      width: 220, height: 35,
      child: TextField(
        controller: _searchController,
        onChanged: _runSearch, // Connect search [INDEX 3]
        decoration: InputDecoration(
            hintText: "Search ID, Order or Product...",
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            filled: true, fillColor: Colors.white),
      ),
    );

    Widget _outlinedBtn(IconData icon, String label, {VoidCallback? onTap}) => OutlinedButton.icon(
      onPressed: onTap, // <--- Link this here
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );


    Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.2)), // Uses Flutter Border
              borderRadius: BorderRadius.circular(4)
          ),
          child: Icon(icon, color: color, size: 16)
      ),
    );

    void _showReasonDialog(String action, int refundId,double amount) {
      final TextEditingController noteController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("${action.toUpperCase()} Note"),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter $action reason here...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String note = noteController.text;
                Navigator.pop(context);
                _updateRefundStatus(refundId, action, amount, note);
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInitialsPlaceholder(String name) {
    // Uses ui-avatars.com to generate a high-quality initials image
    final String initialsUrl = "https://ui-avatars.com{Uri.encodeComponent(name)}&background=random&color=fff&bold=true";

    return Image.network(
      initialsUrl,
      width: 35,
      height: 35,
      fit: BoxFit.cover,
      // Final fallback to a static icon if even the avatar API fails
      errorBuilder: (context, error, stackTrace) => Container(
        width: 35,
        height: 35,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 20, color: Colors.grey),
      ),
    );
  }

