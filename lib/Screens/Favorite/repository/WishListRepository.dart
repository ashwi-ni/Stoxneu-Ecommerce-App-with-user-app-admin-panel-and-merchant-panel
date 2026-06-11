// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../Auth/repository/auth_repository.dart';
// import '../../Auth/services/auth_service.dart';
// import '../../Products/model/product_model.dart';
//
// class WishListRepository {
//   final String baseUrl;
//   final AuthRepository authRepository;
//
//   WishListRepository({required this.baseUrl, required this.authRepository});
//
//   /// Helper to get headers dynamically
//   Future<Map<String, String>> _getHeaders() async {
//     final token = await authRepository.getToken();
//     if (token == null) throw Exception('User not logged in');
//
//     return {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     };
//   }
//
//   /// Fetch wishlist from backend
//   Future<List<Product>> fetchWishList() async {
//     final headers = await _getHeaders();
//     final response = await http.get(Uri.parse('$baseUrl/wishlist'), headers: headers);
//
//     if (response.statusCode == 200) {
//       final List data = json.decode(response.body);
//       return data.map((e) => Product.fromJson(e)).toList();
//     } else {
//       throw Exception('Failed to load wishlist: ${response.body}');
//     }
//   }
//
//   /// Add product to wishlist
//   Future<void> addToWishList(String productId) async {
//     final headers = await _getHeaders();
//     final response = await http.post(
//       Uri.parse('$baseUrl/wishlist'),
//       headers: headers,
//       body: jsonEncode({'productId': productId}),
//     );
//
//     if (response.statusCode != 201) {
//       throw Exception('Failed to add to wishlist: ${response.body}');
//     }
//   }
//
//   /// Remove product from wishlist
//   Future<void> removeFromWishList(String productId) async {
//     final headers = await _getHeaders();
//     final response = await http.delete(
//       Uri.parse('$baseUrl/wishlist/$productId'),
//       headers: headers,
//     );
//
//     if (response.statusCode != 200) {
//       throw Exception('Failed to remove from wishlist: ${response.body}');
//     }
//   }
// }