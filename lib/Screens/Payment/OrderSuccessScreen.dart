import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:stoxneu/Screens/MyOrder/OrderDetailsScreen.dart';
import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';
import '../BottomNav_Screen/mainscreen.dart';
import '../MyOrder/myorder_Screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final int totalItems;

  const OrderSuccessScreen({
  super.key,
  required this.orderId,
  required this.totalAmount,
  required this.totalItems,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text("Order Success"),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Your order has been placed successfully!",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "Order ID: ${widget.orderId}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  "Total Items: ${widget.totalItems}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  "Total Paid: ₹${widget.totalAmount.toStringAsFixed(0)}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyOrdersScreen(),
                          ),
                        );
                      },
                      child: const Text("Track Order"),
                    ),

                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () {
                        // Clear previous screens and go home
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MainScreen()),
                              (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Colors.blue),
                      ),
                      child: const Text("Go Home"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Confetti animation
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.pink,
              Colors.purple
            ],
            numberOfParticles: 30,
            gravity: 0.3,
            emissionFrequency: 0.05,
          ),
        ],
      ),
    );
  }
}
