import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stoxneu/Screens/Products/ProductDetailsScreen.dart';
import '../Checkout/CheckoutScreen.dart';
import 'Bloc/cart_bloc.dart';
import 'Bloc/cart_event.dart';
import 'Bloc/cart_state.dart';
import 'model/cart_item_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dispatch LoadCartFromApi when entering screen
    context.read<CartBloc>().add(LoadCartFromApi());

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) return const Center(child: CircularProgressIndicator());
          if (state is CartError) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          if (state is CartLoaded) {
            if (state.items.isEmpty) return const Center(child: Text("Your cart is empty"));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.items.length,
              itemBuilder: (_, index) {
                final item = state.items[index];
                return ListTile(
                  leading: Image.network(
                    item.product.fullImageUrl,
                    width: 60,
                    height:60,
                    fit: BoxFit.cover,
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
                  title: Text(item.product.name),
                  subtitle: Text("₹${item.product.price} x ${item.quantity}"),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}