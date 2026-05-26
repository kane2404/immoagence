import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'app_session.dart';

class PayDunyaCheckout {
  const PayDunyaCheckout({
    required this.paymentId,
    required this.reference,
    required this.checkoutUrl,
    required this.token,
    required this.status,
  });

  final String paymentId;
  final String reference;
  final String checkoutUrl;
  final String token;
  final String status;

  factory PayDunyaCheckout.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? {};

    return PayDunyaCheckout(
      paymentId: payment['id']?.toString() ?? '',
      reference: payment['reference']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      status: payment['status']?.toString() ?? 'pending',
    );
  }
}

class PayDunyaPaymentApi {
  const PayDunyaPaymentApi();

  Future<PayDunyaCheckout> createCheckout({
    required String propertyId,
    required int amount,
    required String phone,
    required String purpose,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/paydunya/create'),
      headers: _headers,
      body: jsonEncode({
        'propertyId': propertyId,
        'amount': amount,
        'phone': phone,
        'purpose': purpose,
      }),
    );

    final body = _decode(response.body);

    if (response.statusCode != 201) {
      throw ApiException(
        body['message']?.toString() ?? 'Creation du paiement impossible.',
      );
    }

    return PayDunyaCheckout.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<String> confirmPayment(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/paydunya/confirm'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );

    final body = _decode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        body['message']?.toString() ?? 'Verification du paiement impossible.',
      );
    }

    final data = body['data'] as Map<String, dynamic>? ?? {};
    final payment = data['payment'] as Map<String, dynamic>? ?? {};
    return payment['status']?.toString() ?? 'pending';
  }

  Map<String, String> get _headers {
    final token = appSession.token;

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }
}
