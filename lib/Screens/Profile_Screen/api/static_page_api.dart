import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../features/dashboard/Admin_Panel/cms/Static Pages/Model/static_page_model.dart';

class StaticPageApi {

final String baseUrl = ApiConfig.baseUrl;

  Future<StaticPageModel> fetchPage(String slug) async {

    final response = await http.get(
      Uri.parse("$baseUrl/static-pages/$slug"),
      headers: {
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {

      return StaticPageModel.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception("Failed to load page");
  }
}