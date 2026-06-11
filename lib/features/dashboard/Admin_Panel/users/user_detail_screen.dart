import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stoxneu/config/api_config.dart';
import 'dart:convert';

import '../orders/adminorder_detail_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int userId;
  const CustomerDetailsScreen({super.key, required this.userId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final String baseUrl = ApiConfig.baseUrl;
  final storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    try {
      String? token = await storage.read(key: 'jwt');
      final response = await http.get(
        Uri.parse("$baseUrl/admin/users/${widget.userId}/details"),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Detail Error: $e");
      setState(() => loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (data == null) return const Scaffold(body: Center(child: Text("Data not found")));

    final profile = data!['profile'];
    final stats = data!['stats'];
    final orders = data!['orders'] as List;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Customer Details", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Header Card (Profile)
            _buildProfileCard(profile),
            const SizedBox(height: 20),

            // 2. Status Horizontal List (Ongoing, Completed, etc)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _miniStat("Total Orders", stats['total'], Colors.blue),
                  _miniStat("Ongoing", stats['ongoing'], Colors.orange),
                  _miniStat("Completed", stats['completed'], Colors.green),
                  _miniStat("Canceled", stats['canceled'], Colors.red),
                  _miniStat("Returned", stats['returned'], Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 3. Order Table
            _buildOrderHistoryTable(orders),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(
              p['avatar'] != null && p['avatar'].toString().startsWith('http')
                  ? p['avatar']
                  : "https://ui-avatars.com{p['name'] ?? 'User'}",
            ),
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint("Avatar Image Error: $exception");
            },
          ),

          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? "User", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(p['email'] ?? "", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text("Joined: ${p['created_at'].toString().split('T')[0]}", style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _miniStat(String label, dynamic val, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(15),
      width: 140,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(val?.toString() ?? "0", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryTable(List orders) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DataTable(
        horizontalMargin: 15,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text("Order ID")),
          DataColumn(label: Text("Amount")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Action")), // 🔥 Added Action Column
        ],
        rows: orders.map((o) {
          return DataRow(cells: [
            DataCell(Text("${o['order_id'] ?? 'N/A'}", style: const TextStyle(fontSize: 13))),

            // Amount + Payment Status
            DataCell(Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("₹${o['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    o['payment_status'] ?? "Unpaid",
                    style: TextStyle(
                        fontSize: 10,
                        color: (o['payment_status'] == "PAID" || o['payment_status'] == "Success") ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold
                    )
                ),
              ],
            )),

            // Colored Status Badge
            DataCell(_buildStatusBadge(o['status'].toString())),

            // Action Buttons
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminOrderDetailsScreen(
                          orderId: o['order_id'].toString(), // Passing the order ID
                        ),
                      ),
                    );
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.download, color: Colors.green, size: 20),
                  onPressed: () => generateAndDownloadInvoice(o), // Pass the order object 'o'
                ),

              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

// Helper to build colored badges based on status
  Widget _buildStatusBadge(String status) {
    Color color;
    String formattedStatus = "";

    // 1. Determine Color (Logic check in Uppercase)
    switch (status.toUpperCase()) {
      case 'DELIVERED': color = Colors.green; break;
      case 'PLACED': color = Colors.blue; break;
      case 'PROCESSING': color = Colors.orange; break;
      case 'CANCELED': color = Colors.red; break;
      default: color = Colors.grey;
    }

    // 2. Format string to 'Sentence case' (First letter Cap, rest small)
    if (status.isNotEmpty) {
      formattedStatus = "${status[0].toUpperCase()}${status.substring(1).toLowerCase()}";
    } else {
      formattedStatus = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)
      ),
      child: Text(
        formattedStatus, // This will now show 'Placed'
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }



  Future<void> generateAndDownloadInvoice(Map<String, dynamic> order) async {
    try {
      final pdf = pw.Document();
      final primaryColor = PdfColors.blue900; // Professional brand color

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. HEADER SECTION
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("STOXNEU", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.Text("Your Trusted Trading Partner", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("INVOICE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.Text("#${order['order_id']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // 2. INFORMATION BAR (Company vs Customer)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Billed To:", style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                            pw.Text("${data!['profile']['name']}"),
                            pw.Text("${data!['profile']['email']}"),
                            pw.Text("${order['address']}", style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text("Invoice Details:", style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                            pw.Text("Date: ${DateTime.now().toLocal().toString().split(' ')[0]}"),
                            pw.Text("Payment: ${order['payment_method']}"),
                            pw.Text("Status: ${order['payment_status']}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // 3. ITEMIZED ITEMS TABLE
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: pw.BoxDecoration(color: primaryColor),
                    cellHeight: 30,
                    cellAlignment: pw.Alignment.centerLeft,
                    headerAlignment: pw.Alignment.centerLeft,
                    headers: ['Description', 'Qty', 'Unit Price', 'Total'],
                    data: [
                      ['Order Purchase', '1', 'INR ${order['total_amount']}', 'INR ${order['total_amount']}'],
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // 4. TOTALS SECTION
                  pw.Row(
                    children: [
                      pw.Spacer(flex: 2),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          children: [
                            _invoicePriceRow("Sub Total", "INR ${order['total_amount']}"),
                            _invoicePriceRow("Tax", "INR 0.00"),
                            pw.Divider(),
                            _invoicePriceRow("Grand Total", "INR ${order['total_amount']}", isTotal: true),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.Spacer(),
                  // 5. FOOTER
                  pw.Center(child: pw.Text("This is a computer-generated invoice.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500))),
                  pw.SizedBox(height: 5),
                  pw.Center(child: pw.Text("Thank you for your business!", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'STOXNEU_INV_${order['order_id']}');
    } catch (e) {
      debugPrint("PDF Generation Failed: $e");
    }
  }

// Helper to draw clean rows in the PDF
  pw.Widget _invoicePriceRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isTotal ? 14 : 10)),
        ],
      ),
    );
  }
}
