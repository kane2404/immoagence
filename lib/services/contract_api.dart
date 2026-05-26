import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/contract.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'app_session.dart';

class ContractApi {
  const ContractApi();

  Future<String> request({
    required String propertyId,
    required ContractType type,
    required int amount,
    required List<String> terms,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/contracts/request'),
      headers: _headers,
      body: jsonEncode({
        'propertyId': propertyId,
        'type': _contractTypeToApi(type),
        'amount': amount,
        'terms': terms,
        'startDate': DateTime.now().toIso8601String().substring(0, 10),
      }),
    );
    final decoded = _decode(response);
    final data = decoded['data'] as Map<String, dynamic>;
    return data['reference']?.toString() ??
        'CTR-${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (appSession.token != null) 'Authorization': 'Bearer ${appSession.token}',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Contrat impossible.',
      );
    }
    return decoded;
  }
}

String _contractTypeToApi(ContractType type) {
  return switch (type) {
    ContractType.rental => 'rental',
    ContractType.colocation => 'colocation',
    ContractType.landSale => 'land_sale',
    ContractType.houseSale => 'house_sale',
  };
}
