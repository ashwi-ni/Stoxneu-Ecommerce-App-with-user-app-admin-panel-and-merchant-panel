import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stoxneu/Screens/Products/model/product_model.dart';
import '../../../../Screens/Products/product_api.dart';

class AdminProductApprovalScreen extends StatefulWidget {
  const AdminProductApprovalScreen({super.key});

  @override
  State<AdminProductApprovalScreen> createState() => _AdminProductApprovalScreenState();
}

class _AdminProductApprovalScreenState extends State<AdminProductApprovalScreen> {
  late final ProductApi productApi;
  List<Product> allPendingProducts = []; // Master list
  List<Product> filteredProducts = [];    // Display list
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    productApi = ProductApi();
    loadPendingProducts();
  }

  Future<void> loadPendingProducts() async {
    setState(() => loading = true);
    try {
      final result = await productApi.fetchAllProductsForAdmin();
      setState(() {
        allPendingProducts = result.where((p) => p.requestStatus == 'pending').toList();
        filteredProducts = allPendingProducts;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _showSnackBar("Error loading products", Colors.red);
    }
  }

  // 🔍 Functional Search Logic
  void _filterProducts(String query) {
    setState(() {
      filteredProducts = allPendingProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: Text("Vendor Product List (${allPendingProducts.length})",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,

      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity, // Expand to whole screen width
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _buildDataTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Pending Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          // 🔎 Small, Functional Search Bar
          SizedBox(
            width: 250,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: "Search name...",
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xffF1F4F9)),
              horizontalMargin: 12,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('SL')),
                DataColumn(label: Text('Product Details')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Manage')),
              ],
              rows: filteredProducts.asMap().entries.map((entry) {
                int index = entry.key;
                Product p = entry.value;
                debugPrint("WORKING PRODUCT URL: ${p.fullImageUrl}");
                return DataRow(cells: [
                  DataCell(Text((index + 1).toString())),
                  DataCell(Row(

                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          // Your dynamic image URL

                          p.fullImageUrl,
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                          headers: const {'ngrok-skip-browser-warning': 'true'}, // Necessary for ngrok

                          // 1. Placeholder while loading
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 35,
                              height: 35,
                              color: Colors.grey.shade100,
                              child: const Center(
                                  child: SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                  )
                              ),
                            );

                          },

                          // 2. Placeholder if image fails to load (404, invalid URL, etc.)
                          errorBuilder: (context, error, stackTrace) {
                            return _buildInitialsPlaceholder(p.name);
                          },
                        ),
                      ),

                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          Text("SKU: ${p.sku}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  )),


                  DataCell(Text("₹${p.price}")),
                  DataCell(_buildStatusBadge(p.requestStatus)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min, // 👈 Prevent row from expanding
                      children: [
                        _iconBtn(Icons.check, Colors.green, () => _handleApproval(p.id, 'approved')),
                        const SizedBox(width: 8),
                        _iconBtn(Icons.close, Colors.red, () => _handleApproval(p.id, 'denied')),
                        const SizedBox(width: 12), // More spacing for easier clicking
                        _iconBtn(Icons.edit, Colors.blue, () => _editProduct(p)),
                        const SizedBox(width: 8),
                        _iconBtn(Icons.delete, Colors.red, () => _confirmDelete(p.id)),
                      ],
                    ),
                  ),


                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // 🔘 Named Action Buttons for better Admin understanding
  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(80, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _handleApproval(int productId, String newStatus) async {
    try {
      await productApi.updateApprovalStatus(productId, newStatus);
      _showSnackBar("Product $newStatus", newStatus == 'approved' ? Colors.green : Colors.orange);
      loadPendingProducts();
    } catch (e) {
      _showSnackBar("Action failed", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  // ✏️ Navigate to Edit Screen
  // ✏️ Navigate to Edit Screen
  // ✏️ Navigate to Edit Screen
  void _editProduct(Product product) {
    debugPrint("Navigating to edit: ${product.name}");
    context.push('/merchant-editproduct', extra: product).then((value) {
      if (value == true) loadPendingProducts();
    });
  }

  void _confirmDelete(int productId) {
    debugPrint("Showing delete dialog for ID: $productId");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await productApi.deleteProductAdmin(productId);
                _showSnackBar("Product deleted", Colors.green);
                loadPendingProducts();
              } catch (e) {
                _showSnackBar("Error: $e", Colors.red);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }


  // 🔘 Fully functional Icon Button Widget
  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: () {
          debugPrint("Button Pressed: $icon"); // 👈 This will now show in console
          onTap();
        },
        icon: Icon(icon, color: color, size: 16),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(6),
        splashRadius: 20,
      ),
    );
  }
}

Widget _buildInitialsPlaceholder(String name) {
  // Uses ui-avatars.com to generate a high-quality initials image
  final String initialsUrl = "https://ui-avatars.com{Uri.encodeComponent(name)}&background=random&color=fff&bold=true";

  return Image.network(
    initialsUrl,
    width: 35,
    height: 35,
    fit: BoxFit.cover,
    // Final fallback to a static icon if even the avatar API fails
    errorBuilder: (context, error, stackTrace) => Container(
      width: 35,
      height: 35,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, size: 20, color: Colors.grey),
    ),
  );
}

