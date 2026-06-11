import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../model/SubCategoryModel.dart';


class SubCategoryRepository {
  Future<List<SubCategoryModel>> fetchSubCategories(int categoryId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/categories/$categoryId/subcategories',
      ),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => SubCategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load subcategories');
    }
  }
}