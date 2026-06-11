import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../config/api_config.dart';
import '../../../../core/network/api_client.dart';

class AdminIncomeTaxReport extends StatefulWidget {
  const AdminIncomeTaxReport({super.key});

  @override
  State<AdminIncomeTaxReport> createState() => _AdminIncomeTaxReportState();
}

class _AdminIncomeTaxReportState extends State<AdminIncomeTaxReport> {
  bool isLoading = true;
  List<dynamic> tableData = [];
  Map<String, dynamic> summary = {"totalIncome": "0.00", "totalTax": "0.00"};

  // Filter Variables
  String dateRangeType = "All Time";
  String calculationMethod = "Different Tax for Different Income Source";
  String serviceTaxRate = "Service Tax (6%)";

  @override
  void initState() {
    super.initState();
    _fetchReport(filter: "All Time");
  }

  Future<void> _fetchReport({String? filter}) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final baseUrl = "${ApiConfig.baseUrl}/admin/reports/tax-income";
      final url = Uri.parse(filter != null && filter != "All Time" ? "$baseUrl?filter=$filter" : baseUrl);

      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            tableData = data['data'] ?? [];
            summary = Map<String, dynamic>.from(data['summary'] ?? {"totalIncome": "0.00", "totalTax": "0.00"});
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        title: const Text("Generate Tax Report", style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTopFilterCard(),
            const SizedBox(height: 24),
            _buildSummaryBars(),
            const SizedBox(height: 24),
            _buildReportTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFilterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildDropdown(
                      "Date Range Type",
                      dateRangeType,
                      ["All Time", "This Month", "This Year"],
                          (val) {
                        setState(() => dateRangeType = val!);
                        _fetchReport(filter: val);
                      }
                  )
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildDropdown("Calculation Method", calculationMethod, [calculationMethod], (v){})),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => _fetchReport(filter: dateRangeType),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0052FF)),
                child: const Text("Generate Report"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBars() {
    return Row(
      children: [
        _infoBar("Total Income", "₹${summary['totalIncome']}", const Color(0xffEFF6FF), const Color(0xff2563EB), Icons.account_balance_wallet_outlined),
        const SizedBox(width: 16),
        _infoBar("Total Tax", "₹${summary['totalTax']}", const Color(0xffFFF7ED), const Color(0xffEA580C), Icons.analytics_outlined),
      ],
    );
  }

  Widget _infoBar(String label, String val, Color bg, Color textCol, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: textCol.withOpacity(0.5), size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textCol, fontSize: 12)),
                Text(val, style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Income Source")),
          DataColumn(label: Text("Total Income")),
          DataColumn(label: Text("Tax Amount")),
        ],
        rows: tableData.map((item) => DataRow(cells: [
          DataCell(Text(item['income_source'] ?? "")),
          DataCell(Text("₹${item['total_income']}")),
          DataCell(Text("₹${item['tax_amount']}")),
        ])).toList(),
      ),
    );
  }
}
