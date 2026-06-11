import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import '../../ApiService/product_api.dart';
import 'package:stoxneu/Screens/Products/model/product_model.dart';

class MerchantProductsScreen extends StatefulWidget {
  const MerchantProductsScreen({super.key});

  @override
  State<MerchantProductsScreen> createState() => _MerchantProductsScreenState();
}

class _MerchantProductsScreenState extends State<MerchantProductsScreen> with SingleTickerProviderStateMixin {
  late final MerchantProductApi productApi;
  late TabController _tabController;

  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool loading = true;
  final TextEditingController searchController = TextEditingController();
  final List<String> tabs = ["All", "Active", "Inactive", "Low Stock"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    final authRepo = context.read<AuthRepository>();
    productApi = MerchantProductApi(authRepository: authRepo);
    loadProducts();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _filterByTab();
    });
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    try {
      final result = await productApi.fetchMerchantProducts();
      setState(() {
        products = result;
        _filterByTab();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _showSnackBar("Failed to load: $e", Colors.red);
    }
  }

  void _filterByTab() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((p) {
        bool matchesSearch = p.name.toLowerCase().contains(query);
        if (_tabController.index == 1) return matchesSearch && p.isActive == 1;
        if (_tabController.index == 2) return matchesSearch && p.isActive == 0;
        if (_tabController.index == 3) return matchesSearch && (p.stockQuantity) <= (p.lowStockThreshold ?? 5);
        return matchesSearch;
      }).toList();
    });
  }
  void _showQuickStockUpdate(Product p) {
    final controller = TextEditingController(text: p.stockQuantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Stock: ${p.name}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "New Stock Quantity", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                try {
                  int newStock = int.tryParse(controller.text) ?? p.stockQuantity;
                  await productApi.updateStock(p.id, newStock);
                  if (!mounted) return;
                  Navigator.pop(context);
                  loadProducts(); // Refresh list
                  _showSnackBar("Stock updated!", Colors.green);
                } catch (e) {
                  _showSnackBar("Stock update failed", Colors.red);
                }
              },
              child: const Text("Update")
          ),
        ],
      ),
    );
  }


  /// 🛡️ ADMIN APPROVAL BADGE
  Widget _buildApprovalBadge(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'denied' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  /// 🔄 VENDOR ACTIVE TOGGLE
  Widget _buildStatusToggle(Product product) {
    // Logic: Only allow toggle if Admin has approved the product
    bool isApproved = product.requestStatus.toLowerCase() == 'approved';

    return Tooltip(
      message: isApproved ? "Toggle Visibility" : "Waiting for Admin Approval",
      child: Switch(
        // If not approved, force the value to false/0
        value: isApproved && product.isActive == 1,
        activeColor: Colors.green,
        // Disable the switch (onChanged = null) if not approved
        onChanged: !isApproved
            ? null
            : (bool newValue) async {
          setState(() => product.isActive = newValue ? 1 : 0);
          try {
            await productApi.toggleStatus(product.id, newValue ? 1 : 0);
            _showSnackBar("Product is now ${newValue ? 'Live' : 'Hidden'}", Colors.green);
          } catch (e) {
            setState(() => product.isActive = newValue ? 0 : 1);
            _showSnackBar("Update failed", Colors.red);
          }
        },
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

                _buildSearchBar(),



            const SizedBox(height: 20),
            _buildTabs(), // Status Tabs (All, Active, etc.)
            const SizedBox(height: 20),

            // Ensure your Table is also inside an Expanded
            Expanded(child: _buildProductTable()),
          ],
        ),
      ),
    );

  }

  Widget _buildHeader() {
    return const Text("Product List", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: tabs.map((t) => Tab(text: t)).toList(),
      labelColor: Colors.blue,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.blue,
    );
  }

  Widget _buildSearchBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 300,
          height: 45,
          child: TextField(
            controller: searchController,
            onChanged: (_) => _filterByTab(),
            decoration: InputDecoration(
              hintText: "Search by Name...",
              prefixIcon: const Icon(Icons.search, size: 20),

              // 🎨 SETTING THE BORDER COLOR
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5), // Color when not focused
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.yellow, width: 2.0), // Color when clicked
              ),

              filled: true,
              fillColor: const Color(0xffF1F4F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        // ➕ Add Product Button
        ElevatedButton.icon(
          onPressed: () async {
            if (await context.push('/add-product') == true) loadProducts();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add New Product"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTable() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProducts.isEmpty) {
      return const Center(child: Text("No products found"));
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical, // ✅ vertical scroll
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // ✅ horizontal scroll
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1200),
            child: DataTable(
              columnSpacing: 170,
              dataRowHeight: 70,
              headingRowHeight: 50,
              headingRowColor: WidgetStateProperty.all(
                const Color(0xffF1F4F9),
              ),
              columns: const [
                DataColumn(label: Text("SL")),
                DataColumn(label: Text("Product Info")),
                DataColumn(label: Text("Price")),
                DataColumn(label: Text("Stock")),
                DataColumn(label: Text("Verify Status")),
                DataColumn(label: Text("Active Status")),
                DataColumn(label: Text("Action")),
              ],
              rows: filteredProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                bool isLowStock =
                    (p.stockQuantity) <= (p.lowStockThreshold);

                return DataRow(cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            p.fullImageUrl,
                            headers: const {'ngrok-skip-browser-warning': 'true'},
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported, size: 30, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(p.name),
                    ],
                  )),
                  DataCell(Text("₹${p.price}")),
                  DataCell(Text("${p.stockQuantity}")),
                  DataCell(_buildApprovalBadge(p.requestStatus)),
                  DataCell(_buildStatusToggle(p)),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility,
                              color: Colors.green),
                          onPressed: () {
                            context.push('/merchant-productdetail',
                                extra: p);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blue),
                          onPressed: () async {
                            final result = await context.push(
                                '/merchant-editproduct',
                                extra: p);
                            if (result == true) loadProducts();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () => _confirmDelete(p),
                        ),
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }




  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to delete '${p.name}'?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => context.pop(),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () async {
              context.pop();

              try {
                await productApi.deleteProduct(p.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product deleted successfully")),
                );

                await loadProducts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Delete failed: $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
