import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stoxneu/Screens/Caterogy/model/Category_model.dart';
import 'package:universal_html/html.dart' as html;
import '../../../../Screens/Products/product_api.dart';
import 'dart:convert'; // For utf8 encoding
import 'dart:io';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});
  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  late final ProductApi productApi;
  List<CategoryModel> categories = [];
  bool loading = true;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController();
  XFile? _selectedImage;
  bool _isAvailable = true;
  bool _isSubmitting = false;
  int? _editingCategoryId;
  @override
  void initState() {
    super.initState();
    productApi = ProductApi();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => loading = true);
    try {
      // 🚩 Switch to the Admin-specific fetch method
      final res = await productApi.fetchCategoriesForAdmin();
      setState(() {
        categories = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await productApi.deleteCategory(id);
                _showSnackBar("Deleted successfully", Colors.green);
                _loadCategories();
              } catch (e) {
                _showSnackBar("Delete failed: $e", Colors.red);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editCategory(CategoryModel cat) {
    setState(() {
      _editingCategoryId = cat.id;
      _nameController.text = cat.name;
      _priorityController.text = cat.priority.toString();
      _selectedImage = null; // Let them pick a new one or keep old
    });
    _showAddCategoryPanel(context);
  }

  void _exportCategoriesToExcel() {
    // 1. Define CSV Headers
    String csvData = "SL,ID,Category Name,Priority,Home Category Status\n";

    // 2. Loop through current categories list
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];

      // Clean name of any commas to avoid breaking CSV columns
      String cleanName = cat.name.replaceAll(',', '');
      String homeStatus = cat.homeStatus ? "Active" : "Inactive";

      csvData += "${i + 1},#${cat.id},$cleanName,${cat.priority},$homeStatus\n";
    }

    // 3. Create a Blob and trigger download
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "categories_export_${DateTime.now().millisecondsSinceEpoch}.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
    _showSnackBar("Category list exported successfully", Colors.green);
  }

  Future<void> _submitCategory(BuildContext context) async {
    if (_nameController.text.isEmpty || (_editingCategoryId == null && _selectedImage == null)) {
      _showSnackBar("Name and Image are required", Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_editingCategoryId == null) {
        await productApi.addCategory(
          name: _nameController.text,
          priority: int.tryParse(_priorityController.text) ?? 1,
          imageFile: _selectedImage!,
        );
      } else {
        await productApi.updateCategory(
          id: _editingCategoryId!,
          name: _nameController.text,
          priority: int.tryParse(_priorityController.text) ?? 1,
          imageFile: _selectedImage,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar(_editingCategoryId == null ? "Category added" : "Category updated", Colors.green);

      // ✅ FORCE REFRESH: Clear the local list and re-fetch from API
      setState(() {
        _editingCategoryId = null;
        _nameController.clear();
        _priorityController.clear();
        _selectedImage = null;
        categories = []; // Clear current list to show loading
      });

      await _loadCategories(); // Re-fetch all data from server

    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTableContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text("Category List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _badge(categories.length),
        const Spacer(),
        _searchField(),
        const SizedBox(width: 12),
        // ✅ CONNECTED THE EXPORT FUNCTION HERE
        _outlinedBtn(Icons.download, "Export", onTap: _exportCategoriesToExcel),
        const SizedBox(width: 12),
        _addBtn(),
      ],
    );
  }



  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: loading ? const LinearProgressIndicator() : DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
        dataRowHeight: 70,
        columns: const [
          DataColumn(label: Text('SL')),
          DataColumn(label: Text('Category Name')),
          DataColumn(label: Text('Priority')),
          DataColumn(label: Text('Home Category Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: categories.asMap().entries.map((entry) {
          int index = entry.key;
          CategoryModel cat = entry.value;
          return DataRow(cells: [
            DataCell(Text("${index + 1}")),
            DataCell(Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade100,
                  child: ClipOval(
                    child: Image.network(
                      // 🔥 Use the new getter
                      cat.fullIconUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      // 🔥 Required for ngrok
                      headers: const {'ngrok-skip-browser-warning': 'true'},

                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)));
                      },

                      errorBuilder: (context, error, stackTrace) {
                        // 🔥 FIXED: Added the '$' and correct path /api/?name=
                        return Image.network(
                          "https://ui-avatars.com{cat.name}&background=random&color=fff",
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text("ID: #${cat.id}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            )),


            DataCell(Text("${cat.priority}")),
            DataCell(CupertinoSwitch(
              activeTrackColor: const Color(0xff004182),
              value: cat.homeStatus,
              onChanged: (bool val) async {
                // 1. Optimistic Update (Update UI immediately)
                setState(() => cat.homeStatus = val);

                try {
                  // 2. Call API
                  await productApi.updateHomeStatus(cat.id, val);
                  _showSnackBar("Home status updated!", Colors.green);
                } catch (e) {
                  // 3. Revert on failure
                  setState(() => cat.homeStatus = !val);
                  _showSnackBar("Update failed: $e", Colors.red);
                }
              },
            )),

            // Inside DataTable rows
            DataCell(Row(
              children: [
                _actionIcon(Icons.edit, Colors.blue, () => _editCategory(cat)), // 👈 Call Edit
                const SizedBox(width: 8),
                _actionIcon(Icons.delete, Colors.red, () => _confirmDelete(cat.id)), // 👈 Call Delete
              ],
            )),

          ]);
        }).toList(),
      ),
    );
  }

  Widget _addBtn() {
    return ElevatedButton.icon(
      onPressed: () => _showAddCategoryPanel(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text("Add Category"),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff004182), foregroundColor: Colors.white),
    );
  }

  void _showAddCategoryPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
            builder: (context, setPanelState) {
              return Align(
                alignment: Alignment.centerRight,
                child: Material(
                  child: Container(
                    width: 450,
                    height: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Add Category", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                                onPressed: () {
                                  _editingCategoryId = null; // Reset here
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.close)
                            ),

                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Availability", style: TextStyle(fontWeight: FontWeight.w500)),
                                    Row(
                                      children: [
                                        const Text("Status", style: TextStyle(fontSize: 12)),
                                        CupertinoSwitch(
                                            value: _isAvailable,
                                            activeTrackColor: Colors.blue,
                                            onChanged: (v) => setPanelState(() => _isAvailable = v)
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text("Category Name (EN) *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(hintText: "Type category name", border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 20),
                                const Text("Priority *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _priorityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: "Set Priority (1-10)", border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 30),
                                const Center(child: Text("Category Logo *", style: TextStyle(fontWeight: FontWeight.bold))),
                                const SizedBox(height: 10),
                                Center(
                                  child: InkWell(
                                    onTap: () async {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                      if (image != null) setPanelState(() => _selectedImage = image);
                                    },
                                    child: Container(
                                      width: 150, height: 150,
                                      // inside StatefulBuilder's builder
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        image: _selectedImage != null
                                            ? DecorationImage(
                                          // ✅ Use Image.network for web (the path is a Blob URL)
                                          image: NetworkImage(_selectedImage!.path),
                                          fit: BoxFit.cover,
                                        )
                                            : null,
                                      ),

                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : () => _submitCategory(context),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff004182)),
                                child: _isSubmitting
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text("Submit", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }


  // --- Helpers ---
  Widget _badge(int count) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: Text("$count", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
  Widget _searchField() => SizedBox(width: 240, height: 38, child: TextField(decoration: InputDecoration(hintText: "Search category", prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: EdgeInsets.zero, filled: true, fillColor: Colors.white)));
  Widget _outlinedBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap, // 👈 Uses the passed function
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        foregroundColor: Colors.black87,
      ),
    );
  }
  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material( // Added Material for better hit testing on web
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
}
