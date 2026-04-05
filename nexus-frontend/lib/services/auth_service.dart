import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Manages authentication state (token + current user) and persists
/// the session to shared preferences.
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // ── Initialise from persisted storage ─────────────────────────────────────
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userJson = prefs.getString(AppConstants.userKey);

    if (token == null || userJson == null) return false;

    _token = token;
    _currentUser = UserModel.fromJson(
      jsonDecode(userJson) as Map<String, dynamic>,
    );
    ApiService.instance.setToken(token);
    notifyListeners();
    return true;
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String phoneNumber = '',
  }) async {
    _setLoading(true);
    try {
      final data = await ApiService.instance.register(
        username: username,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      await _persistSession(data);
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final data =
          await ApiService.instance.login(email: email, password: password);
      await _persistSession(data);
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await ApiService.instance.logout();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);

    _token = null;
    _currentUser = null;
    notifyListeners();
  }

  // ── Update local user cache ────────────────────────────────────────────────
  Future<void> updateCurrentUser(UserModel updated) async {
    _currentUser = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(updated.toJson()));
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    _token = token;
    _currentUser = user;
    ApiService.instance.setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
