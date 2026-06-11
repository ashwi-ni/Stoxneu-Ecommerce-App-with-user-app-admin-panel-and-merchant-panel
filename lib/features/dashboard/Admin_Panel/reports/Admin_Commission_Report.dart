import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
// Add to pubspec.yaml

// Mocking your ApiClient for the example, ensure yours is imported
import '../../../../config/api_config.dart';
import '../../../../core/network/api_client.dart';

class AdminCommissionReport extends StatefulWidget {
  const AdminCommissionReport({super.key});

  @override
  State<AdminCommissionReport> createState() => _AdminCommissionReportState();
}

class _AdminCommissionReportState extends State<AdminCommissionReport> {
  bool isLoading = true;
  List<dynamic> commissionData = [];
  List<dynamic> filteredData = [];
  Map<String, dynamic> summary = {};

  // Selection & Search
  Set<int> selectedIndices = {};
  TextEditingController searchController = TextEditingController();
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadCommissionData();
  }

  Future<void> _loadCommissionData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      selectedIndices.clear();
    });

    try {
      // Added query parameters for filtering if your API supports them
      if (selectedDateRange != null) {
      }

      final url = Uri.parse("${ApiConfig.baseUrl}/admin/reports/commissions");
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            commissionData = (data['data'] as List? ?? [])
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

            filteredData = commissionData;

            summary = Map<String, dynamic>.from(data['summary'] ?? {
              "totalSales": 0,
              "totalCommission": 0,
              "totalPayout": 0,
              "pendingPayout": 0,
              "orderCount": 0
            });

            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar("Error: $e", Colors.red);
      }
    }
  }

  void _runFilter(String query) {
    setState(() {
      final searchText = query.toLowerCase();
      filteredData = commissionData.where((item) {
        final vendor = (item['vendor_name'] ?? "").toString().toLowerCase();
        final products = (item['product_names'] ?? "").toString().toLowerCase();
        final id = (item['order_id'] ?? "").toString().toLowerCase();
        return vendor.contains(searchText) || products.contains(searchText) || id.contains(searchText);
      }).toList();
    });
  }


  void _exportToExcel() {
    var excel = ex.Excel.createExcel();

    // 1. Get the default sheet name (usually 'Sheet1')
    String defaultSheet = excel.getDefaultSheet()!;

    // 2. Rename the default sheet to 'Commissions'
    excel.rename(defaultSheet, 'Commissions');

    // 3. Reference the sheet correctly
    ex.Sheet sheet = excel['Commissions'];

    // 4. Append Headers
    sheet.appendRow([
      ex.TextCellValue('Order ID'),
      ex.TextCellValue('Vendor'),
      ex.TextCellValue('Products'),
      ex.TextCellValue('Amount'),
      ex.TextCellValue('Commission'),
      ex.TextCellValue('Payout Status'),
    ]);

    // 5. Append Data
    for (var item in filteredData) {
      sheet.appendRow([
        ex.TextCellValue(item['order_id']?.toString() ?? ""),
        ex.TextCellValue(item['vendor_name']?.toString() ?? ""),
        ex.TextCellValue(item['product_names']?.toString() ?? ""),
        ex.DoubleCellValue(double.tryParse(item['order_amount']?.toString() ?? "0") ?? 0.0),
        ex.DoubleCellValue(double.tryParse(item['commission_amount']?.toString() ?? "0") ?? 0.0),
        ex.TextCellValue(item['payout_status'] == 'completed' ? 'Paid' : 'Pending'),
      ]);
    }

    // 6. Save and Download
    var fileBytes = excel.save();
    if (fileBytes != null) {
      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(fileBytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "Commission_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // If you are testing on Mobile/Emulator, you need path_provider to save locally
        debugPrint("Excel export is configured for Web. Use a browser to test.");
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F8),
      appBar: AppBar(
        title: const Text("Commission Management"),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.calendar_today_outlined),
          //   onPressed: () async {
          //     final range = await showDateRangePicker(
          //         context: context,
          //         firstDate: DateTime(2022),
          //         lastDate: DateTime.now());
          //     if (range != null) {
          //       setState(() => selectedDateRange = range);
          //       _loadCommissionData();
          //     }
          //   },
          // ),
          IconButton(
              onPressed: _exportToExcel,
              icon: const Icon(Icons.file_download_outlined)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // ✅ Makes the entire page scrollable
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildHeaderSummary(),
              const SizedBox(height: 24),
               _buildVisualReport(),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Commission & Payout Ledger", // ✅ Your New Title
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchAndActions(),

              const SizedBox(height: 12),
              _buildTableHead(),
              // Inside your Column in the build method:
              const SizedBox(height: 24),

              _buildList(),

            ],
          ),
        ),
      ),
      bottomNavigationBar:
      selectedIndices.isNotEmpty ? _buildBulkActionBar() : null,
    );
  }

  Widget _buildHeaderSummary() {
    double totalSales = double.tryParse(summary['totalSales']?.toString() ?? '0') ?? 0;
    double paid = double.tryParse(summary['paidPayout']?.toString() ?? '0') ?? 0;
    double pending = double.tryParse(summary['pendingPayout']?.toString() ?? '0') ?? 0;

    // Calculate percentage for a simple visual bar
    double totalPayout = paid + pending;
    double paidWidth = totalPayout > 0 ? (paid / totalPayout) : 0;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard("Total Sales", "₹$totalSales", Colors.blue, Icons.payments),
            const SizedBox(width: 16),
            _buildStatCard("Admin Profit", "₹${summary['totalCommission'] ?? 0}", Colors.green, Icons.trending_up),
            const SizedBox(width: 16),
            _buildStatCard("Pending Payout", "₹$pending", Colors.orange, Icons.hourglass_empty),
          ],
        ),
        const SizedBox(height: 20),
        // --- Simple Visual "Chart" Bar ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Payout Fulfillment", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(height: 12, color: Colors.orange.withOpacity(0.2)), // Total track (Pending)
                    FractionallySizedBox(
                      widthFactor: paidWidth,
                      child: Container(height: 12, color: Colors.green), // Progress (Paid)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Paid: ₹$paid", style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  Text("Remaining: ₹$pending", style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildSearchAndActions() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: _runFilter,
            decoration: InputDecoration(
              hintText: "Search vendor name...",
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text("${filteredData.length} records found", style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
  Widget _buildTableHead() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          //SizedBox(width: 50, child: Text("SELECT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text("ORDER ID", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text("VENDOR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text("PRODUCTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text("ORDER ₹", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text("COMMISSION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text("PAYOUT ₹", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }


  Widget _buildList() {
    final displayData = filteredData;

    return ListView.builder(
      shrinkWrap: true, // ✅ Vital: Tells the list to only take needed space
      physics: const NeverScrollableScrollPhysics(), // ✅ Vital: Disables internal scrolling
      itemCount: displayData.length,
      itemBuilder: (context, index) {
        final item = displayData[index];
        final isSelected = selectedIndices.contains(index);
        final bool isPaid = item['payout_status'] == 'completed';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            hoverColor: Colors.transparent,
            tileColor: Colors.white,
            leading: isPaid
                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                : Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() => val!
                    ? selectedIndices.add(index)
                    : selectedIndices.remove(index));
              },
            ),
            title: Row(
              children: [
                Expanded(flex: 2, child: Text("#${item['order_id']}")),
                Expanded(
                    flex: 3,
                    child: Text(item['vendor_name'] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Text(item['product_names'] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(flex: 2, child: Text("₹${item['order_amount']}")),
                Expanded(
                    flex: 2,
                    child: Text("₹${item['commission_amount']}",
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("₹${item['payout_amount']}")),
                Expanded(
                    flex: 2,
                    child: isPaid
                        ? _statusBadge('Paid')
                        : _statusBadge(item['status'] ?? 'Pending')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Paid') color = Colors.green;
    if (status == 'Cancelled') color = Colors.red;

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Text("${selectedIndices.length} items selected"),
          const Spacer(),
          ElevatedButton(
            // ✅ Just point to the function name, or call it without arguments
            onPressed: _processPayouts,
            child: const Text("Payout All Selected"),
          ),
        ],
      ),
    );
  }


  Widget _buildStatCard(String title, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
  Future<void> _processPayouts() async {
    int successCount = 0;
    int errorCount = 0;

    // Show a loading indicator if you have one
    setState(() => isLoading = true);

    for (var index in selectedIndices) {
      final item = filteredData[index];

      try {
        final response = await ApiClient.post(
          Uri.parse("${ApiConfig.baseUrl}/admin/payouts/update-status"),
          body: jsonEncode({
            "order_id": item['order_id'],    // ✅ Send Order ID
            "merchant_id": item['merchant_id'],
            "amount": item['payout_amount'], // ✅ Send the calculated amount
            "status": "approved",
          }),
        );

        if (response.statusCode == 200) {
          successCount++;
        } else {
          errorCount++;
          debugPrint("Server error for Order ${item['order_id']}: ${response.body}");
        }
      } catch (e) {
        errorCount++;
        debugPrint("Connection error for Order ${item['order_id']}: $e");
      }
    }

    // Final UI Refresh
    await _loadCommissionData();
    setState(() => selectedIndices.clear());
    _showSnackBar(
        "Finished: $successCount successful, $errorCount failed.",
        successCount > 0 ? Colors.green : Colors.red
    );
  }


  Widget _buildVisualReport() {
    double sales = double.tryParse(summary['totalSales']?.toString() ?? '0') ?? 0;
    double commission = double.tryParse(summary['totalCommission']?.toString() ?? '0') ?? 0;
    double merchantShare = sales - commission;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          // 1. The Real Pie Chart
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: commission,
                    title: '${((commission / sales) * 100).toStringAsFixed(1)}%',
                    color: Colors.green,
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: merchantShare,
                    title: '${((merchantShare / sales) * 100).toStringAsFixed(1)}%',
                    color: Colors.orange,
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // 2. Legend (Labels)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(Colors.green, "Admin Profit"),
                const SizedBox(height: 8),
                _buildLegend(Colors.orange, "Vendor Share"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

}
