
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'bloc/MerchantOrderEvent.dart';
import 'bloc/merchantorder_bloc.dart';

class MerchantOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const MerchantOrderDetailScreen({
  super.key,
  required this.orderId,
  });

  @override
  State<MerchantOrderDetailScreen> createState() =>
      _MerchantOrderDetailScreenState();
}

class _MerchantOrderDetailScreenState
    extends State<MerchantOrderDetailScreen> {
  String? currentStatus;

  final List<String> allowedStatuses = const [
    "pending",
    "confirmed",
    "shipped",
    "delivered"
  ];

  String normalize(String? value) {
    final v = value?.toLowerCase().trim() ?? "pending";
    return allowedStatuses.contains(v) ? v : "pending";
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "delivered":
        return Colors.green;
      case "confirmed":
        return Colors.blue;
      case "shipped":
        return Colors.deepPurple;
      case "canceled":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }



  Widget buildItemsTable(Order order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 150,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
          dataRowHeight: 70,

          columns: const [
            DataColumn(label: Text("SL")),
            DataColumn(label: Text("Product")),
            DataColumn(label: Text("Product Id")),
            DataColumn(label: Text("Qty")),
            DataColumn(label: Text("Price")),
            DataColumn(label: Text("Total")),
          ],

          rows: order.items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;

            final total = item.price * item.quantity;

            return DataRow(
              cells: [
                DataCell(Text(index.toString())),

                // 🔥 PRODUCT IMAGE + NAME
                  DataCell(
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:Image.network(
                            item.fullImageUrl,
                            headers: const {'ngrok-skip-browser-warning': 'true'},
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported, size: 30, color: Colors.grey);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // DETAILS (you can extend later)
                DataCell(Text(" ${item.productId ?? '-'}")),

                DataCell(Text(item.quantity.toString())),

                DataCell(Text("₹${item.price}")),

                DataCell(
                  Text(
                    "₹$total",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildRightPanel(Order order) {
    final safeStatus = currentStatus ?? normalize(order.status);

    return Column(
      children: [
        _card(
          "Payment",
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Status: ${order.paymentStatus}"),
              Text("Method: ${order.paymentMethod}"),
              Text("Amount: ₹${order.totalAmount}"),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _card(
          "Order & Shipping Info",
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<String>(
                value: safeStatus,

                items: allowedStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    currentStatus = value;
                  });

                  updateOrderStatus(context, order.orderId, value);
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: order.paymentStatus.toLowerCase() == "paid",
                onChanged: (v) {},
                title: const Text("Payment Status"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _card(
          "Customer Address",
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.address),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MerchantOrderBloc>().repository;

    return FutureBuilder<Order>(
      future: repo.api.fetchOrderDetails(widget.orderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final order = snapshot.data!;

        currentStatus ??= normalize(order.status);

        return Scaffold(
          backgroundColor: const Color(0xfff5f6fa),

          appBar: AppBar(
            title: Text("Order Details"),
          ),

          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // LEFT SIDE (TABLE + HEADER)
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [

                      // 🔥 MOVED APPBAR CONTENT HERE
                      buildOrderHeaderInsideTable(context, order),

                      const SizedBox(height: 16),

                      buildItemsTable(order),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // RIGHT SIDE
                Expanded(
                  flex: 3,
                  child: buildRightPanel(order),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildOrderHeaderInsideTable(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // LEFT SIDE: ORDER INFO
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order #${order.orderId}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text("Customer: ${order.address}"),
            ],
          ),

          // RIGHT SIDE: STATUS + ACTIONS
          Row(
            children: [

              // STATUS DROPDOWN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: DropdownButton<String>(
                  value: currentStatus ?? order.status,

                  items: const [
                    DropdownMenuItem(value: "pending", child: Text("Pending")),
                    DropdownMenuItem(value: "confirmed", child: Text("Confirmed")),
                    DropdownMenuItem(value: "shipped", child: Text("Shipped")),
                    DropdownMenuItem(value: "delivered", child: Text("Delivered")),
                  ],

                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      currentStatus = value;
                    });

                    updateOrderStatus(context, order.orderId, value);
                  },
                ),
              ),

              const SizedBox(width: 10),

              // PRINT BUTTON
              ElevatedButton.icon(
    onPressed: () {
    printOrder(order);
    },
    icon: const Icon(Icons.print),
    label: const Text("Print"),
    ),
              ]),

            ],


    ));}

  Future<void> printOrder(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("ORDER INVOICE",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 10),

              pw.Text("Order ID: ${order.orderId}"),
              pw.Text("Customer: ${order.address}"),
              pw.Text("Payment: ${order.paymentMethod}"),
              pw.Text("Status: ${order.status}"),

              pw.SizedBox(height: 20),

              pw.Text("Items:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

              pw.Table.fromTextArray(
                headers: ["Name", "Qty", "Price", "Total"],
                data: order.items.map((item) {
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
void updateOrderStatus(
    BuildContext context,
    String orderId,
    String status,
    ) {
  final bloc = context.read<MerchantOrderBloc>();

  switch (status) {
    case "confirmed":
      bloc.add(ConfirmMerchantOrder(orderId));
      break;

    case "shipped":
      bloc.add(MarkMerchantOrderShipped(orderId));
      break;

    case "delivered":
      bloc.add(MarkMerchantOrderDelivered(orderId));
      break;

    case "canceled":
      bloc.add(CancelMerchantOrder(orderId));
      break;

    default:
      break;
  }
}