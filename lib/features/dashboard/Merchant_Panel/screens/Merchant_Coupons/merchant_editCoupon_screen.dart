import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import '../../ApiService/merchant_couponApiService.dart';

class EditCouponScreen extends StatefulWidget {
  final Map coupon;

  const EditCouponScreen({super.key, required this.coupon});

  @override
  State<EditCouponScreen> createState() => _EditCouponScreenState();
}

class _EditCouponScreenState extends State<EditCouponScreen> {
  late TextEditingController _titleController;
  late TextEditingController _codeController;
  late TextEditingController _limitController;
  late TextEditingController _discountController;
  late TextEditingController _minPurchaseController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _startDateController;
  late TextEditingController _expireDateController;

  String? selectedCouponType;
  String? selectedCustomer;
  String? selectedDiscountType;
  bool isSaving = false;
  @override
  void initState() {
    super.initState();
    final c = widget.coupon;

    _titleController = TextEditingController(text: c['title'] ?? '');
    _codeController = TextEditingController(text: c['code'] ?? '');
    _limitController =
        TextEditingController(text: "${c['limit_per_user'] ?? ''}");
    _discountController =
        TextEditingController(text: "${c['discount_amount'] ?? ''}");
    _minPurchaseController =
        TextEditingController(text: "${c['min_purchase'] ?? ''}");
    _maxDiscountController =
        TextEditingController(text: "${c['max_discount'] ?? ''}");
    _startDateController =
        TextEditingController(text: c['start_date'] ?? '');
    _expireDateController =
        TextEditingController(text: c['expire_date'] ?? '');

    selectedCouponType = c['coupon_type'];
    selectedCustomer = c['customer'];
    selectedDiscountType = c['discount_type'];
  }

  /// GENERATE CODE
  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    setState(() {
      _codeController.text = List.generate(
          10, (index) => chars[Random().nextInt(chars.length)])
          .join();
    });
  }

  /// DATE PICKER
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

  Future<void> _updateCoupon() async {
    final authRepo = context.read<AuthRepository>();
    final couponApiService = CouponApiService(authRepository: authRepo);
    String formatDate(String input) {
      try {
        final parsed = DateFormat('dd-MM-yyyy').parse(input);
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (e) {
        return input; // fallback (avoid crash)
      }
    }
    // 1. Show loading
    setState(() => isSaving = true);

    try {
      // 2. Prepare the data map matching your backend keys
      final Map<String, dynamic> updateData = {
        "title": _titleController.text.trim(),
        "code": _codeController.text.trim(),
        "coupon_type": selectedCouponType,
        "customer": selectedCustomer,
        "limit_per_user": int.tryParse(_limitController.text) ?? 0,
        "discount_type": selectedDiscountType,
        "discount_amount": double.tryParse(_discountController.text) ?? 0,
        "min_purchase": double.tryParse(_minPurchaseController.text) ?? 0,
        "max_discount": double.tryParse(_maxDiscountController.text) ?? 0,
        "start_date": formatDate(_startDateController.text),
        "expire_date": formatDate(_expireDateController.text),
      };

      // 3. Call your API (Ensure you have this method in your service)
      await couponApiService.updateCoupon(widget.coupon['id'], updateData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coupon updated successfully"), backgroundColor: Colors.green),
      );

      // 4. Return true so the list screen knows it needs to refresh
      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: const Text("Update Coupon",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              /// ROW 1
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                        "Coupon Type",
                        ["Discount on Purchase", "Free Delivery"],
                        selectedCouponType, (val) {
                      setState(() => selectedCouponType = val);
                    }),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                      child:
                      _buildTextField("Title", _titleController)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTextField(
                        "Code", _codeController,
                        actionLabel: "Generate",
                        onAction: _generateCode),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ROW 2
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                        "Customer",
                        ["All Customer", "New Customer"],
                        selectedCustomer, (val) {
                      setState(() => selectedCustomer = val);
                    }),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                      child: _buildTextField(
                          "Limit/User", _limitController)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildDropdownField(
                        "Discount Type",
                        ["Amount", "Percentage"],
                        selectedDiscountType, (val) {
                      setState(() => selectedDiscountType = val);
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ROW 3
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          "Discount", _discountController)),
                  const SizedBox(width: 20),
                  Expanded(
                      child: _buildTextField(
                          "Min Purchase", _minPurchaseController)),
                  const SizedBox(width: 20),
                  Expanded(
                      child: _buildTextField(
                          "Max Discount", _maxDiscountController)),
                ],
              ),

              const SizedBox(height: 20),

              /// ROW 4
              Row(
                children: [
                  Expanded(
                      child: _buildDateField(
                          "Start Date", _startDateController)),
                  const SizedBox(width: 20),
                  Expanded(
                      child: _buildDateField(
                          "Expire Date", _expireDateController)),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 30),

              /// BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isSaving ? null : _updateCoupon,
                    child: isSaving
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Update Coupon"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// TEXT FIELD
  Widget _buildTextField(String label, TextEditingController controller,
      {String? actionLabel, VoidCallback? onAction}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
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
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  /// DROPDOWN
  Widget _buildDropdownField(String label, List<String> items,
      String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
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
  Widget _buildDateField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
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

}