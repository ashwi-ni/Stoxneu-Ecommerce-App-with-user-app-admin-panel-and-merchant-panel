import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import '../../ApiService/product_api.dart';
import 'package:stoxneu/Screens/Products/model/product_model.dart';

class MerchantSaleScreen extends StatefulWidget {
  final String saleType; // "Flash Deal" or "Clearance Sale"

  const MerchantSaleScreen({super.key, required this.saleType});

  @override
  State<MerchantSaleScreen> createState() => _MerchantSaleScreenState();
}

class _MerchantSaleScreenState extends State<MerchantSaleScreen> {
  late final MerchantProductApi productApi;
  Map<int, TextEditingController> individualDiscounts = {};
  // State variables
  bool isActiveOffer = true;
  String discountType = "Flat Discount";
  String activeTime = "Always";
  DateTimeRange? selectedDateRange;

  final _discountController = TextEditingController(text: "10");
  final _tableSearchController = TextEditingController();

  List<Product> allMerchantProducts = []; // From API
  List<Product> selectedForSale = [];     // In the Table
  bool isLoading = false;
  bool isSaving = false;



  @override
  void initState() {
    super.initState();
    final authRepo = context.read<AuthRepository>();
    productApi = MerchantProductApi(authRepository: authRepo);
    _loadInitialProducts();
  }
  Future<void> _handleSaveSale() async {
    if (selectedForSale.isEmpty) {
      _showSnackBar("Please add products first", Colors.orange);
      return;
    }
    try {
      final payload = {
        "sale_type": widget.saleType == "Flash Deal" ? "flash_deal" : "clearance",
        "discount_type": discountType, // Send if it's Flat or Product Wise
        "start_time": selectedDateRange?.start.toIso8601String() ?? DateTime.now().toIso8601String(),
        "end_time": selectedDateRange?.end.toIso8601String() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        "products": selectedForSale.map((p) {

          // Use individual discount if Product Wise, otherwise use Global
          double pDiscount = discountType == "Product Wise"
              ? double.tryParse(individualDiscounts[p.id]?.text ?? "0") ?? 0
              : double.tryParse(_discountController.text) ?? 0;

          double calculatedPrice = p.price - (p.price * (pDiscount / 100));

          return {
            "product_id": p.id,
            "flash_percentage": pDiscount.toString(), // Individual percentage
            "flash_price": calculatedPrice.toStringAsFixed(2),
            "status": p.isActive == 1 ? 'active' : 'inactive',
          };
        }).toList(),
      };

      await productApi.storeFlashDeals(payload);
      _showSnackBar("Sale Saved Successfully!", Colors.green);
    } catch (e) {
      _showSnackBar("Save failed: $e", Colors.red);
    } finally {
      setState(() => isSaving = false);
    }
  }



  Future<void> _loadInitialProducts() async {
    setState(() => isLoading = true);
    try {
      final result = await productApi.fetchMerchantProducts();
      setState(() => allMerchantProducts = result);
    } catch (e) {
      _showSnackBar("Error loading inventory: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(widget.saleType, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white, elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTypeSelectorHeader(),
            const SizedBox(height: 20),
            _buildSetupLogicCard(),
            const SizedBox(height: 20),
            _buildProductListCard(),
          ],
        ),
      ),
    );
  }

  // 1. Header with Dropdown & Toggle
  Widget _buildTypeSelectorHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text("Offer Category: ", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: widget.saleType,
                underline: const SizedBox(),
                items: ["Flash Deal", "Clearance Sale"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) {
                  final route = val == "Flash Deal" ? "flash" : "clearance";
                  context.go('/merchant-sale/$route');
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text("Active Offer"),
              Switch(
                value: isActiveOffer,
                activeColor: Colors.blue,
                onChanged: (v) => setState(() => isActiveOffer = v),
              ),
            ],
          )
        ],
      ),
    );
  }

  // 2. Setup Logic Card
  Widget _buildSetupLogicCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Setup Offer Logics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(child: _buildRadioGroup("Discount Type", ["Flat Discount", "Product Wise"], discountType, (v) => setState(() => discountType = v!))),
              const SizedBox(width: 20),
              Expanded(child: _buildRadioGroup("Active Time", ["Always", "Specific Time"], activeTime, (v) => setState(() => activeTime = v!))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: _buildTextField(
                    "Global Discount (%)",
                    _discountController,
                    enabled: discountType == "Flat Discount", // Disable if Product Wise
                  )
              ),

              const SizedBox(width: 20),
              Expanded(
                child: activeTime == "Specific Time"
                    ? _buildDateRangePicker()
                    : const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: // Inside _buildSetupLogicCard
            ElevatedButton(
              onPressed: _handleSaveSale, // New function below
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Settings", style: TextStyle(color: Colors.white)),
            ),

          )
        ],
      ),
    );
  }

  // 3. Product List Card with Search & Modal
  Widget _buildProductListCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Product List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _tableSearchController,
                      decoration: const InputDecoration(hintText: "Search items in list...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddProductDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Add Product", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
        columns: const [
          DataColumn(label: Text("Product")),
          DataColumn(label: Text("Price")),
          DataColumn(label: Text("Discount %")), // Changed to be interactive
          DataColumn(label: Text("Offer Price")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Action")),
        ],
        rows: selectedForSale.map((p) {
          // Initialize controller for this product if not exists
          individualDiscounts.putIfAbsent(p.id, () => TextEditingController(text: _discountController.text));

          double currentDiscount = discountType == "Product Wise"
              ? (double.tryParse(individualDiscounts[p.id]!.text) ?? 0)
              : (double.tryParse(_discountController.text) ?? 0);

          double offerPrice = p.price - (p.price * (currentDiscount / 100));

          return DataRow(cells: [
            DataCell(Text(p.name)),
            DataCell(Text("₹${p.price}")),

            // --- EDITABLE DISCOUNT CELL ---
            DataCell(
              discountType == "Product Wise"
                  ? SizedBox(
                width: 60,
                child: TextField(
                  controller: individualDiscounts[p.id],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (v) => setState(() {}), // Refresh Offer Price cell
                ),
              )
                  : Text("${_discountController.text}%"),
            ),

            DataCell(Text("₹${offerPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),

            DataCell(Switch(
                value: p.isActive == 1,
                onChanged: (v) => setState(() => p.isActive = v ? 1 : 0)
            )),

            DataCell(IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => selectedForSale.remove(p))
            )),
          ]);
        }).toList(),
      ),
    );
  }


  // --- ADD PRODUCT MODAL (SEARCH + SELECT ALL) ---
  void _showAddProductDialog() {
    List<int> modalSelectedIds = [];

    // ✅ ONLY APPROVED PRODUCTS SHOULD BE SHOWN
    List<Product> modalFiltered = allMerchantProducts
        .where((p) => p.requestStatus == "approved" && p.isActive == 1)
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(15),
            color: const Color(0xffF1F4F9),
            child: const Text("Add Product to Sale"),
          ),
          content: SizedBox(
            width: 550,
            height: 500,
            child: Column(
              children: [
                // 🔍 SEARCH BOX
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Search inventory...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (q) {
                    setModalState(() {
                      modalFiltered = allMerchantProducts
                          .where((p) =>
                      p.requestStatus == "approved" &&
                          p.isActive == 1 &&
                          p.name.toLowerCase().contains(q.toLowerCase()))
                          .toList();
                    });
                  },
                ),

                const SizedBox(height: 10),

                // ✅ SELECT ALL
                CheckboxListTile(
                  title: const Text(
                    "Select All",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: modalSelectedIds.isNotEmpty &&
                      modalSelectedIds.length == modalFiltered.length,
                  onChanged: (v) {
                    setModalState(() {
                      modalSelectedIds = v == true
                          ? modalFiltered.map((e) => e.id).toList()
                          : [];
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const Divider(),

                // 📦 PRODUCT LIST
                Expanded(
                  child: modalFiltered.isEmpty
                      ? const Center(
                    child: Text(
                      "No approved products available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: modalFiltered.length,
                    itemBuilder: (context, i) {
                      final p = modalFiltered[i];

                      return CheckboxListTile(
                        value: modalSelectedIds.contains(p.id),
                        title: Text(p.name),
                        subtitle: Text("Price: ₹${p.price}"),
                        onChanged: (v) {
                          setModalState(() {
                            if (v == true) {
                              modalSelectedIds.add(p.id);
                            } else {
                              modalSelectedIds.remove(p.id);
                            }
                          });
                        },
                        controlAffinity:
                        ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🎯 ACTIONS
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  for (var id in modalSelectedIds) {
                    final product = allMerchantProducts.firstWhere(
                          (e) => e.id == id,
                    );

                    // extra safety check
                    if (product.requestStatus == "approved" &&
                        product.isActive == 1) {
                      if (!selectedForSale.contains(product)) {
                        selectedForSale.add(product);
                      }
                    }
                  }
                });

                Navigator.pop(context);
              },
              child: const Text("Add Selected"),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  // --- HELPERS ---
  Widget _buildDateRangePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime(2100)
        );
        if (picked != null) setState(() => selectedDateRange = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8)
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 20),
            const SizedBox(width: 10),
            Text(selectedDateRange == null
                ? "Select Dates"
                : "${DateFormat('dd MMM').format(selectedDateRange!.start)} - ${DateFormat('dd MMM').format(selectedDateRange!.end)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioGroup(String title, List<String> opts, String current, Function(String?) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
            children: opts.map((o) => Row(
                children: [
                  Radio<String>(value: o, groupValue: current, onChanged: onChange),
                  Text(o, style: const TextStyle(fontSize: 12))
                ]
            )).toList()
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
            filled: !enabled,
          ),
          onChanged: (v) => setState(() {}), // Update table if global discount changes
        ),
      ],
    );
  }
}
