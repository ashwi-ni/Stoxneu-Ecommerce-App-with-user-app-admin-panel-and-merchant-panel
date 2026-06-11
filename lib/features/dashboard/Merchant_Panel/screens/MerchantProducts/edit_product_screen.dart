import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this to check role
import 'package:stoxneu/Screens/Products/model/product_model.dart';

import '../../../../../config/api_config.dart';

class EditProductScreen extends StatefulWidget {
  final String token;
  final Product product;

  const EditProductScreen({super.key, required this.token, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final mrpController = TextEditingController();
  final stockController = TextEditingController();
  final lowStockController = TextEditingController();
  final skuController = TextEditingController();

  int? selectedCategory;
  int? selectedSubCategory;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];
  XFile? imageFile;
  Uint8List? imageBytes;
  bool isSaving = false;
  bool isAdmin = false; // 👈 Track if user is Admin

  final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // 👈 Check role on start
    nameController.text = widget.product.name;
    descriptionController.text = widget.product.description ?? "";
    priceController.text = widget.product.price.toString();
    mrpController.text = widget.product.mrp.toString();
    stockController.text = widget.product.stockQuantity.toString();
    lowStockController.text = widget.product.lowStockThreshold.toString();
    selectedCategory = widget.product.categoryId;
    selectedSubCategory = widget.product.subCategoryId;
    skuController.text = widget.product.sku ?? "";
    loadCategories();
  }

  // 🛡️ Detect if the logged-in user is an Admin
  void _checkUserRole() {
    try {
      final decodedToken = JwtDecoder.decode(widget.token);
      setState(() {
        isAdmin = decodedToken['role'] == 'admin';
      });
    } catch (e) {
      isAdmin = false;
    }
  }

  Future<void> updateProduct() async {
    setState(() => isSaving = true);

    try {
      // 🚩 DYNAMIC URL: Uses /admin/ if Admin, else /merchant/
      final String endpoint = isAdmin
          ? "$baseUrl/admin/products/${widget.product.id}"
          : "$baseUrl/merchant/products/${widget.product.id}";

      var request = http.MultipartRequest('PUT', Uri.parse(endpoint));

      request.headers.addAll({
        "Authorization": "Bearer ${widget.token}",
        "ngrok-skip-browser-warning": "true",
      });

      request.fields.addAll({
        'name': nameController.text,
        'description': descriptionController.text,
        'price': priceController.text,
        'mrp': mrpController.text,
        'stock_quantity': stockController.text,
        'low_stock_threshold': lowStockController.text,
        'sku': skuController.text,
        'category_id': selectedCategory?.toString() ?? "",
        'sub_category_id': selectedSubCategory?.toString() ?? "",
      });

      if (imageFile != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
              'image_url', imageBytes!, filename: 'product.png'));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
              'image_url', imageFile!.path));
        }
      }

      var res = await request.send();
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product updated successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Returns true to refresh the list
      } else {
        final errorData = await res.stream.bytesToString();
        throw Exception(errorData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => isSaving = false);
    }
  }

  // ... (Keep your build methods, _containerCard, _textField, etc. as they were) ...

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            child: const Text("Cancel"),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : updateProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff004182),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Update Product", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // --- Helper methods (Provided to ensure code compiles) ---
  Widget _containerCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)));

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()));
  }

  Widget _columnField(String label, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
      const SizedBox(height: 8),
      TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder())),
    ]);
  }

  Widget _dropdown(List<Map<String, dynamic>> items, String hint, int? value, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      value: value, hint: Text(hint), isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['name']))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> loadCategories() async {
    final res = await http.get(Uri.parse("$baseUrl/categories"), headers: {"ngrok-skip-browser-warning": "true"});
    if (res.statusCode == 200) {
      setState(() => categories = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
      if (selectedCategory != null) await loadSubCategories(selectedCategory!);
    }
  }

  Future<void> loadSubCategories(int catId) async {
    final res = await http.get(Uri.parse("$baseUrl/categories/$catId/subcategories"), headers: {"ngrok-skip-browser-warning": "true"});
    if (res.statusCode == 200) setState(() => subCategories = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
  }

  void generateSKU() {
    final String prefix = nameController.text.length >= 3 ? nameController.text.substring(0, 3).toUpperCase() : "PROD";
    final String random = (1000 + (DateTime.now().millisecond % 9000)).toString();
    setState(() => skuController.text = "$prefix-$random");
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text("Update Product", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN: Basic Info
                Expanded(flex: 2, child: _buildGeneralSection()),
                const SizedBox(width: 25),
                // RIGHT COLUMN: Image & Category
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
          _textField(nameController, "Ex: Luxury Watch", maxLines: 1),
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
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageFile != null
                        ? (kIsWeb
                        ? Image.memory(imageBytes!, fit: BoxFit.cover)
                        : Image.file(File(imageFile!.path), fit: BoxFit.cover))
                    // ✅ FIXED: Using fullImageUrl getter from model to prevent double BaseURL
                        : Image.network(
                      widget.product.fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Click to change image", style: TextStyle(fontSize: 12, color: Colors.blue)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _containerCard(
          title: "Category Selection",
          child: Column(
            children: [
              _dropdown(categories, "Select Category", selectedCategory, (val) {
                setState(() {
                  selectedCategory = val;
                  subCategories = [];
                  selectedSubCategory = null;
                });
                if (val != null) loadSubCategories(val);
              }),
              const SizedBox(height: 15),
              _dropdown(subCategories, "Select Sub Category", selectedSubCategory, (val) {
                setState(() => selectedSubCategory = val);
              }),
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
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("SKU Code"),
                    TextField(
                      controller: skuController,
                      decoration: InputDecoration(
                        hintText: "Ex: TS-1234",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                          onPressed: generateSKU,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(flex: 1, child: _columnField("Total Stock", stockController)),
              const SizedBox(width: 15),
              Expanded(flex: 1, child: _columnField("Low Stock Alert", lowStockController)),
            ],
          ),
        ],
      ),
    );
  }






}
