import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static AuthService? _instance;
  AuthService._();
  static AuthService get instance => _instance ??= AuthService._();

  final _api = ApiService.instance;

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    await _persist(data);
    return data;
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(
      String name, String email, String password, {String? phone}) async {
    final data = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    }) as Map<String, dynamic>;

    await _persist(data);
    return data;
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
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
    return prefs.getString('access_token') != null;
  }

  Future<Map<String, dynamic>?> cachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw == null) return null;
    // Parse stored user JSON
    try {
      return Map<String, dynamic>.from(
        (await _api.get('/me')) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Persist token + user ─────────────────────────────────────────────────
  Future<void> _persist(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token'] as String);
  }
}
