import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:stoxneu/Screens/Products/model/product_model.dart';

import '../../../../../Screens/Auth/repository/auth_repository.dart';
import '../../../../../Screens/Products/product_api.dart';


class MerchantProductDetailScreen extends StatefulWidget {
  final Product product;
  const MerchantProductDetailScreen({required this.product, super.key});

@override
State<MerchantProductDetailScreen> createState() => _MerchantProductDetailScreenState();
}

class _MerchantProductDetailScreenState extends State<MerchantProductDetailScreen> {
  late Product p;
  late final ProductApi productApi;
  @override
  void initState() {
    super.initState();
    p = widget.product;

  }
  @override
  Widget build(BuildContext context) {
    //final p = widget.product;
    final bool isLowStock = p.stockQuantity <= p.lowStockThreshold;

    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text("Product Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP HEADER ACTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(p.requestStatus),
                ElevatedButton.icon(
                    onPressed: () async {
    final result = await context.push(
    '/merchant-editproduct',
    extra: p,
    );

    if (result == true) {
      await reloadProduct();
    }
                    },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit Product"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // MAIN CONTENT ROW (Image + Summary)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Section
                Expanded(
                  flex: 1,
                  child: _infoCard(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        p.fullImageUrl,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported, size: 30, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // 2. Info Summary
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _infoCard(
                        title: "General Information",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _detailRow("Category", "Main Category"), // Add p.categoryName if available
                            _detailRow("SKU", p.sku.toString()), // Replace with p.sku if available
                            _detailRow("Total Stock", "${p.stockQuantity}", valueColor: isLowStock ? Colors.red : Colors.green),
                            _detailRow("Status", p.isActive == 1 ? "Active" : "Inactive"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // PRICING & STOCK TABLE
            _infoCard(
              title: "Pricing & Stock",
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _priceColumn("Purchase Price", "₹${p.mrp}"),
                  _priceColumn("Selling Price", "₹${p.price}", isBlue: true),
                  _priceColumn("Tax", "0%"),
                  _priceColumn("Discount", "${p.discountPercentage}%"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DESCRIPTION SECTION
            _infoCard(
              title: "Product Description",
              child: Text(
                p.description ?? "No description provided.",
                style: const TextStyle(height: 1.6, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _infoCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
          ],
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(": ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _priceColumn(String label, String value, {bool isBlue = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isBlue ? Colors.blue : Colors.black
        )),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
  Future<void> reloadProduct() async {
    final updated = await productApi.getProductById(p.id);

    setState(() {
      p = updated;
    });
  }
}
