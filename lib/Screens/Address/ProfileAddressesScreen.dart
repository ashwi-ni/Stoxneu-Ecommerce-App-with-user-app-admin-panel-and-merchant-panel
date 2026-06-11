import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

import 'Bloc/address_bloc.dart';
import 'Bloc/address_event.dart';
import 'Bloc/address_state.dart';
import 'model/address_model.dart';

class ProfileAddressesScreen extends StatelessWidget {
  const ProfileAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: const Text(
          "My Addresses",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressSheet(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Address"),
      ),

      body: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading || state is AddressInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AddressError) {
            return Center(child: Text(state.message));
          }

          if (state is! AddressLoaded || state.addresses.isEmpty) {
            return const Center(
              child: Text("No addresses found"),
            );
          }

          final addresses = state.addresses;
          final selected = state.selected;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              return _addressCard(context, addresses[i], selected);
            },
          );
        },
      ),
    );
  }

  Widget _addressCard(
      BuildContext context,
      AddressModel addr,
      AddressModel? selected,
      ) {
    final isSelected = selected?.id == addr.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade200,
          width: isSelected ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<int>(
                  value: addr.id,
                  groupValue: selected?.id,
                  onChanged: (_) {
                    context
                        .read<AddressBloc>()
                        .add(UpdateAddress(addr.copyWith(isDefault: true)));
                  },
                ),

                Expanded(
                  child: Text(
                    addr.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),

                if (addr.isDefault)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "DEFAULT",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              addr.fullAddress,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "📞 ${addr.phone}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () =>
                      _showAddAddressSheet(context, existing: addr),
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      size: 20, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Address"),
                        content: const Text(
                            "Are you sure you want to delete this address?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              context
                                  .read<AddressBloc>()
                                  .add(DeleteAddress(addr.id));
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
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
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, {AddressModel? existing}) {
    final formKey = GlobalKey<FormState>();

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Text(
                    existing == null ? "Add Address" : "Edit Address",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _field("Name", nameCtrl),
                  _field("Phone", phoneCtrl),
                  _field("House No", houseCtrl),
                  _field("Road", roadCtrl),
                  _field("Pincode", pinCtrl),

                  const SizedBox(height: 10),

                  SelectState(
                    onCountryChanged: (c) => country = c,
                    onStateChanged: (s) => state = s,
                    onCityChanged: (c) => city = c,
                  ),

                  const SizedBox(height: 10),

                  _field("Landmark", landmarkCtrl),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;

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
        );
      },
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }
}
