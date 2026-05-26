import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/property.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_mappers.dart';
import 'app_session.dart';

class AdminApi {
  const AdminApi();

  Future<List<AppUser>> users() async {
    final data = await _getList('users');
    return data.map(userFromApi).toList();
  }

  Future<AppUser> createAccount({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final response = await _post('/admin/accounts', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': roleToApi(role),
    });
    final decoded = _decode(response);
    return userFromApi(decoded['user'] as Map<String, dynamic>);
  }

  Future<AppUser> setUserBlocked(String id, bool isBlocked) async {
    final response = await _patch('/admin/users/$id', {
      'is_blocked': isBlocked,
    });
    final decoded = _decode(response);
    return userFromApi(decoded['data'] as Map<String, dynamic>);
  }

  Future<void> changeUserPassword(String id, String password) async {
    await _patch('/admin/users/$id/password', {'password': password});
  }

  Future<List<Property>> properties() async {
    final data = await _getList('properties');
    return data.map(propertyFromApi).toList();
  }

  Future<List<Map<String, dynamic>>> auditLogs() => _getList('audit-logs');

  Future<Property> createProperty({
    required String title,
    required PropertyType type,
    required PropertyOfferType offerType,
    required int price,
    required String location,
    required String description,
    required String? imageUrl,
    required String? ownerId,
    String? tenantId,
  }) async {
    final response = await _post('/admin/properties', {
      'title': title,
      'type': propertyTypeToApi(type),
      'offer_type': offerTypeToApi(offerType),
      'status': propertyStatusToApi(PropertyStatus.available),
      'price': price,
      'location': location,
      'description': description,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      'features': ['Document verifie', 'Suivi agence', 'Disponible'],
      'owner_id': ownerId,
      'tenant_id': tenantId,
    });
    final decoded = _decode(response);
    return propertyFromApi(decoded['data'] as Map<String, dynamic>);
  }

  Future<Property> updateProperty({
    required String id,
    required String title,
    required PropertyType type,
    required PropertyOfferType offerType,
    required int price,
    required String location,
    required String description,
    required String? imageUrl,
    required String? ownerId,
    required String? tenantId,
    required PropertyStatus status,
  }) async {
    final response = await _patch('/admin/properties/$id', {
      'title': title,
      'type': propertyTypeToApi(type),
      'offer_type': offerTypeToApi(offerType),
      'status': propertyStatusToApi(status),
      'price': price,
      'location': location,
      'description': description,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      'owner_id': ownerId,
      'tenant_id': tenantId,
    });
    final decoded = _decode(response);
    return propertyFromApi(decoded['data'] as Map<String, dynamic>);
  }

  Future<void> deleteResource(String resource, String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/$resource/$id'),
      headers: _headers,
    );
    _decode(response);
  }

  Future<String> uploadImageDataUrl({
    required String fileName,
    required String dataUrl,
  }) async {
    final response = await _post('/admin/uploads/images', {
      'fileName': fileName,
      'dataUrl': dataUrl,
    });
    final decoded = _decode(response);
    return decoded['url']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> updateResource(
    String resource,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _patch('/admin/$resource/$id', body);
    final decoded = _decode(response);
    return decoded['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _getList(String resource) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/$resource'),
      headers: _headers,
    );
    final decoded = _decode(response);
    final data = decoded['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _patch(String path, Map<String, dynamic> body) {
    return http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
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
        decoded['message']?.toString() ?? 'Action impossible.',
      );
    }
    return decoded;
  }
}
