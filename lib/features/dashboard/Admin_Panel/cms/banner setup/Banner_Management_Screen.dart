import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stoxneu/config/api_config.dart';

import '../../../../../Screens/Products/model/BannerModel.dart';
import '../../services/banner_service.dart';


class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final Color primaryColor = const Color(0xff0055D3);
  final BannerService _bannerService = BannerService();
  bool isAddFormVisible = false;
  bool isLoading = true;
  File? selectedImage;
  // Controllers
  final TextEditingController linkController = TextEditingController();
  String selectedType = "Main Banner";
  String selectedResource = "Product";
  List<BannerModel> bannerList = [];
  Uint8List? webImage; // Variable to hold web image bytes
  int? editingBannerId;
  String _generatedLink = "";
  List<Map<String, dynamic>> availableProducts = []; // Fetch from: GET /admin/products
  List<Map<String, dynamic>> availableCategories = []; // Fetch from: GET /admin/categories
  String? selectedResourceId;
  String? selectedResourceName;
  String? selectedFilterType;
  List<dynamic> filteredBannerList = [];
  final String baseUrl = ApiConfig.baseUrl;
  @override
  void initState() {
    super.initState();
    loadData();
    _fetchDropdownData();
    filteredBannerList = bannerList;
  }

  // 1. FETCH DATA FROM API
  void loadData() async {
    setState(() => isLoading = true);

    try {
      var data = await _bannerService.fetchBanners();

      if (!mounted) return;

      setState(() {
        bannerList = data;
        // 🔥 ADD THIS LINE: This makes data visible by default
        filteredBannerList = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchDropdownData() async {
    final products = await _bannerService.getAvailableProducts();
    final categories = await _bannerService.getAvailableCategories();

    if (!mounted) return; // ✅ IMPORTANT

    setState(() {
      availableProducts = products;
      availableCategories = categories;
    });
  }


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // WEB LOGIC: Read as bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          webImage = bytes;
          // This is a placeholder to keep your logic working
          selectedImage = File('web_placeholder');
        });
      } else {
        // MOBILE LOGIC: Use File
        setState(() => selectedImage = File(pickedFile.path));
      }
    }
  }

// Update the Preview Widget
  Widget _imageUploadArea() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 150, width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300)
        ),
        child: kIsWeb && webImage != null
            ? Image.memory(webImage!, fit: BoxFit.cover)
            : selectedImage != null && !kIsWeb
            ? Image.file(selectedImage!, fit: BoxFit.cover)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: primaryColor, size: 30),
            const Text("Click to upload", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }


  // 3. SAVE DATA TO API
  void handleSave() async {
    if (editingBannerId == null && selectedImage == null && webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    setState(() => isLoading = true);
    bool success;

    if (editingBannerId != null) {
      // UPDATING EXISTING
      success = await _bannerService.updateBanner(editingBannerId!, selectedType, linkController.text);
    } else {
      // CREATING NEW
      success = await _bannerService.createBanner(kIsWeb ? webImage : selectedImage, selectedType, linkController.text);
    }

    if (success) {
      if (!mounted) return; // ✅ ADD

      loadData();
      setState(() {
        isAddFormVisible = false;
        editingBannerId = null;
        selectedImage = null;
        webImage = null;
        linkController.clear();
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action failed")));
    }
  }


  void handleDelete(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Banner?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm) {
      setState(() => isLoading = true);

      bool success = await _bannerService.deleteBanner(id);

      if (!mounted) return; // ✅ ADD

      if (success) {
        loadData();
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  // --- EDIT LOGIC (Prepare Form) ---
  void startEdit(BannerModel item) {
    setState(() {
      isAddFormVisible = true;
      editingBannerId = item.id;

      // ✅ FIX 1: Banner type
      selectedType = normalizeBannerType(item.type);

      // ✅ FIX 2: Store full link
      linkController.text = item.link;

      // RESET
      selectedResourceName = null;
      selectedResourceId = null;

      // ✅ FIX 3: Detect resource type from link
      if (item.link.contains("product-details")) {
        selectedResource = "Product";

        final uri = Uri.parse(item.link);
        final id = uri.queryParameters['id'];

        selectedResourceId = id;

        // map ID → name
        final product = availableProducts.firstWhere(
              (p) => p['id'].toString() == id,
          orElse: () => {},
        );

        if (product.isNotEmpty) {
          selectedResourceName = product['name'];
        }

      } else if (item.link.contains("subCategoryId")) {
        selectedResource = "Category";

        final uri = Uri.parse(item.link);
        final id = uri.queryParameters['subCategoryId'];

        selectedResourceId = id;

        final category = availableCategories.firstWhere(
              (c) => c['id'].toString() == id,
          orElse: () => {},
        );

        if (category.isNotEmpty) {
          selectedResourceName = category['name'];
        }

      } else {
        selectedResource = "Custom";
      }
    });
  }
  void _updateLink(String val) {
    setState(() {
      if (selectedResource == "Category") {
        _generatedLink = "/products?subCategoryId=$val";
      } else if (selectedResource == "Product") {
        _generatedLink = "/product-details?id=$val";
      } else if (selectedResource == "Brand") {
        _generatedLink = "/products?brandId=$val";
      } else {
        _generatedLink = val; // Direct link for others
      }
      linkController.text = _generatedLink;
    });
  }

  Widget _buildAddBannerForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _dropdownField(
                      "Banner type *",
                      ["Main Section Banner", "Footer Banner", "Popup Banner"],
                      selectedType,
                          (val) => setState(() => selectedType = val!),
                    ),
                    const SizedBox(height: 16),

                    // Resource Type Dropdown
                    _dropdownField(
                      "Resource type *",
                      ["Product", "Category", "Custom"],
                      selectedResource,
                          (val) {
                        setState(() {
                          selectedResource = val!;
                          selectedResourceId = null;
                          selectedResourceName = null;
                          if (val == "Custom") linkController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // DYNAMIC SECONDARY FIELD
                    _buildDynamicResourceField(),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(flex: 1, child: _imageUploadArea()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => isAddFormVisible = false),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    linkController.clear();
                    selectedImage = null;
                    webImage = null;
                    editingBannerId = null;
                    selectedType = "Main Section Banner";
                    selectedResource = "Product";
                    selectedResourceName = null; // ✅ ADD THIS
                  });
                },
                child: const Text("Reset"),
              ),

              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                onPressed: handleSave,
                child: const Text("Save"),
              ),
            ],
          )
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FBFF),
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
            "Banner Setup",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.black,
            )
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 20,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isAddFormVisible) _buildAddBannerForm(),
            const SizedBox(height: 24),
            _buildTableSection(),
          ],
        ),
      ),
    );
  }



  Widget _buildTableSection() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Banner table (${bannerList.length})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

              // --- FILTERING SECTION ---
              Row(
                children: [
                  // Dropdown Field
                  SizedBox(
                    width: 250, // Fixed width for the dropdown
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      hint: const Text("Select Banner Type"),
                      value: selectedFilterType, // Define this variable in your state
                      items: ["All", "Main Banner", "Footer Banner", "Popup Banner", "Main Section Banner"]
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedFilterType = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter Button
                  // Filter Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (selectedFilterType == null || selectedFilterType == "All") {
                          // Reset to show everything from the original list
                          filteredBannerList = bannerList;
                        } else {
                          // Filter the original list and assign the results to the filtered list
                          filteredBannerList = bannerList
                              .where((item) => item.type == selectedFilterType)
                              .toList();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Use your primary blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Filter"),
                  ),


                  const SizedBox(width: 10),

                  // --- ADD BANNER BUTTON ---
                  ElevatedButton.icon(
                    onPressed: () => setState(() {
                      isAddFormVisible = true;
                      editingBannerId = null;
                      linkController.clear();
                      selectedImage = null;
                      webImage = null;
                      selectedResourceName = null;
                    }),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add Banner"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1800),
                child: _dataTable(),
              ),
            ),
          )
        ],
      ),
    );
  }




  Widget _dataTable() {
    return DataTable(
      columnSpacing: 20,
      horizontalMargin: 12,
      headingRowHeight: 50,
      dataRowHeight: 70,
      headingRowColor: WidgetStateProperty.all(const Color(0xffF1F4F9)),
      columns: const [
        DataColumn(label: Text("SL")),
        DataColumn(label: Text("Image")),
        DataColumn(label: Text("Banner Type")),
        DataColumn(label: Text("Resource")),
        DataColumn(label: Text("Published")),
        DataColumn(label: Text("Action")),
      ],
      // 🔥 CHANGE: Use filteredBannerList instead of bannerList
      rows: filteredBannerList.asMap().entries.map((entry){
        int idx = entry.key;
        BannerModel item = entry.value;

        String resourceType = "Custom";
        if (item.link.contains("product-details")) {
          resourceType = "Product";
        } else if (item.link.contains("subCategoryId")) {
          resourceType = "Category";
        }

        return DataRow(cells: [
          DataCell(Text("${idx + 1}")),
          DataCell(
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                item.fullImageUrl,
                width: 120,
                height: 60,
                fit: BoxFit.cover,
                headers: const {
                  'ngrok-skip-browser-warning': 'true', // 🔥 This is the "Visit Site" bypass
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("FAILING URL: ${item.fullImageUrl}");
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
              )

            ),
          ),



          DataCell(Text(item.type)), // Displays "Main Banner" or "Footer Banner"
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(resourceType, style: const TextStyle(fontSize: 12)),
            ),
          ),
          DataCell(
            CupertinoSwitch(
              value: item.isPublished,
              activeColor: primaryColor,
              onChanged: (bool newValue) async {
                setState(() => item.isPublished = newValue);
                await _bannerService.updateBannerStatus(item.id, newValue);
              },
            ),
          ),
          DataCell(
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    onPressed: () async {
                      if (availableProducts.isEmpty || availableCategories.isEmpty) {
                        await _fetchDropdownData();
                      }
                      startEdit(item);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => handleDelete(item.id),
                  ),
                ],
              ),
            ),
          ),
        ]);
      }).toList(),
    );
  }


  // --- HELPERS ---
  Widget _dropdownField(
      String label,
      List<String> items,
      String? selectedValue,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),

          // ✅ FIX: safe value
          value: safeDropdownValue(items, selectedValue),

          items: items.toSet().map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: const TextStyle(fontSize: 13)),
          )).toList(),

          onChanged: onChanged,
        ),
      ],
    );
  }




  Widget _buildDynamicResourceField() {
    if (selectedResource == "Product") {
      return _dropdownField(
        "Select Product *",
        availableProducts.map((p) => p['name'].toString()).toList(),
        selectedResourceName, // ✅ selected value
            (val) {
          setState(() {
            selectedResourceName = val;

            final product = availableProducts.firstWhere((p) => p['name'] == val);
            _updateLink(product['id'].toString());
          });
        },
      );
    } else if (selectedResource == "Category") {
      return _dropdownField(
        "Select Category *",
        availableCategories.map((c) => c['name'].toString()).toList(),
        selectedResourceName, // ✅ same variable works
            (val) {
          setState(() {
            selectedResourceName = val;

            final category = availableCategories.firstWhere((c) => c['name'] == val);
            _updateLink(category['id'].toString());
          });
        },
      );
    } else if (selectedResource == "Custom") {
      return _textField("Enter Custom URL *", linkController);
    }
    return const SizedBox.shrink();
  }

  Widget _textField(String label, TextEditingController controller, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
        ),
      ],
    );
  }

  String normalizeBannerType(String type) {
    if (type.toLowerCase().contains("main")) return "Main Section Banner";
    if (type.toLowerCase().contains("footer")) return "Footer Banner";
    if (type.toLowerCase().contains("popup")) return "Popup Banner";
    return "Main Section Banner";
  }

  String? safeDropdownValue(List<String> items, String? value) {
    if (value == null) return null;
    return items.contains(value) ? value : null;
  }
}



