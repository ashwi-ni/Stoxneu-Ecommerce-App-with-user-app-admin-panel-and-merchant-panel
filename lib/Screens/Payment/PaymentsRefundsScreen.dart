import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../MyOrder/bloc/order_bloc.dart';
import '../MyOrder/bloc/order_event.dart';
import '../MyOrder/bloc/order_state.dart';
import '../MyOrder/model/order_model.dart';

class PaymentsRefundsScreen extends StatelessWidget {
  const PaymentsRefundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Payments & Refunds"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderError) {
            return Center(
              child: Text(
                "Error: ${state.message}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is OrderLoaded) {
            final onlineOrders = state.orders
                .where((o) => o.paymentMethod == "ONLINE")
                .toList();

            if (onlineOrders.isEmpty) {
              return const _EmptyPaymentsView();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: onlineOrders.length,
              itemBuilder: (context, index) {
                final order = onlineOrders[index];
                return _orderCard(context, order);
              },
            );
          }

          return const Center(child: Text("Unexpected state"));
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Order ID: ${order.orderId}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // TOTAL AMOUNT
          Text(
            "Amount: ₹${order.totalAmount.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),

          // ALL PRODUCTS WITH IMAGE + NAME
          if (order.items.isNotEmpty)
            Column(
              children: order.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),

          // STATUS TIMELINE
          Row(
            children: ["Processing", "Shipped", "Delivered"].map((status) {
              final isActive = order.status == status;
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // PAYMENT & REFUND STATUS + BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusChip("Payment", order.paymentStatus,
                  color: order.paymentStatus == "PAID" ? Colors.green : Colors.orange),
              _statusChip("Refund", order.refundStatus, color: _refundColor(order.refundStatus)),
              // REPLACE THE EXISTING BUTTON IN _orderCard WITH THIS:
              if (_canRequestRefund(order))
                ElevatedButton(
                  onPressed: () => _showRefundReasonDialog(context, order), // Call dialog
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("Request Refund",
                      style: TextStyle(fontSize: 14, color: Colors.white)),
                ),

            ],
          ),
        ],
      ),
    );
  }
  Widget _statusChip(String label, String value, {Color color = Colors.grey}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text("$label: $value",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }

  bool _canRequestRefund(Order order) =>
      order.paymentStatus == "PAID" &&
          order.refundStatus == "NONE" &&
          order.status == "Delivered";

  Color _refundColor(String status) {
    switch (status) {
      case "REQUESTED":
        return Colors.orange;
      case "COMPLETED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showRefundReasonDialog(BuildContext context, Order order) {
    final TextEditingController reasonController = TextEditingController();
    int? selectedProductId; // Track which product is selected

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Request Refund"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select item to refund:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // --- Item Selection List ---
                ...order.items.map((item) => RadioListTile<int>(
                  contentPadding: EdgeInsets.zero,
                  value: item.productId,
                  groupValue: selectedProductId,
                  title: Text(item.name, style: const TextStyle(fontSize: 13)),
                  secondary: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      item.imageUrl,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                    ),
                  ),
                  onChanged: (val) => setState(() => selectedProductId = val),
                )),

                const Divider(),
                const SizedBox(height: 10),
                const Text("Reason for refund:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // --- Reason Input ---
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "E.g., Product is damaged or wrong size",
                    hintStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                final reason = reasonController.text.trim();

                // 1. Validation: Must select a product
                if (selectedProductId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select an item to refund")),
                  );
                  return;
                }

                // 2. Validation: Must provide a reason
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a reason")),
                  );
                  return;
                }

                // 3. Dispatch to BLoC
                context.read<OrderBloc>().add(
                  RequestRefund(
                    order.orderId,
                    reason: reason,
                    productId: selectedProductId!,
                  ),
                );

                Navigator.pop(context); // Close dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Refund request submitted successfully")),
                );
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }


}

class _EmptyPaymentsView extends StatelessWidget {
  const _EmptyPaymentsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("No Payments Yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Your online payments and refunds will appear here.",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}