import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:stoxneu/config/api_config.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailsScreen> createState() => _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  final String baseUrl = ApiConfig.baseUrl;
  final storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  Map<String, dynamic>? orderData;
  bool loading = true;
  String currentStatus = "Pending";

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      String? token = await storage.read(key: 'jwt');
      final response = await http.get(
        Uri.parse("$baseUrl/admin/orders/${widget.orderId}"),
        headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        setState(() {
          orderData = jsonDecode(response.body);
          currentStatus = orderData!['status'] ?? "Pending";
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
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (orderData == null) return const Scaffold(body: Center(child: Text("Order not found")));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: Text("Order ID: #${widget.orderId}", style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildMainColumn()),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildSideColumn()),
            ])
                : Column(children: [
              _buildMainColumn(),
              const SizedBox(height: 20),
              _buildSideColumn(),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildMainColumn() {
    final items = orderData!['items'] as List? ?? [];

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Text("Order Setup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    _statusBadge(currentStatus),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No items details found"),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // 🔥 MOVED INSIDE HERE: Now 'index' is defined
                    final item = items[index];
                    final String rawImg = item['image_url'] ?? "";

                    final String fullImgUrl = rawImg.startsWith('http')
                        ? rawImg
                        : "$baseUrl$rawImg";

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fullImgUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shopping_cart, color: Colors.grey),
                        ),
                      ),
                      title: Text(item['name'] ?? "Unknown Product",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text("₹${item['price']} x ${item['quantity']}"),
                      trailing: Text(
                        "₹${(double.parse(item['price'].toString()) * item['quantity'])}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    );
                  },
                ),
              _buildPricingSection(),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))),
      child: Column(
        children: [
          _priceRow("Sub Total", "₹${orderData!['sub_total'] ?? orderData!['total_amount']}"),
          _priceRow("Tax", "₹${orderData!['tax'] ?? '0'}"),
          _priceRow("Shipping", "₹${orderData!['shipping'] ?? '0'}"),
          const Divider(height: 25),
          _priceRow("Total Amount", "₹${orderData!['total_amount']}", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSideColumn() {
    // Use the 'address' key directly from the server response
    final String displayAddress = orderData!['address'] ?? "No address found in database";

    return Column(
      children: [
        _sideCard("Order Status", Column(
          children: [
            DropdownButtonFormField<String>(
              value: currentStatus,
              items: ['Placed', 'Delivered', 'Cancelled', 'Processing']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => currentStatus = val!),
            ),
            const SizedBox(height: 10),
            Text("Placed on: ${orderData!['created_at']}", style: const TextStyle(fontSize: 11)),
          ],
        )),
        const SizedBox(height: 20),
        _sideCard("Payment Info", Column(
          children: [
            _dataRow("Method", orderData!['payment_method'] ?? "N/A"),
            _dataRow("Status", orderData!['payment_status'] ?? "N/A"),
            _dataRow("Refund", orderData!['refund_status'] ?? "NONE"),
          ],
        )),
        const SizedBox(height: 20),
        _sideCard("Shipping Address", Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.location_on, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text("Delivery Details", style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            // Display the full address string here
            Text(
              displayAddress,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
            ),
          ],
        )),
      ],
    );
  }


  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sideCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Divider(height: 25),
        child,
      ]),
    );
  }

  Widget _priceRow(String label, String val, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
        Text(val, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isTotal ? Colors.blue : Colors.black)),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
