import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'app_session.dart';

class VisitApi {
  const VisitApi();

  Future<void> create({
    required String propertyId,
    required DateTime scheduledAt,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/visits'),
      headers: _headers,
      body: jsonEncode({
        'propertyId': propertyId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'message': message,
      }),
    );
    _decode(response);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (appSession.token != null) 'Authorization': 'Bearer ${appSession.token}',
  };

  void _decode(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Visite impossible.',
      );
    }
  }
}
