import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/property.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_mappers.dart';
import 'app_session.dart';

class DashboardData {
  const DashboardData({
    required this.properties,
    required this.visits,
    required this.contracts,
    required this.payments,
    required this.receipts,
    required this.issues,
    required this.messages,
    required this.calendarEvents,
  });

  final List<Property> properties;
  final List<Map<String, dynamic>> visits;
  final List<Map<String, dynamic>> contracts;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> receipts;
  final List<Map<String, dynamic>> issues;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> calendarEvents;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) {
      final raw = json[key] as List<dynamic>? ?? [];
      return raw.cast<Map<String, dynamic>>();
    }

    return DashboardData(
      properties: list('properties').map(propertyFromApi).toList(),
      visits: list('visits'),
      contracts: list('contracts'),
      payments: list('payments'),
      receipts: list('receipts'),
      issues: list('issues'),
      messages: list('messages'),
      calendarEvents: list('calendarEvents'),
    );
  }
}

class DashboardApi {
  const DashboardApi();

  Future<DashboardData> load() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/dashboard'),
      headers: _headers,
    );
    final decoded = _decode(response);
    return DashboardData.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Map<String, String> get _headers {
    final token = appSession.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Chargement dashboard impossible.',
      );
    }
    return decoded;
  }
}
