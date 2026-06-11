import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';
import '../../../../Screens/Products/product_api.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import 'adminorder_detail_screen.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  late final ProductApi productApi;
  List<Order> allOrders = [];
  List<Order> filteredOrders = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    productApi = ProductApi();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => loading = true);
    try {
      final res = await productApi.fetchAllOrdersForAdmin();
      setState(() {
        allOrders = res;
        filteredOrders = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _showSnackBar("Error loading orders: $e", Colors.red);
    }
  }

  void _runSearch(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      filteredOrders = allOrders.where((order) {
        final matchesId = order.orderId.toLowerCase().contains(lowercaseQuery);
        final dateString = DateFormat('dd MMM yyyy').format(order.date).toLowerCase();
        final matchesDate = dateString.contains(lowercaseQuery);
        return matchesId || matchesDate;
      }).toList();
    });
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      sheetObject.appendRow([
        TextCellValue('SL'),
        TextCellValue('Order ID'),
        TextCellValue('Date'),
        TextCellValue('Amount'),
        TextCellValue('Status'),
        TextCellValue('Payment'),
      ]);

      // Data Rows
      for (int i = 0; i < filteredOrders.length; i++) {
        var o = filteredOrders[i];
        sheetObject.appendRow([
          IntCellValue(i + 1),
          TextCellValue(o.orderId),
          TextCellValue(DateFormat('dd MMM yyyy').format(o.date)),
          DoubleCellValue(o.totalAmount),
          TextCellValue(o.status),
          TextCellValue(o.paymentStatus),
        ]);
      }

      var fileBytes = excel.save();
      if (fileBytes == null) return;

      if (kIsWeb) {
        final content = Uint8List.fromList(fileBytes);
        final blob = html.Blob([content], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "Orders_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar("Exported successfully", Colors.green);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = "${directory.path}/Orders_Export.xlsx";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        _showSnackBar("File saved to documents folder", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Export failed: $e", Colors.red);
    }
  }

  int _getCount(String status) {
    return allOrders.where((o) => o.status.toLowerCase() == status.toLowerCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSummaryGrid(),
            const SizedBox(height: 30),
            _buildOrderTableContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text("Order Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _badge(allOrders.length),
        const Spacer(),
        _searchField(),
        const SizedBox(width: 12),
        _outlinedBtn(Icons.download, "Export", onTap: _exportToExcel),
      ],
    );
  }

  Widget _buildOrderTableContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                horizontalMargin: 12,
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
                columns: const [
                  DataColumn(label: Text('SL')),
                  DataColumn(label: Text('Order ID')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Total Amount')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Action')),
                ],
                rows: filteredOrders.asMap().entries.map((entry) {
                  int index = entry.key;
                  Order order = entry.value;
                  return DataRow(cells: [
                    DataCell(Text("${index + 1}")),
                    DataCell(Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(DateFormat('dd MMM yyyy').format(order.date))),
                    DataCell(Text("₹${order.totalAmount.toStringAsFixed(2)}")),
                    DataCell(_statusBadge(order.status)),
                    DataCell(_paymentBadge(order.paymentStatus)),
                    DataCell(Row(
                      children: [

                        _iconBtn(Icons.visibility, Colors.blue, () => _viewOrderDetails(order)),
                        const SizedBox(width: 8),
                        _iconBtn(Icons.download, Colors.grey, () => _downloadInvoice(order)),
                      ],
                    )),

                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI Helpers ---

  Widget _badge(int count) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Text("$count", style: const TextStyle(fontSize: 11)));

  Widget _searchField() => SizedBox(
      width: 250,
      height: 35,
      child: TextField(
          controller: _searchController,
          onChanged: _runSearch,
          decoration: InputDecoration(
              hintText: "Search ID or Date...",
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: Colors.white)));

  Widget _outlinedBtn(IconData icon, String label, {VoidCallback? onTap}) => OutlinedButton.icon(
    onPressed: onTap,
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.2)), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, color: color, size: 16),
    ),
  );

  Widget _statusBadge(String status) {
    Color color = Colors.blue;
    if (status == "Pending") color = Colors.orange;
    if (status == "Placed") color = Colors.green;
    if (status == "Delivered") color = Colors.blue;
    if (status == "Canceled") color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _paymentBadge(String status) {
    bool isPaid = status.toUpperCase() == "PAID";
    return Text(status, style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w600));
  }

  Widget _summaryCard(String title, String count, Color color, IconData icon) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        _summaryCard("Pending", _getCount("Pending").toString(), Colors.orange, Icons.hourglass_empty),
        _summaryCard("Placed", _getCount("Placed").toString(), Colors.green, Icons.check_circle_outline),
        _summaryCard("Delivered", _getCount("Delivered").toString(), Colors.blue, Icons.local_shipping),
        _summaryCard("Refund Requests", allOrders.where((o) => o.refundStatus == "REQUESTED").length.toString(), Colors.red, Icons.assignment_return),
      ],
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminOrderDetailsScreen(

          orderId: order.orderId.toString(),
        ),
      ),
    );
  }

  Future<void> _downloadInvoice(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("INVOICE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Stoxneu Admin Dashboard"),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Order ID: ${order.orderId}"),
                pw.Text("Date: ${DateFormat('dd MMM yyyy').format(order.date)}"),
              ]),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Description', 'Status', 'Total'],
                data: [
                  ['Order Purchase', order.status, 'Rs.${order.totalAmount.toStringAsFixed(2)}'],
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Grand Total: Rs.${order.totalAmount.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.orderId}',
    );
  }
}
