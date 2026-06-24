import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static AuthService? _instance;
  AuthService._();
  static AuthService get instance => _instance ??= AuthService._();

  final _api = ApiService.instance;

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data =
        await _api.post(
              '/auth/login',
              body: {'email': email, 'password': password},
            )
            as Map<String, dynamic>;

    final user = Map<String, dynamic>.from(data['user'] as Map);
    if (user['role'] != 'marketer') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user');
      throw ApiException('Please sign in with a marketer account.', 403);
    }

    await _persist(data);
    return data;
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    final data =
        await _api.post(
              '/auth/register',
              body: {
                'name': name,
                'email': email,
                'password': password,
                if (phone != null && phone.isNotEmpty) 'phone': phone,
              },
            )
            as Map<String, dynamic>;

    await _persist(data);
    return data;
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
  }

  // ─── Verify Code ──────────────────────────────────────────────────────────
  Future<void> verifyCode(String email, String token) async {
    await _api.post(
      '/auth/verify-code',
      body: {'email': email, 'token': token},
    );
  }

  // ─── Reset Password ───────────────────────────────────────────────────────
  Future<void> resetPassword(String email, String token, String password, String passwordConfirmation) async {
    await _api.post(
      '/auth/reset-password',
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    _api.clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user');
  }

  // ─── Me ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> me() async {
    return (await _api.get('/me')) as Map<String, dynamic>;
  }

  // ─── Token helpers ────────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('access_token') == null) return false;

    try {
      final user = await me();
      if (user['role'] == 'marketer') {
        await prefs.setString('user', jsonEncode(user));
        return true;
      }
    } catch (_) {}

    await prefs.remove('access_token');
    await prefs.remove('user');
    return false;
  }

  Future<Map<String, dynamic>?> cachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  // ─── Persist token + user ─────────────────────────────────────────────────
  Future<void> _persist(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token'] as String);
    await prefs.setString('user', jsonEncode(data['user']));
  }
}
