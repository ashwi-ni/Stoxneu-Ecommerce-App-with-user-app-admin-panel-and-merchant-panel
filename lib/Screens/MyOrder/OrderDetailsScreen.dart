import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/order_bloc.dart';
import 'bloc/order_event.dart';
import 'model/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order, int? orderId});

  // Only allow refund if PAID, not refunded yet, and delivered
  bool _canRequestRefund(Order order) =>
      order.paymentStatus == "PAID" &&
          order.refundStatus == "NONE" &&
          order.status.toLowerCase() == "delivered";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Order Details"),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.textTheme.titleLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductsSection(items: order.items, orderId: order.orderId, date: order.date),
            const SizedBox(height: 12),
            _OrderStatusTimeline(status: order.status),
            const SizedBox(height: 12),
            _PaymentRefundSection(
              order: order,
              onRefund: _canRequestRefund(order)
                  ? () => _showRefundBottomSheet(context, order)
                  : null,
            ),
            const SizedBox(height: 12),
            _AddressSection(address: order.address),
            const SizedBox(height: 12),
            _PriceDetails(total: order.totalAmount),
            const SizedBox(height: 20),
            _HelpSection(),
          ],
        ),
      ),
    );
  }

  void _showRefundBottomSheet(BuildContext context, Order order) {
    final TextEditingController reasonController = TextEditingController();
    int? selectedProductId; // 🔥 Track which product is selected

    final List<String> quickReasons = [
      "Item damaged",
      "Wrong size/color",
      "Quality not as expected",
      "Received wrong item",
      "Other"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery
                      .of(context)
                      .viewInsets
                      .bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Request Refund",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 🔥 ITEM SELECTION SECTION
                    const Text("Select item to refund:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    ...order.items.map((item) =>
                        RadioListTile<int>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name, style: const TextStyle(
                              fontSize: 13)),
                          secondary: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(item.imageUrl, width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image, size: 35)),
                          ),
                          value: item.productId,
                          // Ensure your model uses productId
                          groupValue: selectedProductId,
                          onChanged: (val) {
                            setModalState(() => selectedProductId = val);
                          },
                        )).toList(),

                    const Divider(),
                    const SizedBox(height: 10),
                    const Text("Select a reason:",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      children: quickReasons.map((r) {
                        final isSelected = reasonController.text == r;
                        return ChoiceChip(
                          label: Text(r),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() => reasonController.text = r);
                          },
                          selectedColor: Colors.orange.withOpacity(0.2),
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.orange.shade900
                                  : Colors.black,
                              fontSize: 12
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Tell us more...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final reason = reasonController.text.trim();

                          if (selectedProductId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(
                                  "Please select an item to refund")),
                            );
                            return;
                          }

                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(
                                  "Please select or enter a reason")),
                            );
                            return;
                          }

                          context.read<OrderBloc>().add(
                            RequestRefund(
                              order.orderId,
                              reason: reason,
                              productId: selectedProductId!,
                            ),
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(
                                "Refund request submitted")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text("Submit", style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Refund request sent successfully!"),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

}

/// ===================== PRODUCTS =====================
class _ProductsSection extends StatelessWidget {
  final List<OrderItem> items;
  final String orderId;
  final DateTime date;
  const _ProductsSection({required this.items, required this.orderId, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Items Ordered", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: theme.disabledColor.withOpacity(0.2),
                      child: Icon(Icons.image, color: theme.disabledColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text("₹${item.price}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text("Order ID: $orderId", style: theme.textTheme.bodySmall),
                      Text("Ordered on: ${date.day}/${date.month}/${date.year}", style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// ===================== ORDER STATUS =====================
class _OrderStatusTimeline extends StatelessWidget {
  final String status;
  const _OrderStatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = ["Processing", "Shipped", "Delivered"];
    final currentIndex = statuses.indexOf(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Status", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: statuses.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isActive = idx <= currentIndex;
              return Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isActive ? theme.colorScheme.primary : theme.disabledColor.withOpacity(0.3),
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(s, style: theme.textTheme.bodySmall?.copyWith(color: isActive ? theme.colorScheme.primary : theme.disabledColor)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(statuses.length - 1, (i) {
              final active = i < currentIndex;
              return Expanded(
                child: Container(
                  height: 2,
                  color: active ? theme.colorScheme.primary : theme.disabledColor.withOpacity(0.3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// ===================== ADDRESS =====================
class _AddressSection extends StatelessWidget {
  final String address;
  const _AddressSection({required this.address});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Delivery Address", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(address, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// ===================== PAYMENT & REFUND =====================
class _PaymentRefundSection extends StatelessWidget {
  final Order order;
  final VoidCallback? onRefund;
  const _PaymentRefundSection({required this.order, this.onRefund});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Payment & Refund", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Payment Method", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(order.paymentMethod, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Payment Status", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(order.paymentStatus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: order.paymentStatus == "PAID" ? Colors.green : Colors.orange,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          if (order.refundStatus == "NONE")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRefund,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text("Request Refund", style: TextStyle(fontSize: 14)),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Refund Status", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(order.refundStatus,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
        ],
      ),
    );
  }
}

/// ===================== PRICE DETAILS =====================
class _PriceDetails extends StatelessWidget {
  final double total;
  const _PriceDetails({required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Price Details", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _row(context, "Item Total", total),
          _row(context, "Delivery Charges", 0),
          const Divider(),
          _row(context, "Total Amount", total, bold: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String title, double value, {bool bold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: theme.textTheme.bodyMedium),
        Text("₹$value", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}

/// ===================== HELP SECTION =====================
class _HelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(theme),
      child: Row(children: [
        Icon(Icons.support_agent, color: theme.colorScheme.secondary),
        const SizedBox(width: 10),
        Text("Need Help with this order?", style: theme.textTheme.bodyMedium),
      ]),
    );
  }
}

/// ===================== CARD DECORATION =====================
BoxDecoration _cardDecoration(ThemeData theme) => BoxDecoration(
  color: theme.cardColor,
  borderRadius: BorderRadius.circular(10),
  boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
);