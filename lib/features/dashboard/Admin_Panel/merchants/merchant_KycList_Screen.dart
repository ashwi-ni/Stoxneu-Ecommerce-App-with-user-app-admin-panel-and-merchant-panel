import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../config/api_config.dart';
import 'merchant_KycReview_Screen.dart';

class AdminKycListScreen extends StatefulWidget {
  final String status;

  const AdminKycListScreen({super.key, required this.status});

  @override
  State<AdminKycListScreen> createState() => _AdminKycListScreenState();
}

class _AdminKycListScreenState extends State<AdminKycListScreen> {
  List<dynamic> allKyc = [];
  bool loading = true;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final Color primaryColor = const Color(0xff0055D3);

  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  void initState() {
    super.initState();
    fetchAllKyc();
  }

  Future<void> fetchAllKyc() async {
    setState(() => loading = true);
    try {
      final token = await storage.read(key: 'jwt');
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/kyc/all"),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          allKyc = data;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = allKyc.where((k) {
      final statusMatch = k['status']?.toString().toLowerCase() == widget.status.toLowerCase();
      final name = k['merchant_name']?.toLowerCase() ?? "";
      final email = k['email']?.toLowerCase() ?? "";
      final searchMatch = name.contains(searchQuery) || email.contains(searchQuery);
      return statusMatch && searchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- HEADER SECTION ---
            _buildHeader(filteredList.length),
            const SizedBox(height: 20),

            // --- TABLE SECTION ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: loading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildDataTable(filteredList),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.status[0].toUpperCase()}${widget.status.substring(1)} Merchants",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
            ),
            Text("Total $count applications found", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: 300,
          height: 45,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search by name or email...",
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<dynamic> list) {
    if (list.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(40), child: Text("No records found matching your criteria."));
    }

    return DataTable(
      headingRowHeight: 56,
      dataRowHeight: 64,
      horizontalMargin: 20,
      columnSpacing: 24,
      headingRowColor: WidgetStateProperty.all(const Color(0xffF8FAFC)),
      columns: const [
        DataColumn(label: Text("SHOP NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
        DataColumn(label: Text("MERCHANT NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
        DataColumn(label: Text("EMAIL ADDRESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
        DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
        DataColumn(label: Text("TOTAL PRODUCTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
        DataColumn(label: Text("TOTAL ORDERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),

        DataColumn(label: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
      ],
      rows: list.map((kyc) {
        return DataRow(cells: [
          DataCell(Text(kyc['shop_name'] ?? "N/A")),
          DataCell(Text(kyc['merchant_name'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w500))),
          DataCell(Text(kyc['email'] ?? "N/A")),
          DataCell(_buildStatusBadge(widget.status)),
          // Shop Name


          // Products Count
          DataCell(Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text("${kyc['total_products'] ?? 0}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          )),

          // Orders Count
          DataCell(Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text("${kyc['total_orders'] ?? 0}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          )),

          DataCell(
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminKycReviewScreen(kycData: kyc))
                    ).then((_) => fetchAllKyc());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.status == 'pending'
                          ? primaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.status == 'pending' ? Icons.rate_review_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: widget.status == 'pending' ? primaryColor : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ]);
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
