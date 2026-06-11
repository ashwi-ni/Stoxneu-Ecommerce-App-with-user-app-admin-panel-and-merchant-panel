import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stoxneu/config/api_config.dart';
import '../../Sub_Categories/model/SubCategoryModel.dart';

import '../../core/network/api_client.dart';
import '../../features/dashboard/Admin_Panel/cms/Static Pages/Model/static_page_model.dart';
import '../../features/dashboard/Admin_Panel/reports/model/sales_report_model.dart';
import '../MyOrder/model/order_model.dart';
import 'model/product_model.dart';
import 'model/BannerModel.dart';
import '../Caterogy/model/Category_model.dart';

class ProductApi {
 final String baseUrl = ApiConfig.baseUrl;

  // Fetch products, optionally by subcategory
  Future<List<Product>> fetchProducts({int? subCategoryId}) async {
    String url = '$baseUrl/products';
    if (subCategoryId != null) {
      url += '?subCategoryId=$subCategoryId'; // filter by subcategory
    }

    final res = await ApiClient.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception('Failed to load products');
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  // Fetch featured products
  Future<List<Product>> fetchFeaturedProducts() async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/products'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load products');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => Product.fromJson(e)).toList();
  }

  // Fetch flash deals
  Future<List<Product>> fetchFlashDeals({String type = "flash_deal"}) async {
    final res = await ApiClient.get(
      Uri.parse('$baseUrl/flash_deals/$type'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load flash deals');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => Product.fromJson(e)).toList();
  }

  /// Fetch banners
  Future<List<BannerModel>> fetchBanners() async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/banners'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load banners');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Fetch categories
  Future<List<CategoryModel>> fetchCategories() async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/categories'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load categories');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    final uri = Uri.parse('$baseUrl/products/search')
        .replace(queryParameters: {'q': query});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Search failed');
    }
  }

  /// ✅ ADMIN METHODS (Using ApiClient)

  // 1. Fetch all products for Admin
  Future<List<Product>> fetchAllProductsForAdmin() async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/admin/products'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load admin products');
    }

    final decoded = jsonDecode(res.body);
    // If backend returns { "data": [...] }, use decoded['data']
    final List data = (decoded is Map) ? decoded['data'] : decoded;

    return data.map((e) => Product.fromJson(e)).toList();
  }

  // 2. Update Status (Approve/Reject)
  Future<void> updateApprovalStatus(int productId, String status) async {
    final res = await ApiClient.post(
      Uri.parse('$baseUrl/admin/products/update-status'),
      body: jsonEncode({
        "product_id": productId,
        "status": status, // 'approved' or 'denied'
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update product status');
    }
  }


  Future<void> addCategory({
    required String name,
    required int priority,
    required XFile imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/admin/category/add');
    var request = http.MultipartRequest('POST', url);

    // 1. Manually add the token to the MultipartRequest headers
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt');

    if (token != null) {
      // Standard format is 'Bearer your_token_here'
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 2. Read bytes for Web compatibility
    final bytes = await imageFile.readAsBytes();

    // 3. Add fields
    request.fields['name'] = name;
    request.fields['priority'] = priority.toString();

    // 4. Add the file (Key must match your multer upload.single('icon_url'))
    request.files.add(http.MultipartFile.fromBytes(
      'icon_url',
      bytes,
      filename: imageFile.name,
    ));

    // 5. Send and check response
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201 && response.statusCode != 200) {
      print("Server Error: ${response.body}"); // Debug exact error
      throw Exception('Failed to add category: ${response.body}');
    }

  }
  Future<void> deleteProductAdmin(int id) async {
    final res = await ApiClient.delete(Uri.parse('$baseUrl/admin/products/$id'));
    if (res.statusCode != 200) throw Exception("Failed to delete product");
  }

  Future<void> updateProductAsAdmin({
    required int id,
    required Map<String, String> fields,
    XFile? imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/admin/products/$id');

    // We use a MultipartRequest for image support
    var request = http.MultipartRequest('PUT', url);

    // ✅ FIX: Use the token logic from your ApiClient or define storage here
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt');

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Necessary for ngrok and json
    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.fields.addAll(fields);

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image_url',
        bytes,
        filename: imageFile.name,
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Admin Update failed: ${response.body}');
    }
  }

  // 🗑️ DELETE CATEGORY
  Future<void> deleteCategory(int id) async {
    final res = await ApiClient.delete(Uri.parse('$baseUrl/admin/category/$id'));
    if (res.statusCode != 200) {
      // Decode only if body is not empty
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(body['message'] ?? 'Delete failed with status: ${res.statusCode}');
    }
  }

  // ✏️ UPDATE CATEGORY (Multipart)
  Future<void> updateCategory({
    required int id,
    required String name,
    required int priority,
    XFile? imageFile
  }) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/admin/category/$id'));

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt');
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['ngrok-skip-browser-warning'] = 'true';

    // ✅ ADD FIELDS FIRST
    request.fields['name'] = name;
    request.fields['priority'] = priority.toString(); // Ensure this is 'priority'

    // ✅ ADD FILE LAST
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
          'icon_url',
          bytes,
          filename: imageFile.name
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Update failed: ${response.body}');
    }
  }

  Future<List<CategoryModel>> fetchCategoriesForAdmin() async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/admin/categories'));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      // ✅ Extract from the 'data' key specifically
      final List data = decoded['data'] ?? [];
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
  Future<void> updateHomeStatus(int id, bool status) async {
    final res = await ApiClient.patch(
      Uri.parse('$baseUrl/admin/category/$id/home-status'),
      body: jsonEncode({"home_status": status}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  // Inside ProductApi class

  Future<List<SubCategoryModel>> fetchSubCategoriesForAdmin() async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/admin/sub-categories'));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      // ✅ Extract the 'data' field
      final List data = decoded['data'] ?? [];
      return data.map((e) => SubCategoryModel.fromJson(e)).toList();
    } else {
      // This helps you see the server's error message in the console
      print("Server Error ${res.statusCode}: ${res.body}");
      throw Exception('Failed to load sub-categories');
    }
  }

  // 🗑️ DELETE
  Future<void> deleteSubCategory(int id) async {
    final res = await ApiClient.delete(Uri.parse('$baseUrl/admin/sub-category/$id'));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Delete failed');
    }
  }


  Future<void> updateSubCategory({
    required int id,
    required String name,
    required int categoryId,
    required int priority,
    Uint8List? imageBytes,
  }) async {
    final url = Uri.parse('$baseUrl/admin/sub-category/$id');

    // 1. CHANGE THIS BACK TO 'PUT'
    var request = http.MultipartRequest('PUT', url);

    const storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'jwt');
    if (token == null) throw Exception('Session expired.');

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    });

    request.fields['name'] = name;
    request.fields['category_id'] = categoryId.toString();
    request.fields['priority'] = priority.toString();

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'icon_url', // 2. MUST match the Multer key in your backend
          imageBytes,
          filename: 'sub_${id}.jpg',
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      print("SERVER ERROR: ${response.body}");
      throw Exception('Update failed: ${response.body}');
    }
  }


  // ➕ ADD SUB-CATEGORY
  Future<void> addSubCategory({
    required String name,
    required int categoryId,
    required int priority,
    required Uint8List? imageBytes, // Add this parameter
  }) async {
    final url = Uri.parse('$baseUrl/admin/sub-category/add');
    var request = http.MultipartRequest('POST', url);

    // 1. Add Token for Authorization
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 2. Add Text Fields
    request.fields['name'] = name;
    request.fields['category_id'] = categoryId.toString();
    request.fields['priority'] = priority.toString();

    // 3. Add Image File (Bytes)
    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'icon_url', // This MUST match your backend multer field name
        imageBytes,
        filename: 'subcategory_${DateTime.now().millisecondsSinceEpoch}.png',
      ));
    }

    // 4. Send Request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201 && response.statusCode != 200) {
      print("Server Error: ${response.body}");
      throw Exception('Failed to add sub-category: ${response.body}');
    }
  }

///FETCH ADMIN ORDERS///
  Future<List<Order>> fetchAllOrdersForAdmin() async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/admin/orders'));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List data = decoded['data'] ?? [];
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }


  // 1. FETCH STATIC PAGE BY SLUG
  // 1. Fetch Page Content
  Future<StaticPageModel> fetchStaticPage(String slug) async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/admin/static-pages/$slug'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load page content');
    }

    final decoded = jsonDecode(res.body);
    // Handle both { data: {...} } and direct object responses
    final data = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;

    return StaticPageModel.fromJson(data is List ? data[0] : data);
  }

  // 2. Save or Update Page Content
  Future<void> saveStaticPage({
    required String slug,
    required String title,
    required String content,
  }) async {
    final res = await ApiClient.post(
      Uri.parse('$baseUrl/admin/static-pages/save'),
      body: jsonEncode({
        "slug": slug,
        "title": title,
        "content": content,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to save page: ${res.body}');
    }
  }

  Future<SalesReportData> fetchSalesReport(String filter) async {
    final res = await ApiClient.get(Uri.parse('$baseUrl/admin/reports/sales?filter=$filter'));
    if (res.statusCode == 200) {
      return SalesReportData.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to load sales report');
    }
  }

  Future<Product> getProductById(int id) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt');

    if (token == null || token.isEmpty) {
      throw Exception("No auth token found");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/merchant/products/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load product: ${response.body}");
    }
  }
}