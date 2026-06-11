import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../config/api_config.dart';
import '../services/admin_dashboard_service.dart';
import '../widgets/simple_line_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late AdminDashboardService service;

  bool loading = true;

  int totalUsers = 0;
  int totalOrders = 0;
  int activeMerchants = 0;
  double totalRevenue = 0;

  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  List<double> salesTrend = [];
  List<double> ordersTrend = [];
  List<dynamic> recentOrders = [];
  int pendingKycCount = 0;

  @override
  void initState() {
    super.initState();
    service = AdminDashboardService(ApiConfig.baseUrl);
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

      String? token = await storage.read(key: 'jwt');

      if (token == null) {
        debugPrint("❌ Token not found");
        setState(() => loading = false);
        return;
      }

      final data = await service.getDashboard(token);

      setState(() {
        totalUsers = data["totalUsers"] ?? 0;
        totalOrders = data["totalOrders"] ?? 0;
        activeMerchants = data["activeMerchants"] ?? 0;
        totalRevenue = double.tryParse(data["totalRevenue"].toString()) ?? 0;

        salesTrend = (data["salesTrend"] as List? ?? [])
            .map((e) => double.tryParse(e["value"].toString()) ?? 0.0)
            .toList();

        ordersTrend = (data["ordersTrend"] as List? ?? [])
            .map((e) => double.tryParse(e["value"].toString()) ?? 0.0)
            .toList();

        recentOrders = data["recentOrders"] ?? [];
        pendingKycCount = data["alerts"]["pendingKyc"] ?? 0;

        loading = false;
      });
    } catch (e) {
      debugPrint("Dashboard error: $e");
      setState(() => loading = false);
    }
  }

  Widget statCard(String title, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status.toLowerCase() == "delivered"
        ? Colors.green
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Admin Dashboard",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// 🔥 STATS
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                statCard("Users", "$totalUsers", Icons.people),
                statCard("Orders", "$totalOrders", Icons.shopping_cart),
                statCard("Revenue", "₹$totalRevenue", Icons.currency_rupee),
                statCard("Merchants", "$activeMerchants", Icons.store),
              ],
            ),

            const SizedBox(height: 25),

            /// 🔥 CHARTS
            Row(
              children: [
                Expanded(
                  child: SimpleLineChart(
                    values: salesTrend,
                    title: "Sales Trend",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SimpleLineChart(
                    values: ordersTrend,
                    title: "Orders Trend",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// 🔥 HEADER ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Transactions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (pendingKycCount > 0)
                  Chip(
                    label: Text("$pendingKycCount Pending KYCs"),
                    backgroundColor: Colors.orange.shade100,
                    labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 15),

            /// 🔥 TABLE (FIXED)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // important for expansion
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 700), // 👈 expands table
                  child: DataTable(
                    columnSpacing: 450, // increased spacing
                    horizontalMargin: 20,
                    headingRowHeight: 50,
                    dataRowHeight: 55,
                    dividerThickness: 0.6,
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),

                    columns: const [
                      DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],

                    rows: recentOrders.isEmpty
                        ? const [
                      DataRow(
                        cells: [
                          DataCell(Text("No orders")),
                          DataCell(Text("-")),
                          DataCell(Text("-")),
                          DataCell(Text("-")),
                        ],
                      )
                    ]
                        : recentOrders.map((order) {
                      return DataRow(
                        cells: [
                          DataCell(Text("#${order['order_id']}")),
                          DataCell(Text(order['customer_name'] ?? "Guest")),
                          DataCell(Text("₹${order['total_amount']}")),
                          DataCell(_statusBadge(order['status'] ?? "Pending")),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}