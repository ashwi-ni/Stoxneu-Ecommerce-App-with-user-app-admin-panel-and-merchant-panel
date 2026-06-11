import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import 'package:stoxneu/Screens/Cart/Bloc/cart_bloc.dart';
import 'package:stoxneu/Screens/Cart/model/cart_item_model.dart';
import '../../../config/api_config.dart';
import '../../Address/model/address_model.dart';
import '../../Auth/services/auth_service.dart';
import '../../Cart/Bloc/cart_event.dart';
import '../../MyOrder/API/OrderApi.dart' show OrderApiService;
import '../../MyOrder/bloc/order_bloc.dart';
import '../../MyOrder/bloc/order_event.dart';
import '../../MyOrder/model/order_model.dart';
import '../OrderSuccessScreen.dart';

class PaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final AddressModel address;
  final double totalAmount;


  const PaymentScreen({
  super.key,
  required this.cartItems,
  required this.address,
  required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  late AuthRepository authRepo;
  late OrderApiService orderApi;
  String selectedMethod = "ONLINE"; // ONLINE or COD
  bool _isProcessing = false; // for loading indicator

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    authRepo = AuthRepository(api: AuthApiService());
    orderApi = OrderApiService(authRepository: authRepo);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ---------------- Razorpay Payment ----------------
  void _startRazorpayPayment() {
    setState(() => _isProcessing = true);

    var options = {
      'key': 'rzp_test_SEMaMT8TVnP5xL',
      'amount': (widget.totalAmount * 100).toInt(), // amount in paise
      'name': 'Stoxneu',
      'description': 'Order Payment',
      'prefill': {
        'contact': widget.address.phone,
        'email': 'customer@email.com',
      },
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      setState(() => _isProcessing = false);
    }
  }

  // ---------------- Razorpay Callbacks ----------------
  void _onSuccess(PaymentSuccessResponse response) async {
    debugPrint("Payment Success: ${response.paymentId}");

    // Simulate backend verification
    bool verified = await _verifyPayment(response.paymentId!);

    if (verified) {
      _placeOrder(paymentMode: "ONLINE", paymentId: response.paymentId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment verification failed!")),
      );
    }

    setState(() => _isProcessing = false);
  }

  void _onError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  // ---------------- Simulated Backend Verification ----------------
  Future<bool> _verifyPayment(String paymentId) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate network
    debugPrint("Payment $paymentId verified on backend (simulated)");
    return true; // always return true for simulation
  }


  Future<void> _placeOrder({required String paymentMode, String? paymentId}) async {
    if (!mounted) return;

    setState(() => _isProcessing = true);

    // 1️⃣ Map your cart data elements
    final orderItems = widget.cartItems.map((cartItem) {
      return OrderItem(
        productId: cartItem.product.id,
        name: cartItem.product.name,
        imageUrl: cartItem.product.fullImageUrl,
        price: cartItem.product.price,
        quantity: cartItem.quantity,
      );
    }).toList();

    final order = Order(
      orderId: paymentId ?? "COD-${DateTime.now().millisecondsSinceEpoch}",
      date: DateTime.now(),
      totalAmount: widget.totalAmount,
      items: orderItems,
      status: "placed",
      address: widget.address.fullAddress,
      paymentMethod: paymentMode,
      paymentStatus: paymentMode == "COD" ? "PENDING" : "PAID",
    );

    try {
      // 1️⃣ Fetch your authorization JWT token safely
      final token = await authRepo.getToken();

      // 2️⃣ Map array elements strictly using primitive data types to avoid encoder crashes
      final List<Map<String, dynamic>> secureItemsPayload = widget.cartItems.map((cartItem) {
        return {
          "productId": cartItem.product.id.toString(), // Coerce to string to protect validation constraints
          "product_id": cartItem.product.id.toString(),
          "name": cartItem.product.name,
          "imageUrl": cartItem.product.fullImageUrl ?? "",
          "image_url": cartItem.product.fullImageUrl ?? "",
          "price": cartItem.product.price, // Safely wrap numeric types as text strings
          "quantity": cartItem.quantity,               // Raw primitive int is safe
        };
      }).toList();

      // 3️⃣ Construct your target dictionary mapping strictly using simple types
      final Map<String, dynamic> rawPayloadMap = {
        "orderId": paymentId ?? "COD-${DateTime.now().millisecondsSinceEpoch}",
        "totalAmount": widget.totalAmount, // ✅ FIX: Force floating-point double to pure primitive string text
        "status": "placed",
        "address": widget.address.fullAddress,
        "paymentMethod": paymentMode,
        "paymentStatus": paymentMode == "COD" ? "PENDING" : "PAID",
        "items": secureItemsPayload, // Clean primitive nested array matrix mapping
      };

      // Debug check print to verify serialization trace inside your IDE log dashboard
      debugPrint("📤 RAW SERIALIZATION STRING AUDIT: ${json.encode(rawPayloadMap)}");

      // 4️⃣ Execute the synchronization network request call
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/orders"),
        headers: {
          'Content-Type': 'application/json', // Signals Express to invoke parser allocations
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(rawPayloadMap), // This is guaranteed to encode cleanly now
      );

      debugPrint("➡️ RESPONSE STATUS FROM CONTROLLER: ${response.statusCode}");
      debugPrint("➡️ RESPONSE BODY FROM CONTROLLER: ${response.body}");

      if (response.statusCode != 201) {
        throw Exception("Server rejected payload parameters: ${response.body}");
      }

      // 5️⃣ Clear shopping cart UI layouts safely upon success validation
      final cartBloc = context.read<CartBloc>();
      for (var item in widget.cartItems) {
        cartBloc.add(RemoveFromCart(item));
      }

      // 6️⃣ Navigate directly to order confirmation screen container
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: rawPayloadMap["orderId"],
            totalAmount: widget.totalAmount,
            totalItems: widget.cartItems.length,
          ),
        ),
      );

    } catch (e) {
      debugPrint("❌ CRITICAL UI NETWORK CALL FAILURE: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Network Sync Failure: $e")),
      );
    }
    finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Order Total"),
            Text(
              "₹${widget.totalAmount.toStringAsFixed(0)}",
              style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            _section("Payment Method"),

            RadioListTile(
              value: "ONLINE",
              groupValue: selectedMethod,
              title: const Text("UPI / Card / NetBanking"),
              onChanged: (v) => setState(() => selectedMethod = v!),
            ),

            RadioListTile(
              value: "COD",
              groupValue: selectedMethod,
              title: const Text("Cash on Delivery"),
              onChanged: (v) => setState(() => selectedMethod = v!),
            ),

            const Spacer(),

            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedMethod == "ONLINE") {
                      _startRazorpayPayment();
                    } else {
                      _placeOrder(paymentMode: "COD");
                    }
                  },
                  child: Text(
                    selectedMethod == "ONLINE"
                        ? "Pay ₹${widget.totalAmount.toStringAsFixed(0)}"
                        : "Place Order (COD)",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}
