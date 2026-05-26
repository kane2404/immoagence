import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/property.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_mappers.dart';

class PropertyApi {
  const PropertyApi();

  Future<List<Property>> list() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/properties'),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Biens indisponibles.',
      );
    }
    final data = decoded['data'] as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(propertyFromApi)
        .where((property) => property.title.isNotEmpty)
        .toList();
  }
}
