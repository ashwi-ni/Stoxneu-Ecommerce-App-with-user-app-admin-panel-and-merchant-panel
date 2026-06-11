import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import '../../../../../config/api_config.dart';
import 'helper/wallet_service.dart';

class MerchantPaymentScreen extends StatefulWidget {
  const MerchantPaymentScreen({super.key});

  @override
  State<MerchantPaymentScreen> createState() => _MerchantPaymentScreenState();
}

class _MerchantPaymentScreenState extends State<MerchantPaymentScreen> {
  late BuildContext parentContext;
  late WalletService walletService;

  double walletBalance = 0.0;
  double totalCommission = 0.0;
  double pendingPayout = 0.0;
  double totalWithdrawn = 0.0;

  bool isLoading = true;
  bool isRequestingPayout = false;
  bool isHistoryLoading = true;

  final TextEditingController payoutController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "all";
  String selectedMethod = "UPI";

  List<Map<String, dynamic>> payoutHistory = [];

  @override
  void initState() {
    super.initState();

    final authRepo = Provider.of<AuthRepository>(context, listen: false);

    walletService = WalletService(
      baseUrl: ApiConfig.baseUrl,
      authRepository: authRepo,
    );

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([
        fetchWallet(),
        fetchPayoutHistory(),
        walletService.fetchSavedPaymentMethods(),
      ]);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchWallet() async {
    final data = await walletService.getWalletStats();

    if (!mounted) return;

    setState(() {
      walletBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
      pendingPayout = double.tryParse(data['pending'].toString()) ?? 0.0;
      totalWithdrawn = double.tryParse(data['withdrawn'].toString()) ?? 0.0;
      totalCommission =
          double.tryParse(data['total_commission'].toString()) ?? 0.0;
    });
  }

  Future<void> fetchPayoutHistory() async {
    setState(() => isHistoryLoading = true);

    try {
      final history = await walletService.getPayoutHistory();
      if (mounted) setState(() => payoutHistory = history);
    } finally {
      if (mounted) setState(() => isHistoryLoading = false);
    }
  }

  double getTotalByStatus(String status) {
    return payoutHistory
        .where((e) => e['status'] == status)
        .fold(0.0, (sum, item) {
      return sum + double.parse(item['amount'].toString());
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    parentContext = context;

    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ================= RESPONSIVE CARDS =================
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                Widget card({
                  required String title,
                  required double amount,
                  required Color color,
                  required String icon,
                  String? buttonText,
                  VoidCallback? onTap,
                }) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(icon, width: 22, height: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (buttonText != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onTap,
                              child: Text(buttonText),
                            ),
                          ),

                        const SizedBox(height: 10),

                        FittedBox(
                          child: Text(
                            "₹${amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }

                if (isMobile) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth / 2 - 16,
                        child: card(
                          title: "Current Balance",
                          amount: walletBalance,
                          color: Colors.blue,
                          icon: "images/currentbal.png",
                          buttonText: "Withdraw",
                          onTap: openWithdrawDrawer,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth / 2 - 16,
                        child: card(
                          title: "Commission",
                          amount: totalCommission,
                          color: Colors.purple,
                          icon: "images/requestbal.png",
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth / 2 - 16,
                        child: card(
                          title: "Requested",
                          amount: getTotalByStatus('pending'),
                          color: Colors.orange,
                          icon: "images/requestbal.png",
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth / 2 - 16,
                        child: card(
                          title: "Withdrawn",
                          amount: getTotalByStatus('completed'),
                          color: Colors.green,
                          icon: "images/withdrawbal.png",
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: card(
                        title: "Current Balance",
                        amount: walletBalance,
                        color: Colors.blue,
                        icon: "images/currentbal.png",
                        buttonText: "Withdraw",
                        onTap: openWithdrawDrawer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: card(
                        title: "Commission",
                        amount: totalCommission,
                        color: Colors.purple,
                        icon: "images/requestbal.png",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: card(
                        title: "Requested",
                        amount: getTotalByStatus('pending'),
                        color: Colors.orange,
                        icon: "images/requestbal.png",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: card(
                        title: "Withdrawn",
                        amount: getTotalByStatus('completed'),
                        color: Colors.green,
                        icon: "images/withdrawbal.png",
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            /// ================= HISTORY TABLE =================

            /// ================= HISTORY TABLE (FULL WIDTH + WHITE + SCROLL) =================
            SizedBox(
              width: double.infinity,
              child: Card(
                color: Colors.white, // ✅ WHITE CARD
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isHistoryLoading
                      ? const Center(child: CircularProgressIndicator())
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal, // ✅ HORIZONTAL SCROLL
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth, // ✅ FULL WIDTH
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.grey.shade200,
                            ),
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors.grey.shade100, // header light grey
                              ),
                              dataRowColor: MaterialStateProperty.resolveWith(
                                    (states) => Colors.white, // rows white
                              ),
                              columnSpacing: 40,
                              headingRowHeight: 48,
                              dataRowHeight: 55,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    "Amount",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Date",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Status",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: payoutHistory.map((e) {
                                return DataRow(cells: [
                                  DataCell(
                                    Text(
                                      "₹${e['amount']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(formatDate(e['requested_at'])),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(e['status'])
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        e['status'].toUpperCase(),
                                        style: TextStyle(
                                          color: getStatusColor(e['status']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= DRAWER =================
  void openWithdrawDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        final width = MediaQuery.of(context).size.width;

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: Container(
              width: width < 800 ? width * 0.9 : width * 0.35,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: const Center(child: Text("Withdraw UI")),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    payoutController.dispose();
    searchController.dispose();
    super.dispose();
  }
}