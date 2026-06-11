import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import 'package:stoxneu/Screens/Auth/services/auth_service.dart';
import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';
import '../../../../config/api_config.dart';
import '../widgets/sales_chart.dart';
import '../ApiService/merchant_order_api_service.dart';
import 'Merchant_Orders/order_management_screen.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState
    extends State<MerchantDashboardScreen> {
  late MerchantOrderApiService orderApiService;

  List<Order> latestOrders = [];
  bool loading = true;

  int totalOrders = 0;
  int totalProducts = 0;
  int pendingOrders = 0;
  int cancelledOrders = 0;
  double revenue = 0;

  double walletBalance = 0;
  List<Map<String, dynamic>> payoutHistory = [];

  List<DateTime> chartDates = [];
  List<double> chartTotals = [];

final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    final authApiService = AuthApiService();
    final authRepo = AuthRepository(api: authApiService);
    orderApiService =
        MerchantOrderApiService(authRepository: authRepo);

    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() => loading = true);
    try {
      await fetchStats();
      await fetchWallet();
      await fetchPayoutHistory();
      await fetchOrders();
    } catch (e) {
      debugPrint("❌ Dashboard error: $e");
    }
    setState(() => loading = false);
  }

  Future<void> fetchStats() async {
    final token =
    await orderApiService.authRepository.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: {
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        totalOrders = data["totalOrders"];
        totalProducts = data["totalProducts"];
        pendingOrders = data["pendingOrders"];
        cancelledOrders = data["cancelledOrders"] ?? 0;
        revenue = double.parse(data["revenue"].toString());
      });
    }
  }

  Future<void> fetchWallet() async {
    final token =
    await orderApiService.authRepository.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/merchant/wallet"),
      headers: {
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        walletBalance =
            double.parse(data["balance"].toString());
      });
    }
  }

  Future<void> fetchPayoutHistory() async {
    final token =
    await orderApiService.authRepository.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/merchant/payouts"),
      headers: {
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        payoutHistory =
        List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> fetchOrders() async {
    final orders =
    await orderApiService.fetchMerchantOrders();

    final validOrders = orders.where((o) {
      final status = o.status.toLowerCase().trim();
      return status == "confirmed" || status == "delivered";
    }).toList();

    setState(() {
      latestOrders = orders;
      chartDates = validOrders.map((o) => o.date).toList();
      chartTotals =
          validOrders.map((o) => o.totalAmount).toList();
    });
  }

  double getRequestedAmount() {
    return payoutHistory
        .where((e) =>
    e['status']?.toString().toLowerCase() ==
        'pending')
        .fold(0.0, (sum, e) {
      final amount =
          double.tryParse(e['amount'].toString()) ?? 0;
      return sum + amount;
    });
  }

  double getWithdrawnAmount() {
    return payoutHistory
        .where((e) =>
    e['status']?.toString().toLowerCase() ==
        'completed')
        .fold(0.0, (sum, e) {
      final amount =
          double.tryParse(e['amount'].toString()) ?? 0;
      return sum + amount;
    });
  }

  /// 🔹 STAT CARD
  Widget statCard(
      String title,
      String value, {
        required IconData icon,
        Color iconColor = Colors.blue,
      }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  /// 🔹 RESPONSIVE GRID
  Widget responsiveGrid(List<Widget> children, double width) {
    int count = width > 1200
        ? 4
        : width > 800
        ? 3
        : 2;

    double spacing = 12;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: children
          .map(
            (e) => SizedBox(
          width: (width / count) - (spacing * 1.5),
          child: e,
        ),
      )
          .toList(),
    );
  }

  Widget orderTable(double width) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator());
    }

    if (latestOrders.isEmpty) {
      return const Center(child: Text("No orders"));
    }
    final recentOrders = latestOrders
      ..sort((a, b) => b.date.compareTo(a.date));

    final displayOrders = recentOrders.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        /// 🔹 TABLE
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: width < 800 ? 800 : width,
            ),
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Order SL")),
                DataColumn(label: Text("Order ID")),
                DataColumn(label: Text("Customer")),
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Amount")),
                DataColumn(label: Text("Status")),
              ],
              rows: displayOrders.asMap().entries.map((entry) {
                final index = entry.key;
                final order = entry.value;

                return DataRow(cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Text(order.orderId)),
                  DataCell(Text(order.userId.toString())),
                  DataCell(Text(DateFormat('yyyy-MM-dd').format(order.date))),
                  DataCell(Text("₹${order.totalAmount.toStringAsFixed(2)}")),
                  DataCell(Text(order.status)),
                ]);
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// 🔹 VIEW ALL BUTTON (RIGHT SIDE)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const MerchantOrderListScreen(),
                ),
              );
            },
            child: const Text("View All Orders →"),
          ),
        ),
      ],
    );
  }

  Widget sectionCard({
    required String title,
    required Widget child,
    IconData? icon,
    Color? accentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: (accentColor ?? Colors.blue)
                        .withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: accentColor ?? Colors.blue,
                  ),
                ),

              if (icon != null) const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    print("MERCHANT DASHBOARD BUILDING");
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;

      return SingleChildScrollView(
        padding: EdgeInsets.all(width < 600 ? 12 : 24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text("Welcome back, Merchant!",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            /// 🔹 BUSINESS ANALYSIS (ROW 1)
            /// 🔹 BUSINESS ANALYSIS
            sectionCard(
              title: "Business Analysis",
              icon: Icons.analytics,
              accentColor: Colors.blue,
              child: responsiveGrid([
                statCard("Orders", totalOrders.toString(),
                    icon: Icons.shopping_bag),
                statCard(
                    "Revenue",
                    "₹${revenue.toStringAsFixed(2)}",
                    icon: Icons.currency_rupee,
                    iconColor: Colors.green),
                statCard("Products", totalProducts.toString(),
                    icon: Icons.inventory),
                statCard("Pending", pendingOrders.toString(),
                    icon: Icons.pending),
              ], width),
            ),

            /// 🔹 VENDOR WALLET
            sectionCard(
              title: "Vendor Wallet",
              icon: Icons.account_balance_wallet,
              accentColor: Colors.green,
              child: responsiveGrid([
                statCard(
                    "Balance",
                    "₹${walletBalance.toStringAsFixed(2)}",
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.green),
                statCard(
                    "Requested",
                    "₹${getRequestedAmount().toStringAsFixed(2)}",
                    icon: Icons.schedule,
                    iconColor: Colors.orange),
                statCard(
                    "Withdrawn",
                    "₹${getWithdrawnAmount().toStringAsFixed(2)}",
                    icon: Icons.check_circle,
                    iconColor: Colors.blue),
              ], width),
            ),
            const SizedBox(height: 25),

            /// 🔹 CHART
            Container(
              height: width < 600 ? 240 : 300,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SalesChart(
                dates: chartDates,
                totals: chartTotals,
              ),
            ),

            const SizedBox(height: 25),

            /// 🔹 TABLE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: orderTable(width),
            ),
          ],
        ),
      );
    });
  }
}