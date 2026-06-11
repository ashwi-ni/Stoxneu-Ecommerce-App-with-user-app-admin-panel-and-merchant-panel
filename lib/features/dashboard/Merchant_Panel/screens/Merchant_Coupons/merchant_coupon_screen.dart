import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:intl/intl.dart';


import '../../../../../Screens/Auth/repository/auth_repository.dart';
import '../../ApiService/merchant_couponApiService.dart';
import 'merchant_editCoupon_screen.dart';

class MerchantCouponScreen extends StatefulWidget {
  const MerchantCouponScreen({super.key});

  @override
  State<MerchantCouponScreen> createState() => _MerchantCouponScreenState();
}

class _MerchantCouponScreenState extends State<MerchantCouponScreen> {
  // Service
  late CouponApiService couponApiService;

  // Controllers
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _limitController = TextEditingController();
  final _discountController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _startDateController = TextEditingController();
  final _expireDateController = TextEditingController();
final _searchController = TextEditingController();
  List<dynamic> filteredCoupons = []; // This will hold the search results

  // State
  String? selectedCouponType = "Discount on Purchase";
  String? selectedCustomer = "All Customer";
  String selectedDiscountType = "Amount";
  bool isSaving = false;
  List<dynamic> coupons = [];
  bool isLoadingList = true;
  @override
  void initState() {
    super.initState();
    // ✅ Initialize Service
    final authRepo = context.read<AuthRepository>();
    couponApiService = CouponApiService(authRepository: authRepo);

    _loadCoupons();
  }

  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = coupons;
    } else {
      results = coupons
          .where((coupon) =>
      coupon['title'].toLowerCase().contains(enteredKeyword.toLowerCase()) ||
          coupon['code'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredCoupons = results;
    });
  }

  void _loadCoupons() async {
    setState(() => isLoadingList = true);
    try {
      final result = await couponApiService.fetchMerchantCoupons();
      setState(() {
        coupons = result;
        filteredCoupons = result;
        isLoadingList = false;
      });
    } catch (e) {
      setState(() => isLoadingList = false);
      _showSnackBar("Error loading list: $e", Colors.red);
    }
  }

  Future<void> _submitCoupon() async {
    if (_titleController.text.isEmpty || _codeController.text.isEmpty ||
        _discountController.text.isEmpty) {
      _showSnackBar("Please fill title, code, and discount", Colors.orange);
      return;
    }

    setState(() => isSaving = true);
    try {
      // ✅ Call your Service
      await couponApiService.createCoupon({
        "title": _titleController.text.trim(),
        "code": _codeController.text.trim(),
        "coupon_type": selectedCouponType,
        "customer": selectedCustomer,
        "limit_per_user": _limitController.text.trim(),
        "discount_type": selectedDiscountType,
        "discount_amount": _discountController.text.trim(),
        "min_purchase": _minPurchaseController.text.trim(),
        "start_date": _startDateController.text,
        "expire_date": _expireDateController.text,
      });

      _showSnackBar("Coupon Saved!", Colors.green);
      _resetForm();
      _loadCoupons(); // Refresh table
    } catch (e) {
      _showSnackBar(e.toString().replaceAll("Exception: ", ""), Colors.red);
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _codeController.clear();
    _limitController.clear();
    _discountController.clear();
    _minPurchaseController.clear();
    _startDateController.clear();
    _expireDateController.clear();
    setState(() {
      selectedCustomer = "All Customer";
      selectedDiscountType = "Amount";
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  // 🪄 1. THE MISSING GENERATE CODE METHOD
  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    setState(() {
      _codeController.text = List.generate(
          10, (index) => chars[Random().nextInt(chars.length)])
          .join();
    });
  }

  // 📅 2. THE MISSING DATE PICKER METHOD
  Future<void> _selectDate(BuildContext context,
      TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Merchant can't select past dates
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _confirmDeleteCoupon(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Coupon"),
        content: const Text("Are you sure you want to delete this coupon?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await couponApiService.deleteCoupon(id);
                _loadCoupons(); // Refresh the list
                _showSnackBar("Deleted successfully", Colors.green);
              } catch (e) {
                _showSnackBar("Delete failed", Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: const Text("Coupon Management",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildCouponFormCard(),
            const SizedBox(height: 30),
            _buildCouponTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponFormCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Create Coupon",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 40),

          /// Row 1
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                    "Coupon Type",
                    ["Discount on Purchase", "Free Delivery", "First Order"],
                        (val) => setState(() => selectedCouponType = val)),
              ),
              const SizedBox(width: 20),
              Expanded(
                  child:
                  _buildTextField("Coupon Title", _titleController, "Title")),
            ],
          ),
          const SizedBox(height: 20),

          /// Row 2
          Row(
            children: [
              Expanded(
                child: _buildTextField("Coupon Code", _codeController,
                    "Ex: ABC123",
                    actionLabel: "Generate", onAction: _generateCode),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDropdownField(
                    "Customer",
                    ["All Customer", "New Customer", "VIP"],
                        (val) => setState(() => selectedCustomer = val),
                    initialValue: selectedCustomer),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// Row 3
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      "Limit Per User", _limitController, "Ex: 10")),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDropdownField(
                    "Discount Type",
                    ["Amount", "Percentage"],
                        (val) =>
                        setState(() => selectedDiscountType = val!),
                    initialValue: selectedDiscountType),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// Row 4
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      "Discount Amount", _discountController, "Ex: 500")),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildTextField("Minimum Purchase",
                      _minPurchaseController, "Ex: 100")),
            ],
          ),
          const SizedBox(height: 20),

          /// Row 5
          Row(
            children: [
              Expanded(
                  child:
                  _buildDateField("Start Date", _startDateController)),
              const SizedBox(width: 20),
              Expanded(
                  child:
                  _buildDateField("Expire Date", _expireDateController)),
            ],
          ),
          const SizedBox(height: 30),

          /// Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _resetForm,
                child: const Text("Reset"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isSaving ? null : _submitCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1455AC),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                ),
                child: isSaving
                    ? const SizedBox(width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text(
                    "Save Coupon", style: TextStyle(color: Colors.white)),
              ),


            ],
          )
        ],
      ),
    );
  }

  /// TEXT FIELD
  Widget _buildTextField(String label, TextEditingController controller,
      String hint,
      {String? actionLabel, VoidCallback? onAction}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            if (actionLabel != null)
              InkWell(
                onTap: onAction,
                child: Text(actionLabel,
                    style: const TextStyle(
                        color: Colors.blue, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  /// DROPDOWN
  Widget _buildDropdownField(String label, List<String> items,
      Function(String?) onChanged,
      {String? initialValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: initialValue,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  /// DATE FIELD
  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(context, controller),
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.calendar_today),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }


  Widget _buildCouponTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Coupon List (${coupons.length})",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              // Search field for the table
              SizedBox(
                width: 250,
                height: 40,
                child:
                TextField(
                  controller: _searchController,
                  onChanged: (value) => _runFilter(value),
                  // decoration: InputDecoration(
                  //   hintText: "Search by title or code...",
                  //   prefixIcon: Icon(Icons.search),
                    decoration: InputDecoration(
                      hintText: "Search by title or code",
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          isLoadingList
              ? const Center(child: Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : coupons.isEmpty
              ? const Center(child: Padding(
              padding: EdgeInsets.all(20), child: Text("No coupons found")))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 150,
              dataRowHeight: 70,
              headingRowHeight: 50,
              headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
              columns: const [
                DataColumn(label: Text("SL")),
                DataColumn(label: Text("Coupon Info")),
                DataColumn(label: Text("Coupon Type")),
                DataColumn(label: Text("Min Purchase")),
                DataColumn(label: Text("Max Discount")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Action")),
              ],
              // ⬇️ CHANGE THIS LINE from 'coupons' to 'filteredCoupons'
              rows: filteredCoupons
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final c = entry.value;

                return DataRow(cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c['title'] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Code: ${c['code']}",
                          style: const TextStyle(color: Colors.blue, fontSize: 12)),
                    ],
                  )),
                  DataCell(Text(c['coupon_type'] ?? "")),
                  DataCell(Text("₹${c['min_purchase']}")),
                  DataCell(Text(c['discount_type'] == 'Percentage'
                      ? "${c['discount_amount']}%"
                      : "₹${c['discount_amount']}")),
                  DataCell(Switch(
                    // Ensure your API returns status as 1/0 or true/false
                    value: c['status'] == 1 || c['status'] == true,
                    activeColor: Colors.green,
                    onChanged: (bool newValue) async {
                      try {
                        await couponApiService.toggleCouponStatus(c['id'], newValue ? 1 : 0);
                        _loadCoupons(); // Refresh UI
                        _showSnackBar("Status updated", Colors.green);
                      } catch (e) {
                        _showSnackBar("Toggle failed", Colors.red);
                      }
                    },
                  )),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _showCouponDetailsDialog(context, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditCouponScreen(coupon: c)),
                          );
                          if (result == true) _loadCoupons();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => _confirmDeleteCoupon(c['id']),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),

          ),
        ],
      ),
    );
  }

  void _showCouponDetailsDialog(BuildContext context, Map coupon) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            height: 320,
            child: Row(
              children: [
                /// LEFT
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${coupon['discount_amount']}% discount",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text("Code: ${coupon['code']}"),
                        const SizedBox(height: 15),

                        _infoRow("Min Purchase",
                            "₹${coupon['min_purchase'] ?? 0}"),
                        _infoRow("Max Discount",
                            "₹${coupon['max_discount'] ?? 0}"),
                        _infoRow(
                            "Start Date", coupon['start_date'] ?? ""),
                        _infoRow(
                            "Expire Date", coupon['expire_date'] ?? ""),
                      ],
                    ),
                  ),
                ),
                /// RIGHT
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0xFF174A8B),
                    child: Center(
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            coupon['discount_type'] == "Percentage"
                                ? "${coupon['discount_amount']}% off"
                                : "₹${coupon['discount_amount']} off",
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold,color:Color(0xFF174A8B)),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$title :",
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
