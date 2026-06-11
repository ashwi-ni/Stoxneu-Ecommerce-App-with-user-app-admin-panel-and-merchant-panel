import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:stoxneu/Screens/Cart/Bloc/cart_state.dart';
import '../Address/Bloc/address_bloc.dart';
import '../Address/Bloc/address_event.dart';
import '../Address/Bloc/address_state.dart';
import '../Cart/Bloc/cart_bloc.dart';
import '../Cart/Bloc/cart_event.dart';
import '../Cart/model/cart_item_model.dart';
import '../Address/model/address_model.dart';
import '../Payment/payment_screen/PaymentScreen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(LoadAddresses());
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartItems;

    // Total calculations
    final double totalMrp = items.fold(
        0, (sum, item) => sum + (item.product.mrp * item.quantity));
    final double totalPrice = items.fold(
        0, (sum, item) => sum + (item.product.price * item.quantity));
    final double totalDiscount = totalMrp - totalPrice;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionTitle("Products"),
          ...items.map((item) => _buildProductRow(item)).toList(),

          const SizedBox(height: 16),
          _sectionTitle("Delivery Address"),

          BlocBuilder<AddressBloc, AddressState>(
            builder: (context, state) {
              if (state is AddressLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Widget> addressWidgets = [];

              if (state is AddressLoaded) {
                final addresses = state.addresses;

                addressWidgets.addAll(
                    addresses.map((addr) => _buildAddressCard(addr, state.selected))
                        .toList());
              }

              // Add new address button
              addressWidgets.add(
                _card(
                  ElevatedButton.icon(
                    onPressed: () => _showAddAddressSheet(),
                    icon: const Icon(Icons.add),
                    label: const Text("Add New Address"),
                  ),
                ),
              );

              // Error message
              if (state is AddressError) {
                addressWidgets.insert(
                  0,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: addressWidgets);
            },
          ),

          const SizedBox(height: 16),
          _sectionTitle("Price Details"),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded) {
                final totalMrp = state.items.fold(
                    0.0, (sum, item) => sum + (item.product.mrp * item.quantity));
                final totalPrice = state.items.fold(
                    0.0, (sum, item) => sum + (item.product.price * item.quantity));
                final totalDiscount = totalMrp - totalPrice;

                return _card(Column(
                  children: [
                    _priceRow("Total MRP", "₹${totalMrp.toStringAsFixed(2)}"),
                    _priceRow("Discount", "-₹${totalDiscount.toStringAsFixed(2)}", color: Colors.green),
                    const Divider(),
                    _priceRow("Order Total", "₹${totalPrice.toStringAsFixed(2)}", isBold: true),
                  ],
                ));
              }

              return const SizedBox();
            },
          ),
          const SizedBox(height: 20),
          //_continueToPaymentButton(context),


         // Continue to Payment
// Continue to Payment Button
          BlocBuilder<AddressBloc, AddressState>(
            builder: (context, addrState) {
              if (addrState is! AddressLoaded || addrState.selected == null) {
                return ElevatedButton(
                  onPressed: null,
                  child: const Text("Continue to Payment"),
                );
              }
              final itemsToCheckout = widget.cartItems;

              if (itemsToCheckout.isEmpty) {
                return ElevatedButton(
                  onPressed: null,
                  child: const Text("Continue to Payment"),
                );
              }

              final totalAmount = itemsToCheckout.fold(
                0.0,
                    (sum, item) => sum + item.product.price * item.quantity,
              );

              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        cartItems: itemsToCheckout,
                        address: addrState.selected!,
                        totalAmount: totalAmount,
                      ),
                    ),
                  );
                },
                child: const Text("Continue to Payment"),
              );
            },
          ),    ],
      ),
    );
  }

  // ---------------- UI Helpers ----------------

  // ---------------- Continue to Payment Button ----------------
  // Widget _continueToPaymentButton(BuildContext context) {
  //   final addressState = context.watch<AddressBloc>().state;
  //   final cartState = context.watch<CartBloc>().state;
  //
  //   // Check if either cart is empty or address is not selected
  //   if (cartState is! CartLoaded ||
  //       cartState.items.isEmpty ||
  //       addressState is! AddressLoaded ||
  //       addressState.selected == null) {
  //     return ElevatedButton(
  //       onPressed: null,
  //       child: const Text("Continue to Payment"),
  //     );
  //   }
  //
  //   final totalAmount = cartState.items.fold<double>(
  //       0.0, (sum, item) => sum + item.product.price * item.quantity);
  //
  //   return ElevatedButton(
  //     onPressed: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => PaymentScreen(
  //             cartItems: cartState.items,
  //             address: addressState.selected!,
  //             totalAmount: totalAmount,
  //           ),
  //         ),
  //       );
  //     },
  //     child: const Text("Continue to Payment"),
  //   );
  // }


  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );

  Widget _priceRow(String label, String value,
      {Color? color, bool isBold = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
    ),
    child: child,
  );

  Widget _buildProductRow(CartItem item) {
    final product = item.product;

    return _card(
      Row(
        children: [
          Image.network(
            product.fullImageUrl,
            width:90,
            height:90,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("₹${product.price} x ${item.quantity}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Subtotal: ₹${product.price * item.quantity}",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Decrease
                    InkWell(
                      onTap: () {
                        context.read<CartBloc>().add(DecreaseQuantity(item));
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, size: 18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(item.quantity.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    // Increase
                    InkWell(
                      onTap: () {
                        context.read<CartBloc>().add(IncreaseQuantity(item));
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ),
                    const Spacer(),
                    // Remove
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        context.read<CartBloc>().add(RemoveFromCart(item));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAddressCard(AddressModel addr, AddressModel? selected) {
    return _card(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<int>(
            value: addr.id,
            groupValue: selected?.id,
            onChanged: (_) {
              context.read<AddressBloc>().add(
                UpdateAddress(addr.copyWith(isDefault: true)),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addr.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(addr.fullAddress),
                Text("Phone: ${addr.phone}"),
                if (addr.isDefault)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text("DEFAULT",
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showAddAddressSheet(existing: addr),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete Address"),
                      content:
                      const Text("Are you sure you want to delete this address?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel")),
                        TextButton(
                          onPressed: () {
                            context
                                .read<AddressBloc>()
                                .add(DeleteAddress(addr.id));
                            Navigator.pop(context);
                          },
                          child: const Text("Delete",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAddressSheet({AddressModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final houseCtrl = TextEditingController(text: existing?.house);
    final roadCtrl = TextEditingController(text: existing?.road);
    final pinCtrl = TextEditingController(text: existing?.pincode);
    final landmarkCtrl = TextEditingController(text: existing?.landmark);

    String country = existing?.country ?? "";
    String state = existing?.state ?? "";
    String city = existing?.city ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AddressBloc>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existing == null ? "Add Address" : "Edit Address",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Name"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: "Phone"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                      controller: houseCtrl,
                      decoration: const InputDecoration(labelText: "House")),
                  TextFormField(
                      controller: roadCtrl,
                      decoration: const InputDecoration(labelText: "Road")),
                  TextFormField(
                      controller: pinCtrl,
                      decoration: const InputDecoration(labelText: "Pincode")),
                  const SizedBox(height: 8),
                  SelectState(
                    onCountryChanged: (c) => country = c,
                    onStateChanged: (s) => state = s,
                    onCityChanged: (c) => city = c,
                  ),
                  TextFormField(
                      controller: landmarkCtrl,
                      decoration: const InputDecoration(labelText: "Landmark")),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        final address = AddressModel(
                          id: existing?.id ?? 0,
                          name: nameCtrl.text,
                          phone: phoneCtrl.text,
                          house: houseCtrl.text,
                          road: roadCtrl.text,
                          city: city,
                          state: state,
                          country: country,
                          pincode: pinCtrl.text,
                          landmark: landmarkCtrl.text,
                          isDefault: true,
                        );

                        if (existing == null) {
                          context.read<AddressBloc>().add(AddAddress(address));
                        } else {
                          context.read<AddressBloc>().add(UpdateAddress(address));
                        }

                        Navigator.pop(context);
                      },
                      child: const Text("Save Address"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
