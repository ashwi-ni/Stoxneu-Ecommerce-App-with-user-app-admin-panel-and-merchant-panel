import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/MerchantOrderEvent.dart';
import 'bloc/MerchantOrderState.dart';
import 'bloc/merchantorder_bloc.dart';
import 'merchant_order_detail_screen.dart';
import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MerchantOrderListScreen extends StatefulWidget {
  const MerchantOrderListScreen({super.key});

  @override
  State<MerchantOrderListScreen> createState() =>
      _MerchantOrderListScreenState();
}

class _MerchantOrderListScreenState extends State<MerchantOrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();
  final List<String> tabs = [
    "All",
    "Pending",
    "Confirmed",
    "Shipped",
    "Delivered",
    "Returned",
    "Canceled",
  ];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: tabs.length, vsync: this);

    context.read<MerchantOrderBloc>().add(LoadMerchantOrders());
  }

  @override
  void dispose() {
    verticalController.dispose();
    horizontalController.dispose();
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Order> filterOrders(List<Order> orders, String status) {
    List<Order> filtered = orders;

    if (status.toLowerCase() != "all") {
      filtered = filtered.where((o) {
        final orderStatus = o.status.trim().toLowerCase();
        final tabStatus = status.trim().toLowerCase();

        if (tabStatus == "pending") {
          return orderStatus == "placed";
        }

        return orderStatus == tabStatus;
      }).toList();
    }

    if (searchController.text.isNotEmpty) {
      filtered = filtered.where((o) {
        return o.orderId.toLowerCase().contains(
          searchController.text.toLowerCase(),
        );
      }).toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "placed":
      case "pending":
        return Colors.orange;
      case "confirmed":
        return Colors.blue;
      case "shipped":
        return Colors.deepPurple;
      case "delivered":
        return Colors.green;
      case "returned":
        return Colors.purple;
      case "canceled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget buildStatusChip(String status) {
    final color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildPaymentChip(String paymentStatus) {
    final paid = paymentStatus.toLowerCase() == "paid";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: paid
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        paymentStatus.toUpperCase(),
        style: TextStyle(
          color: paid ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildActionButtons(Order order) {
    final context = this.context;
    return Row(
      children: [
        // =========================
        // VIEW DETAILS ICON
        // =========================
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            tooltip: "View Details",
            icon: const Icon(Icons.visibility_outlined),
            color: Colors.blue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<MerchantOrderBloc>(),
                    child: MerchantOrderDetailScreen(orderId: order.orderId),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 8),

        // =========================
        // PRINT INVOICE ICON
        // =========================
        Container(
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            tooltip: "Print Invoice",
            icon: const Icon(Icons.receipt_long_outlined),
            color: Colors.green,
            onPressed: () async {
              final repo = context.read<MerchantOrderBloc>().repository;

              final freshOrder = await repo.api.fetchOrderDetails(
                order.orderId,
              );

              printOrder(freshOrder);
            },
          ),
        ),
      ],
    );
  }

  Widget buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopSummary(List<Order> orders) {
    final pending = orders
        .where((e) => e.status.toLowerCase() == "placed")
        .length;

    final confirmed = orders
        .where((e) => e.status.toLowerCase() == "confirmed")
        .length;

    final shipped = orders
        .where((e) => e.status.toLowerCase() == "shipped")
        .length;

    final delivered = orders
        .where((e) => e.status.toLowerCase() == "delivered")
        .length;

    final canceled = orders
        .where((e) => e.status.toLowerCase() == "canceled")
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  buildSummaryCard(
                    title: "Pending",
                    value: pending.toString(),
                    color: Colors.orange,
                    icon: Icons.pending_actions,
                  ),
                  buildSummaryCard(
                    title: "Confirmed",
                    value: confirmed.toString(),
                    color: Colors.blue,
                    icon: Icons.check_circle,
                  ),
                ],
              ),
              Row(
                children: [
                  buildSummaryCard(
                    title: "Shipped",
                    value: shipped.toString(),
                    color: Colors.deepPurple,
                    icon: Icons.local_shipping,
                  ),
                  buildSummaryCard(
                    title: "Delivered",
                    value: delivered.toString(),
                    color: Colors.green,
                    icon: Icons.done_all,
                  ),
                  buildSummaryCard(
                    title: "Canceled",
                    value: canceled.toString(),
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            buildSummaryCard(
              title: "Pending",
              value: pending.toString(),
              color: Colors.orange,
              icon: Icons.pending_actions,
            ),
            buildSummaryCard(
              title: "Confirmed",
              value: confirmed.toString(),
              color: Colors.blue,
              icon: Icons.check_circle,
            ),
            buildSummaryCard(
              title: "Shipped",
              value: shipped.toString(),
              color: Colors.deepPurple,
              icon: Icons.local_shipping,
            ),
            buildSummaryCard(
              title: "Delivered",
              value: delivered.toString(),
              color: Colors.green,
              icon: Icons.done_all,
            ),
            buildSummaryCard(
              title: "Canceled",
              value: canceled.toString(),
              color: Colors.red,
              icon: Icons.cancel,
            ),
          ],
        );
      },
    );
  }

  Widget buildOrderCard(Order order) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<MerchantOrderBloc>(),
              child: MerchantOrderDetailScreen(orderId: order.orderId),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#${order.orderId}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.date.toLocal().toString().split(' ')[0],
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${order.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                buildPaymentChip(order.paymentStatus),
              ],
            ),
            const SizedBox(height: 18),
            buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget buildDesktopTable(List<Order> orders) {
    return Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: verticalController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          notificationPredicate: (_) => true,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: DataTable(
                columnSpacing: 170,
                dataRowHeight: 70,
                headingRowColor:
                WidgetStateProperty.all(
                    Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text("SL")),
                  DataColumn(label: Text("Order ID")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Amount")),
                  DataColumn(label: Text("Payment")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: orders.asMap().entries.map((entry) {
                  int index = entry.key;
                  final order = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text("${index + 1}")),

                      DataCell(
                        Text(
                          order.orderId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      DataCell(
                        Text(order.date
                            .toLocal()
                            .toString()
                            .split(' ')[0]),
                      ),

                      DataCell(
                        Text(
                          "₹${order.totalAmount.toStringAsFixed(2)}",
                        ),
                      ),

                      DataCell(
                        buildPaymentChip(
                            order.paymentStatus),
                      ),

                      DataCell(
                        buildStatusChip(order.status),
                      ),

                      DataCell(
                        buildActionButtons(order),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMobileOrders(List<Order> orders) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return buildOrderCard(orders[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MerchantOrderBloc, MerchantOrderState>(
      builder: (context, state) {
        if (state is MerchantOrderLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is MerchantOrderLoaded) {
          return Scaffold(
            backgroundColor: const Color(0xfff5f6fa),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              title: const Text(
                "Merchant Orders",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: tabs.map((tab) {
                  final count = filterOrders(state.orders, tab).length;

                  return Tab(text: "$tab ($count)");
                }).toList(),
              ),
            ),
            body: Column(
              children: [
                const SizedBox(height: 12),

                buildTopSummary(state.orders),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: "Search order ID...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: tabs.map((tab) {
                      final filteredOrders = filterOrders(state.orders, tab);

                      if (filteredOrders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 70,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No orders found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 900;

                          if (isDesktop) {
                            return buildDesktopTable(filteredOrders);
                          }

                          return buildMobileOrders(filteredOrders);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is MerchantOrderError) {
          return Scaffold(
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: Text("Something went wrong")),
        );
      },
    );
  }

  Future<void> printOrder(Order order) async {
    final pdf = pw.Document();

    final items = order.items ?? [];
    print("ITEMS: ${order.items}");
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "ORDER INVOICE",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Text("Order ID: ${order.orderId}"),
              pw.Text("Customer: ${order.address}"),

              pw.SizedBox(height: 20),

              pw.Text(
                "Items:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              items.isEmpty
                  ? pw.Text("No items found ❌")
                  : pw.Table.fromTextArray(
                      headers: ["Name", "Qty", "Price", "Total"],
                      data: items.map((item) {
                        return [
                          item.name,
                          item.quantity.toString(),
                          item.price.toString(),
                          (item.price * item.quantity).toString(),
                        ];
                      }).toList(),
                    ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
