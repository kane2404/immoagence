import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_mappers.dart';

class AppSession extends ChangeNotifier {
  static const _tokenKey = 'immo_session_token';
  static const _idKey = 'immo_session_user_id';
  static const _nameKey = 'immo_session_user_name';
  static const _emailKey = 'immo_session_user_email';
  static const _phoneKey = 'immo_session_user_phone';
  static const _roleKey = 'immo_session_user_role';

  AppUser? _user;
  String? _token;
  bool _isRestored = false;

  AppUser? get user => _user;

  String? get token => _token;

  UserRole get role => _user?.role ?? UserRole.visitor;

  bool get isAuthenticated => _user != null;

  bool get isRestored => _isRestored;

  bool get isVisitor => !isAuthenticated;

  bool get isAdmin => role == UserRole.admin || role == UserRole.agent;

  Future<void> restore() async {
    if (_isRestored) return;

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_idKey);
    final name = prefs.getString(_nameKey);
    final role = prefs.getString(_roleKey);

    if (id != null && name != null && role != null) {
      _user = AppUser(
        id: id,
        fullName: name,
        email: prefs.getString(_emailKey),
        phone: prefs.getString(_phoneKey) ?? '',
        role: roleFromApi(role),
      );
      _token = prefs.getString(_tokenKey);
    }

    _isRestored = true;
    notifyListeners();
  }

  void signIn(AppUser user, {String? token}) {
    _user = user;
    _token = token;
    _persist();
    notifyListeners();
  }

  void updateProfile({
    required String fullName,
    required String email,
    required String phone,
  }) {
    final currentUser = _user;
    if (currentUser == null) return;

    _user = currentUser.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
    );
    _persist();
    notifyListeners();
  }

  void register({
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) {
    _user = AppUser(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
    );
    _token = null;
    _persist();
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _token = null;
    _clearPersisted();
    notifyListeners();
  }

  Future<void> _persist() async {
    final currentUser = _user;
    final prefs = await SharedPreferences.getInstance();

    if (currentUser == null) {
      await _clearPersisted();
      return;
    }

    await prefs.setString(_idKey, currentUser.id);
    await prefs.setString(_nameKey, currentUser.fullName);
    await prefs.setString(_emailKey, currentUser.email ?? '');
    await prefs.setString(_phoneKey, currentUser.phone);
    await prefs.setString(_roleKey, roleToApi(currentUser.role));
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_idKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_roleKey);
  }
}

final appSession = AppSession();
