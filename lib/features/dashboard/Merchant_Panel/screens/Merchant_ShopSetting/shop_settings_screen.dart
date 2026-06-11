import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import '../../../../../config/api_config.dart';
import '../Merchant_Payment/helper/wallet_service.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  bool isStoreActive = true;
  int selectedTab = 0;
  bool _isUpdating = false;
  bool showPaymentDrawer = false;
  late WalletService walletService;
  List<Map<String, dynamic>> paymentMethods = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();

  String selectedMethod = "UPI";

final String baseUrl = ApiConfig.baseUrl;
  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();

    walletService = WalletService(
      baseUrl: baseUrl,
      authRepository: context.read<AuthRepository>(),
    );

    loadPayments();
  }

  Future<void> loadPayments() async {
    await walletService.fetchSavedPaymentMethods();

    setState(() {
      paymentMethods = walletService.savedPaymentMethods.map((e) {
        return {
          "type": e["type"],
          "details": e["details"],
          "active": true,
        };
      }).toList();
    });
  }
  // ---------------- API ----------------
  Future<Map<String, dynamic>> fetchFullMerchantData() async {
    final token = context.read<AuthRepository>().token;

    final response = await http.get(
      Uri.parse('$baseUrl/merchant/shop'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"name": "No Shop", "contact": "N/A", "address": "N/A"};
    }
  }

  Future<void> toggleShopStatus(bool newValue) async {
    setState(() => _isUpdating = true);

    final token = context.read<AuthRepository>().token;

    try {
      await http.patch(
        Uri.parse('$baseUrl/merchant/shop/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_active': newValue}),
      );

      setState(() => isStoreActive = newValue);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Shop Info",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchFullMerchantData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(10),
                    child: _buildTopTabs(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildTabContent(data),
                    ),
                  ),
                ],
              ),

              // BACKDROP
              if (showPaymentDrawer)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => showPaymentDrawer = false),
                    child:
                    Container(color: Colors.black.withOpacity(0.3)),
                  ),
                ),

              // DRAWER
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                right: showPaymentDrawer ? 0 : -420,
                top: 0,
                bottom: 0,
                child: _paymentDrawer(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- TABS ----------------
  Widget _buildTabContent(Map<String, dynamic> data) {
    if (selectedTab == 0) return _shopTab(data);
    return _paymentTab();

  }

  Widget _shopTab(Map<String, dynamic> data) {
    return Column(
      children: [
        _card(
          "Store Availability",
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Your store is live"),
              Switch(
                value: isStoreActive,
                onChanged: _isUpdating
                    ? null
                    : (val) => toggleShopStatus(val),
              ),
            ],
          ),
        ),
        _card(
          "Shop Details",
          child: Column(
            children: [
              _row("Name", data['name']),
              _row("Contact", data['contact']),
              _row("Address", data['address']),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- PAYMENT TAB ----------------
  Widget _paymentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "In this page you can add, edit or delete your payment information for withdraw your earning amount",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,color:Colors.black),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "Payment Method List",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 15),

        /// HEADER (SAME UI STYLE)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),

            ElevatedButton.icon(
              onPressed: () {
                _clearForm();
                setState(() => showPaymentDrawer = true);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add payment info"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56BE),
              ),
            )
          ],
        ),

        const SizedBox(height: 15),

        /// TABLE (UI SAME AS YOUR ORIGINAL)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DataTable(
              columnSpacing: 40,
              headingRowColor:
              WidgetStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text("SL")),
                DataColumn(label: Text("Method Name")),
                DataColumn(label: Text("Withdraw Method")),
                DataColumn(label: Text("Payment Info")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Action")),
              ],
              rows: paymentMethods.isEmpty
                  ? [
                const DataRow(cells: [
                  DataCell(Text("-")),
                  DataCell(Text("No Data")),
                  DataCell(Text("-")),
                  DataCell(Text("-")),
                  DataCell(Text("-")),
                  DataCell(Text("-")),
                ])
              ]
                  : List.generate(paymentMethods.length, (index) {
                final m = paymentMethods[index];
                final d = m["details"];

                return DataRow(cells: [
                  DataCell(Text("${index + 1}")),

                  /// NAME
                  DataCell(Row(
                    children: [
                      Text(d["name"] ?? m["type"]),
                      if (index == 0)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("Default",
                              style: TextStyle(fontSize: 10)),
                        )
                    ],
                  )),

                  /// TYPE
                  DataCell(Text(m["type"] ?? "")),

                  /// INFO
                  DataCell(Text(
                    d["upi_id"] ??
                        d["account_number"] ??
                        d["card_number"] ??
                        "-",
                  )),

                  /// STATUS
                  DataCell(Switch(
                    value: m["active"] ?? true,
                    onChanged: (val) {
                      setState(() {
                        m["active"] = val;
                      });
                    },
                    activeColor: const Color(0xFF1A56BE),
                  )),

                  /// ACTION (EDIT)
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editPayment(m["type"], d),
                    ),
                  ),
                ]);
              }),
            ),
          ),
        )
      ],
    );
  }

  // ---------------- DRAWER ----------------
  Widget _paymentDrawer() {
    return Container(
      width: 400,
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            title: const Text("Add Payment Info",
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  setState(() => showPaymentDrawer = false),
            ),
          ),

          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _input("Method Name", nameController),
                  const SizedBox(height: 10),

                  DropdownButtonFormField(
                    value: selectedMethod,
                    items: ["UPI", "Bank", "Card"]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedMethod = val.toString()),
                  ),

                  const SizedBox(height: 10),

                  if (selectedMethod == "UPI")
                    _input("UPI ID", accountController),

                  if (selectedMethod == "Bank") ...[
                    _input("Account Number", accountController),
                    const SizedBox(height: 10),
                    _input("IFSC", ifscController),
                  ],

                  if (selectedMethod == "Card") ...[
                    _input("Card Holder Name", nameController),
                    const SizedBox(height: 10),
                    _input("Card Number", accountController),
                  ],
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Reset"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56BE),
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ---------------- SAVE ----------------
  // ---------------- SAVE PAYMENT (API) ----------------
  Future<void> _savePayment() async {
    Map<String, dynamic> details = {};

    if (selectedMethod == "UPI") {
      details = {
        "upi_id": accountController.text,
        "name": nameController.text,
      };
    }

    if (selectedMethod == "Bank") {
      details = {
        "account_number": accountController.text,
        "ifsc": ifscController.text,
        "holder": nameController.text,
      };
    }

    if (selectedMethod == "Card") {
      details = {
        "card_number": accountController.text,
        "holder": nameController.text,
      };
    }

    try {
      await walletService.savePaymentMethod(selectedMethod, details);

      await loadPayments();

      setState(() {
        showPaymentDrawer = false;
      });

      nameController.clear();
      accountController.clear();
      ifscController.clear();
    } catch (e) {
      print("SAVE ERROR: $e");
    }
  }

  // ---------------- EDIT PAYMENT ----------------
  void _editPayment(String type, Map<String, dynamic> details) {
    selectedMethod = type;

    nameController.text = details["name"] ?? details["holder"] ?? "";
    accountController.text = details["upi_id"] ??
        details["account_number"] ??
        details["card_number"] ??
        "";
    ifscController.text = details["ifsc"] ?? "";

    setState(() {
      showPaymentDrawer = true;
    });
  }


  // ---------------- HELPERS ----------------

  void _clearForm() {
    nameController.clear();
    accountController.clear();
    ifscController.clear();
    selectedMethod = "UPI";
  }



  Widget _buildTopTabs() {
    return Row(
      children: [
        _tab("Shop", 0),
        _tab("Payment", 1),
       // _tab("KYC", 2),
      ],
    );
  }
  Widget _tab(String t, int i) {
    return GestureDetector(
      onTap: () => setState(() => selectedTab = i),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selectedTab == i
              ? const Color(0xFF1A56BE)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t,
            style: TextStyle(
                color:
                selectedTab == i ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _input(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

// Widget _kycTab(Map<String, dynamic> data) {
//   return _card(
//     "Verification",
//     child: Column(
//       children: [
//         _row("PAN", data['pan_number']),
//         _row("Aadhaar", data['aadhaar_number']),
//       ],
//     ),
//   );
// }

Widget _card(String title, {required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(title,
              style:
              const TextStyle(fontWeight: FontWeight.bold)),
        if (title.isNotEmpty) const Divider(),
        child
      ],
    ),
  );
}

Widget _row(String l, dynamic v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(l),
        Text(v?.toString() ?? "N/A",
            style:
            const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}


String maskCard(String card) {
  if (card.length < 4) return card;
  return "**** **** **** ${card.substring(card.length - 4)}";
}
