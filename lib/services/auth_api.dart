import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import 'api_config.dart';
import 'api_mappers.dart';
import 'app_session.dart';

class AuthApi {
  const AuthApi();

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _handleAuthResponse(response);
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.name,
      }),
    );

    return _handleAuthResponse(response);
  }

  AppUser _handleAuthResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        decoded['message']?.toString() ?? 'Authentification impossible.',
      );
    }

    final token = decoded['token']?.toString();
    final userJson = decoded['user'] as Map<String, dynamic>;
    final user = userFromApi(userJson);
    appSession.signIn(user, token: token);
    return user;
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
