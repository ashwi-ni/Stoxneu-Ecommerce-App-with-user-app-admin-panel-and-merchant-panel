import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../../../config/api_config.dart';

class AddProductScreen extends StatefulWidget {
  final String token;

  const AddProductScreen({super.key, required this.token});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final mrpController = TextEditingController();
  final skuController = TextEditingController(); // NEW
  final stockController = TextEditingController(text: "0"); // NEW
  final lowStockController = TextEditingController(text: "5"); // NEW

  int? selectedCategory;
  int? selectedSubCategory;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];
  XFile? imageFile;
  Uint8List? imageBytes;
  bool isSaving = false;

  final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final res = await http.get(Uri.parse("$baseUrl/categories"), headers: {"ngrok-skip-browser-warning": "true"});
    if (res.statusCode == 200) {
      setState(() => categories = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
  }

  Future<void> loadSubCategories(int catId) async {
    final res = await http.get(Uri.parse("$baseUrl/categories/$catId/subcategories"), headers: {"ngrok-skip-browser-warning": "true"});
    if (res.statusCode == 200) {
      setState(() {
        subCategories = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        selectedSubCategory = null;
      });
    }
  }

  void generateSKU() {
    final String prefix = nameController.text.length >= 3
        ? nameController.text.substring(0, 3).toUpperCase()
        : "PROD";
    final String random = (1000 + (DateTime.now().millisecond % 9000)).toString();
    setState(() => skuController.text = "$prefix-$random");
  }

  Future<void> addProduct() async {
    print("🚀 Add Product button clicked");
    if (isSaving) return;
    if (selectedCategory == null || selectedSubCategory == null) {
      print("❌ Validation failed");
      print("Category: $selectedCategory");
      print("SubCategory: $selectedSubCategory");

      _showSnackBar("Please select category & subcategory", Colors.orange);
      return;
    }

    if (imageFile == null) {
      print("Image: $imageFile");
      _showSnackBar("Please upload image", Colors.orange);
      return;
    }

    setState(() => isSaving = true);
    try {
      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/merchant/products"));
      request.headers.addAll({"Authorization": "Bearer ${widget.token}", "ngrok-skip-browser-warning": "true"});

      request.fields.addAll({
        "name": nameController.text.trim(),
        "description": descriptionController.text.trim(),
        "price": priceController.text.trim(),
        "mrp": mrpController.text.trim(),
        "sku": skuController.text.trim(),
        "stock_quantity": stockController.text.trim(),
        "low_stock_threshold": lowStockController.text.trim(),
        "category_id": selectedCategory.toString(),
        "sub_category_id": selectedSubCategory.toString(),
      });

      if (kIsWeb && imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes("image_url", imageBytes!, filename: imageFile!.name));
      } else if (!kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath("image_url", imageFile!.path));
      }

      final response = await http.Response.fromStream(await request.send());
      print("📡 Status Code: ${response.statusCode}");
      print("📡 Response Body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Product created successfully");
        _showSnackBar("Product added successfully!", Colors.green);

        await Future.delayed(const Duration(milliseconds: 300));
        print("🔙 Navigating back to product screen");
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }else {
        _showSnackBar("Error: ${response.body}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Request failed: $e", Colors.red);
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text("Add New Product", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0.5, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildGeneralSection()),
                const SizedBox(width: 25),
                Expanded(flex: 1, child: _buildMediaAndCategorySection()),
              ],
            ),
            const SizedBox(height: 25),
            _buildPricingAndStockSection(),
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _containerCard(
      title: "General Information",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Product Name"),
          _textField(nameController, "Ex: Luxury Watch"),
          const SizedBox(height: 20),
          _label("Product Description"),
          _textField(descriptionController, "Type details here...", maxLines: 6),
        ],
      ),
    );
  }

  Widget _buildMediaAndCategorySection() {
    return Column(
      children: [
        _containerCard(
          title: "Product Image",
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    if (kIsWeb) imageBytes = await picked.readAsBytes();
                    setState(() => imageFile = picked);
                  }
                },
                child: Container(
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
                  child: imageFile != null
                      ? (kIsWeb ? Image.memory(imageBytes!, fit: BoxFit.cover) : Image.file(File(imageFile!.path), fit: BoxFit.cover))
                      : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey), Text("Upload Image", style: TextStyle(color: Colors.grey))])),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _containerCard(
          title: "Organization",
          child: Column(
            children: [
              _dropdown(categories, "Select Category", selectedCategory, (val) {
                setState(() { selectedCategory = val; subCategories = []; });
                loadSubCategories(val!);
              }),
              const SizedBox(height: 15),
              _dropdown(subCategories, "Select Sub Category", selectedSubCategory, (val) => setState(() => selectedSubCategory = val)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingAndStockSection() {
    return _containerCard(
      title: "Pricing & Stock",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _columnField("Unit Price (₹)", priceController)),
              const SizedBox(width: 15),
              Expanded(child: _columnField("MRP (₹)", mrpController)),
              const SizedBox(width: 15),
              Expanded(child: _columnField("SKU Code", skuController, isSKU: true)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _columnField("Current Stock", stockController)),
              const SizedBox(width: 15),
              Expanded(child: _columnField("Low Stock Warning", lowStockController)),
              const Spacer(flex: 1),
            ],
          ),
        ],
      ),
    );
  }

  // --- REUSABLE UI HELPERS ---
  Widget _containerCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(height: 30),
        child,
      ]),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1, bool isSKU = false}) {
    return TextField(
      controller: controller, maxLines: maxLines,
      decoration: InputDecoration(
          hintText: hint,
          suffixIcon: isSKU ? IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: generateSKU) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white
      ),
    );
  }

  Widget _columnField(String label, TextEditingController controller, {bool isSKU = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
      const SizedBox(height: 8),
      _textField(controller, "0", isSKU: isSKU),
    ]);
  }

  Widget _dropdown(List<Map<String, dynamic>> items, String hint, int? value, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      value: value, items: items.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['name']))).toList(),
      onChanged: onChanged, decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder()),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)));

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)), child: const Text("Cancel")),
        const SizedBox(width: 15),
        ElevatedButton(
          onPressed: addProduct,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
          child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Add Product", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
