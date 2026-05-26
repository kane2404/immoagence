import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/issue_report.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'app_session.dart';

class IssueApi {
  const IssueApi();

  Future<void> create({
    required String propertyId,
    required IssueCategory category,
    required IssuePriority priority,
    required String description,
    String? photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tenant/issues'),
      headers: _headers,
      body: jsonEncode({
        'propertyId': propertyId,
        'category': _categoryToApi(category),
        'priority': _priorityToApi(priority),
        'description': description,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
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
        decoded['message']?.toString() ?? 'Signalement impossible.',
      );
    }
  }
}

String _categoryToApi(IssueCategory category) {
  return switch (category) {
    IssueCategory.electricity => 'electricity',
    IssueCategory.water => 'water',
    IssueCategory.plumbing => 'plumbing',
    IssueCategory.lock => 'lock',
    IssueCategory.painting => 'painting',
    IssueCategory.roof => 'roof',
    IssueCategory.internet => 'internet',
    IssueCategory.neighborhood => 'neighborhood',
    IssueCategory.cleaning => 'cleaning',
    IssueCategory.other => 'other',
  };
}

String _priorityToApi(IssuePriority priority) {
  return switch (priority) {
    IssuePriority.low => 'low',
    IssuePriority.normal => 'normal',
    IssuePriority.urgent => 'urgent',
  };
}
