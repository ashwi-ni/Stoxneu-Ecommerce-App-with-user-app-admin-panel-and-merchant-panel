import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:stoxneu/config/api_config.dart';
import '../model/address_model.dart';

class AddressService {
 final String baseUrl = ApiConfig.baseUrl;
  final FlutterSecureStorage storage;

  AddressService({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();

  // Get logged-in userId from JWT
  Future<int> _getUserId() async {
    final token = await storage.read(key: 'jwt');
    if (token == null) throw Exception("User not logged in");
    final decoded = JwtDecoder.decode(token);
    return decoded['id'];
  }

  // ---------------- GET ADDRESSES ----------------
  Future<List<AddressModel>> fetchAddresses() async {
    final token = await storage.read(key: 'jwt');

    final response = await http.get(
      Uri.parse('$baseUrl/addresses'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );


    if (response.statusCode != 200) {
      throw Exception("Failed to fetch addresses: ${response.body}");
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => AddressModel.fromJson(e)).toList();
  }

  // ---------------- ADD ADDRESS ----------------
  Future<AddressModel> addAddress(AddressModel address) async {
    final token = await storage.read(key: 'jwt');

    final body = {
      "name": address.name,
      "phone": address.phone,
      "house": address.house,
      "road": address.road,
      "city": address.city,
      "state": address.state,
      "country": address.country,
      "pincode": address.pincode,
      "landmark": address.landmark ?? "",
      "isDefault": address.isDefault ? 1 : 0, // ✅ must be 0 or 1
    };

    final response = await http.post(
      Uri.parse('$baseUrl/addresses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return AddressModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add address: ${response.body}');
    }
  }

  // ---------------- UPDATE ADDRESS ----------------
  Future<AddressModel> updateAddress(AddressModel address) async {
    final token = await storage.read(key: 'jwt');

    final body = {
      "name": address.name,
      "phone": address.phone,
      "house": address.house,
      "road": address.road,
      "city": address.city,
      "state": address.state,
      "country": address.country,
      "pincode": address.pincode,
      "landmark": address.landmark ?? "",
      "isDefault": address.isDefault ? 1 : 0,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/addresses/${address.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return AddressModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update address: ${response.body}');
    }
  }
  // ---------------- DELETE ADDRESS ----------------

  Future<void> deleteAddress(int id) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.delete(
      Uri.parse('$baseUrl/addresses/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete address: ${response.body}');
    }
  }
}
