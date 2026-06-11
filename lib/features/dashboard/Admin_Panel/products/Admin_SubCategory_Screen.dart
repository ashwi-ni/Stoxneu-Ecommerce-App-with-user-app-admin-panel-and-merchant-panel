import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import '../../../../Screens/Caterogy/model/Category_model.dart';
import '../../../../Screens/Products/product_api.dart';
import '../../../../Sub_Categories/model/SubCategoryModel.dart';
import 'dart:typed_data';

class AdminSubCategoryScreen extends StatefulWidget {
  const AdminSubCategoryScreen({super.key});
  @override
  State<AdminSubCategoryScreen> createState() => _AdminSubCategoryScreenState();
}

class _AdminSubCategoryScreenState extends State<AdminSubCategoryScreen> {
  late final ProductApi productApi;
  List<SubCategoryModel> subCategories = [];
  bool loading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController();
  List<SubCategoryModel> filteredSubCategories = []; // 👈 New list for UI
  final TextEditingController _searchController = TextEditingController();
  int? _filterMainCategoryId;
  int? _editingSubCategoryId;
  int? _selectedMainCategoryId;
  List<CategoryModel> mainCategories = [];
  Uint8List? _subImageBytes;
  String _selectedSort = "New to Oldest";
  List<int> _tempSelectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    productApi = ProductApi();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final res = await productApi.fetchSubCategoriesForAdmin();
      setState(() {
        subCategories = res;
        filteredSubCategories = res; // Initialise with full list
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
      builder: (context) =>
          AlertDialog(
            title: const Text("Delete Sub Category?"),
            content: const Text(
                "Are you sure? This will permanently remove the sub-category."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await productApi.deleteSubCategory(id);
                    _showSnackBar("Deleted successfully", Colors.green);
                    _loadData();
                  } catch (e) {
                    _showSnackBar("Error: $e", Colors.red);
                  }
                },
                child: const Text(
                    "Delete", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

// ✏️ EDIT LOGIC
  void _editSubCategory(SubCategoryModel sub) {
    setState(() {
      _editingSubCategoryId = sub.id;
      _nameController.text = sub.name;
      _priorityController.text = sub.priority.toString();
      _selectedMainCategoryId = sub.categoryId;
      _subImageBytes = null;
    });
    _showSubCategoryPanel();
  }


  void _runSearch(String query) {
    setState(() {
      filteredSubCategories = subCategories
          .where((sub) =>
      sub.name.toLowerCase().contains(query.toLowerCase()) ||
          (sub.mainCategoryName?.toLowerCase().contains(query.toLowerCase()) ??
              false))
          .toList();
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        const Text("Sub Category List",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _badge(subCategories.length),
        const Spacer(),
        _searchField(),
        const SizedBox(width: 12),
        _outlinedBtn(Icons.filter_list, "Filter", onTap: _showFilterDialog),
        _outlinedBtn(Icons.download, "Export", onTap: _exportToExcel),

        const SizedBox(width: 10),
        _addBtn(),
      ],
    );
  }

  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: loading ? const LinearProgressIndicator() : DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
        columns: const [
          DataColumn(label: Text('SL')),
          DataColumn(label: Text('Image')), // 👈 Moved here
          DataColumn(label: Text('Sub Category Name')),
          DataColumn(label: Text('Main Category Name')),
          DataColumn(label: Text('Priority')),
          DataColumn(label: Text('Action')),
        ],
        rows: filteredSubCategories
            .asMap()
            .entries
            .map((entry) {
          int index = entry.key;
          var sub = entry.value;
          return DataRow(cells: [
            DataCell(Text("${index + 1}")),

            DataCell(
              CircleAvatar(
                radius: 20,
                child: ClipOval(
                  child: Image.network(
                    sub.fullIconUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                  ),
                ),
              ),
            ),

            DataCell(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(sub.name, style: const TextStyle(fontWeight: FontWeight
                    .w600)),
                Text("ID: #${sub.id}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            )),
            DataCell(Text(sub.mainCategoryName ?? "N/A")),
            DataCell(Text("${sub.priority}")),
            DataCell(Row(
              children: [
                _iconBtn(Icons.edit, Colors.blue, () => _editSubCategory(sub)),
                const SizedBox(width: 8),
                _iconBtn(Icons.delete, Colors.red, () =>
                    _confirmDelete(sub.id)),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }


  // --- UI Helpers (Same style as Category Screen) ---
  Widget _badge(int count) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12)),
      child: Text("$count", style: const TextStyle(fontSize: 11)));

  Widget _searchField() =>
      SizedBox(
          width: 250, height: 35,
          child: TextField(
              controller: _searchController, // 👈 Assign controller
              onChanged: _runSearch, // 👈 Connect search function
              decoration: InputDecoration(
                  hintText: "Search sub categories...",
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.white
              )
          )
      );

  Widget _outlinedBtn(IconData icon, String label, {VoidCallback? onTap}) =>
      OutlinedButton.icon(
          onPressed: onTap, // 👈 Pass the action
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              foregroundColor: Colors.black87)
      );

  Widget _addBtn() =>
      ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _editingSubCategoryId = null; // Clear ID
            _nameController.clear();
            _priorityController.clear();
            _selectedMainCategoryId = null;
            _subImageBytes = null;
          });
          _showSubCategoryPanel();
        },
        icon: const Icon(Icons.add, size: 16),
        label: const Text(" Add Sub Category"),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff004182),
            foregroundColor: Colors.white),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }


// 📸 Function to pick image inside the panel
  Future<void> _pickImage(StateSetter setPanelState) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setPanelState(() {
        _subImageBytes = bytes; // ✅ Now works with dart:typed_data
      });
    }
  }

  void _showSubCategoryPanel() async {
    // Fetch main categories for the dropdown if not already loaded
    if (mainCategories.isEmpty) {
      final cats = await productApi.fetchCategories();
      setState(() => mainCategories = cats);
    }

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        late final currentSub = _editingSubCategoryId != null
            ? subCategories.firstWhere((s) => s.id == _editingSubCategoryId)
            : null;

        return StatefulBuilder(builder: (context, setPanelState) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              child: Container(
                width: 400,
                height: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingSubCategoryId == null
                              ? "Add Sub Category"
                              : "Edit Sub Category",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 20),

                    // --- IMAGE UPLOAD SECTION ---
                    const Text("Sub Category Image",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Center(
                      child: InkWell(
                        onTap: () => _pickImage(setPanelState),
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _subImageBytes != null
                                ? Image.memory(_subImageBytes!, fit: BoxFit.cover) // 1. Show newly picked
                                : (currentSub != null && currentSub!.fullIconUrl.isNotEmpty)
                                ? Image.network( // 2. Show existing from DB
                              currentSub!.fullIconUrl,
                              fit: BoxFit.cover,
                              headers: const {'ngrok-skip-browser-warning': 'true'},
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                            )
                                : const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey), // 3. Placeholder
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- DROPDOWN: MAIN CATEGORY ---
                    const Text("Main Category *",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedMainCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      // ✅ FIX: Use dot notation for class properties
                      items: mainCategories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id, // Changed from c['id']
                          child: Text(c.name), // Changed from c['name']
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setPanelState(() => _selectedMainCategoryId = val),
                    ),

                    const SizedBox(height: 20),

                    // --- TEXTFIELD: SUB CATEGORY NAME ---
                    const Text("Sub Category Name *",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            hintText: "Enter name",
                            border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 20),

                    // --- TEXTFIELD: PRIORITY ---
                    const Text(
                        "Priority", style: TextStyle(fontWeight: FontWeight
                        .w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priorityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "Ex: 1, 2, 3",
                          border: OutlineInputBorder()),
                    ),

                    const Spacer(),

                    // --- ACTION BUTTONS ---
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff004182)),
                                onPressed: () async {
          if (_nameController.text.isEmpty || _selectedMainCategoryId == null) {
          _showSnackBar("Please fill required fields", Colors.orange);
          return;
          }

          try {
          if (_editingSubCategoryId == null) {
          // ADD NEW
          await productApi.addSubCategory(
          name: _nameController.text,
          categoryId: _selectedMainCategoryId!,
          priority: int.tryParse(_priorityController.text) ?? 1,
          imageBytes: _subImageBytes, // Ensure this exists in your API
          );
          } else {
          // ✏️ UPDATE EXISTING - Passing the imageBytes here is the key!
          await productApi.updateSubCategory(
          id: _editingSubCategoryId!,
          name: _nameController.text,
          categoryId: _selectedMainCategoryId!,
          priority: int.tryParse(_priorityController.text) ?? 1,
          imageBytes: _subImageBytes, // 👈 ADD THIS LINE
          );
          }

          if (!mounted) return;
          Navigator.pop(context);
          _showSnackBar(_editingSubCategoryId == null ? "Added!" : "Updated!", Colors.green);

          _loadData(); // Refresh the table
          } catch (e) {
          _showSnackBar("Error: $e", Colors.red);
          }
          },

          child: const Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0))
                .animate(anim1),
            child: child
        );
      },
    );
  }


  // 📤 EXPORT LOGIC (Simple Console Export)
  void _exportToExcel() {
    // 1. Define CSV Header
    String csvContent = "SL,ID,Sub Category Name,Main Category Name,Priority\n";

    // 2. Map data
    for (int i = 0; i < filteredSubCategories.length; i++) {
      var sub = filteredSubCategories[i];
      csvContent +=
      "${i + 1},#${sub.id},${sub.name},${sub.mainCategoryName},${sub
          .priority}\n";
    }

    // 3. Trigger Web Download
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "sub_categories_${DateTime
          .now()
          .millisecondsSinceEpoch}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);

    _showSnackBar("Exporting started...", Colors.blue);
  }

  // 🧹 FILTER LOGIC
  void _showFilterDialog() async {
    if (mainCategories.isEmpty) {
      final cats = await productApi.fetchCategories();
      setState(() => mainCategories = cats);
    }

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(builder: (context, setPanelState) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              child: Container(
                width: 350,
                height: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Filter",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight
                            .bold)),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Text(
                        "Sorting", style: TextStyle(fontWeight: FontWeight
                        .bold)),
                    _buildSortRadio("New to Oldest", setPanelState),
                    _buildSortRadio("A-Z", setPanelState),
                    _buildSortRadio("Z-A", setPanelState),
                    const SizedBox(height: 30),
                    const Text(
                        "Category", style: TextStyle(fontWeight: FontWeight
                        .bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: mainCategories.length,
                        itemBuilder: (context, i) {
                          final cat = mainCategories[i];
                          return CheckboxListTile(
                            title: Text(
                                cat.name, style: const TextStyle(fontSize: 13)),
                            value: _tempSelectedCategoryIds.contains(cat.id),
                            onChanged: (val) {
                              setPanelState(() {
                                if (val == true) {
                                  _tempSelectedCategoryIds.add(cat.id);
                                } else {
                                  _tempSelectedCategoryIds.remove(cat.id);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _tempSelectedCategoryIds.clear();
                                _selectedSort = "New to Oldest";
                                filteredSubCategories =
                                    List.from(subCategories);
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Reset"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Inside your showGeneralDialog -> StatefulBuilder -> builder: (context, setPanelState)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff004182)),
                            // ✅ Pass the dialog's context here
                            onPressed: () => _applyFilters(context),
                            child: const Text("Apply", style: TextStyle(color: Colors.white)),
                          ),
                        ),

                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0))
              .animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget _buildSortRadio(String title, StateSetter setPanelState) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: title,
      groupValue: _selectedSort,
      onChanged: (val) => setPanelState(() => _selectedSort = val!),
    );
  }
// Change this
  void _applyFilters(BuildContext dialogContext) { // 👈 Add this parameter
    setState(() {
      List<SubCategoryModel> results = _tempSelectedCategoryIds.isEmpty
          ? List.from(subCategories)
          : subCategories.where((s) => _tempSelectedCategoryIds.contains(s.categoryId)).toList();

      if (_selectedSort == "A-Z") {
        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else if (_selectedSort == "Z-A") {
        results.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      } else if (_selectedSort == "New to Oldest") {
        results.sort((a, b) => b.id.compareTo(a.id));
      }

      filteredSubCategories = results;
    });

    // ✅ Use the dialogContext to close the side panel
    Navigator.pop(dialogContext);
  }
}