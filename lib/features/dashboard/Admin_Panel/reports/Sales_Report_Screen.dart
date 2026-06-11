import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:universal_html/html.dart' as html;
import '../../../../Screens/Products/product_api.dart';
import 'model/sales_report_model.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late ProductApi productApi;
  SalesReportData? reportData;
  bool isLoading = true;
  String _selectedFilter = "This Year";

  @override
  void initState() {
    super.initState();
    productApi = ProductApi();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final data = await productApi.fetchSalesReport(_selectedFilter);
      setState(() {
        reportData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    // 1. Safety Check: If we aren't loading but data is still null, show a message
    if (!isLoading && reportData == null) {
      return const Scaffold(body: Center(child: Text("No data found or failed to load")));
    }

    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inside build -> Column
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildSalesSummaryCard(),
                      const SizedBox(height: 16),
                      // 🔥 Dynamically fetch Product Count
                      _buildStatCard(
                          reportData?.totalProductsSold.toString() ?? "0",
                          "Total Products Sold",
                          Icons.inventory_2_outlined,
                          Colors.orange
                      ),
                      const SizedBox(height: 16),
                      // 🔥 Dynamically fetch Vendor Count
                      _buildStatCard(
                          reportData?.activeVendors.toString() ?? "0",
                          "Active Vendors",
                          Icons.storefront_outlined,
                          Colors.blue
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                Expanded(
                  flex: 2,
                  child: _buildChartContainer(
                    title: "Sales Statistics",
                    // 🔥 FIX: Use ?? [] to provide an empty list if null
                    child: _buildSalesLineChart(reportData?.chartData ?? []),
                  ),
                ),
                const SizedBox(width: 24),

                Expanded(
                  flex: 1,
                  child: _buildChartContainer(
                    title: "Payment Statistics",
                    // 🔥 FIX: Use ?? [] to provide an empty list if null
                    child: _buildPaymentMethodList(reportData?.paymentData ?? []),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTransactionTable(),
          ],
        ),
      ),
    );
  }

  /// --- HEADER & FILTERS ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sales Reports", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(labelText: "Filter", border: OutlineInputBorder()),
                  items: ["This Month", "This Year"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedFilter = val!),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff004182), minimumSize: const Size(140, 52)),
                onPressed: _loadData,
                child: const Text("Filter", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ],
    );
  }

  /// --- SUMMARY CARD ---
  Widget _buildSalesSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("\$${reportData?.totalSales.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Total Sales Amount", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _subValueItem("\$${reportData?.totalCommission.toStringAsFixed(1)}k", "Comm.", Colors.red),
              _subValueItem("\$${reportData?.vendorShare.toStringAsFixed(1)}k", "Vendor", Colors.blue),
               _subValueItem("\$0.0k", "Tax", Colors.green),
            ],
          )
        ],
      ),
    );
  }

  Widget _subValueItem(String val, String label, Color color) {
    return Column(children: [
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    ]);
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ])
      ]),
    );
  }

  /// --- CHART CONTAINERS ---
  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      height: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(child: child),
      ]),
    );
  }

  Widget _buildSalesLineChart(List<Map<String, dynamic>> data) {
    // 1. Create a helper list for month names
    const monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    List<FlSpot> spots = data.map((e) => FlSpot(
        double.parse(e['month'].toString()),
        double.parse(e['amount'].toString())
    )).toList();

    if (spots.isEmpty) spots = [const FlSpot(0, 0)];

    // ... (Your monthNames and spots logic) ...

    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false, // 🔥 Fixed: No vertical lines
          horizontalInterval: 50000,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

          // 🔥 ADD THIS: Format Left Titles to prevent "Crashing"
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40, // Space for the "k" labels
              getTitlesWidget: (value, meta) {
                // Convert 50000 to 50k, 100000 to 100k
                String text = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toStringAsFixed(0);
                return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10));
              },
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 1 && index <= 12) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      monthNames[index],
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xff004182),
            barWidth: 3,
            // Make the dots visible so the user can see exact data points
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xff004182).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildPaymentMethodList(List<Map<String, dynamic>> payments) {
    return Column(
      children: [
        Text("\$${reportData?.totalSales.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("Payments Amount", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        // 🔥 Wrapped in Expanded/ListView to prevent overflow crashes
        Expanded(
          child: ListView.separated(
            itemCount: payments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = payments[index];
              return Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.blue),
                  const SizedBox(width: 10),
                  // 🔥 Use Expanded for the name so it wraps if it's too long
                  Expanded(
                    child: Text(
                      p['payment_method'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis, // Prevents crashing into the price
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 🔥 Keep the price on the right
                  Text(
                    "\$${double.tryParse(p['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildTransactionTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Forces children to fill width
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Transaction Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Export CSV"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xff004182),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xff004182)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(
              cardTheme: const CardThemeData(elevation: 0),
              dividerColor: Colors.transparent, // Hides row dividers
              dataTableTheme: DataTableThemeData(
                dataRowColor: MaterialStateProperty.all(Colors.white),
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
              ),
            ),
            child: SizedBox(
              width: double.infinity, // Ensures the table occupies full width
              child: PaginatedDataTable(
                header: null,
                rowsPerPage: 5,
                dividerThickness: 0, // Removes the physical line thickness
                columnSpacing: 20, // Adjust this to control how columns spread out
                columns: const [
                  DataColumn(label: Text('Order ID')),
                  DataColumn(label: Text('Vendor')),
                  DataColumn(label: Text('Subtotal')),
                  DataColumn(label: Text('Commission')),
                  DataColumn(label: Text('Status')),
                ],
                source: TransactionDataSource(reportData?.transactions ?? []),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _exportToExcel() async {
    if (reportData == null || reportData!.transactions.isEmpty) {
      _showSnackBar("No data available to export", Colors.orange);
      return;
    }

    // 1. Create the Excel object
    var excel = ex.Excel.createExcel();

    // 2. Setup the sheet
    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Sales Report');
    ex.Sheet sheet = excel['Sales Report'];

    // 3. Add Headers
    sheet.appendRow([
      ex.TextCellValue('Order ID'),
      ex.TextCellValue('Vendor'),
      ex.TextCellValue('Subtotal'),
      ex.TextCellValue('Commission'),
      ex.TextCellValue('Status')
    ]);

    // 4. Populate Data from your reportData transactions
    for (var t in reportData!.transactions) {
      sheet.appendRow([
        ex.TextCellValue(t['order_id']?.toString() ?? 'N/A'),
        ex.TextCellValue(t['vendor_name']?.toString() ?? 'Unknown'),
        ex.DoubleCellValue(double.tryParse(t['subtotal'].toString()) ?? 0.0),
        ex.DoubleCellValue(double.tryParse(t['commission'].toString()) ?? 0.0),
        ex.TextCellValue(t['status']?.toString() ?? 'N/A')
      ]);
    }

    // 5. Generate and Download for Web
    var fileBytes = excel.save();
    if (kIsWeb && fileBytes != null) {
      final blob = html.Blob(
          [Uint8List.fromList(fileBytes)],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", "Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx")
        ..click();

      html.Url.revokeObjectUrl(url);
      _showSnackBar("Excel Exported Successfully", Colors.green);
    }
  }
}

class TransactionDataSource extends DataTableSource {
  final List<dynamic> transactions;

  TransactionDataSource(this.transactions);

  @override
  DataRow? getRow(int index) {
    if (index >= transactions.length) return null;
    final data = transactions[index];

    return DataRow(cells: [
      DataCell(Text("#${data['order_id'] ?? 'N/A'}")),
      DataCell(Text(data['vendor_name'] ?? 'Unknown')),
      DataCell(Text("\$${data['subtotal'] ?? '0.00'}")),
      DataCell(Text("\$${data['commission'] ?? '0.00'}",
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: data['status'] == "Completed" ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            data['status'] ?? 'Pending',
            style: TextStyle(
              color: data['status'] == "Completed" ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => transactions.length;

  @override
  int get selectedRowCount => 0;
}


