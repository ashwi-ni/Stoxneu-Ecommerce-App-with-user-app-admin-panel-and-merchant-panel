import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stoxneu/Screens/Checkout/CheckoutScreen.dart';

import '../../Widgets/common_appbar.dart';
import '../Cart/Bloc/cart_bloc.dart';
import '../Cart/Bloc/cart_event.dart';
import '../Cart/model/cart_item_model.dart';
import 'model/product_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
  super.key,
  required this.product,

  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: CommonAppBar(title: "Product Detail"),

      /// 🧾 BODY
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Product Image
          Image.network(
            product.fullImageUrl,
            height: 300,
            headers: const {
              'ngrok-skip-browser-warning': 'true',
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade100,
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Product Name
          Text(
            product.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // Price + MRP + Discount
          Row(
            children: [
              Text(
                "₹${product.currentPrice.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              if (product.discountPercentage > 0)
                Text(
                  "₹${product.mrp.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              if (product.discountPercentage > 0)
                const SizedBox(width: 6),
              if (product.discountPercentage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.red,
                  child: Text(
                    "${product.discountPercentage}% OFF",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          const Text(
            "Product Details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(product.description ?? "No description available"),

          const SizedBox(height: 20),

          // Quantity Selector
          Row(
            children: [
              const Text(
                "Quantity:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              _quantityButton(Icons.remove, () {
                setState(() {
                  if (selectedQuantity > 1) selectedQuantity--;
                });
              }),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  selectedQuantity.toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _quantityButton(Icons.add, () {
                setState(() {
                  selectedQuantity++;
                });
              }),
            ],
          ),
        ],
      ),

      /// 🔘 BOTTOM BAR
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Add to Cart
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<CartBloc>().add(
                    AddToCart(widget.product, quantity: selectedQuantity),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to cart")),
                  );
                },
                child: const Text("ADD TO CART"),
              ),
            ),
            const SizedBox(width: 12),
            // Buy Now
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final cartItem = CartItem(
                    product: product,
                    quantity: selectedQuantity,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(cartItems: [cartItem]),
                    ),
                  );
                },
                child: const Text("BUY NOW"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quantity button helper
  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}