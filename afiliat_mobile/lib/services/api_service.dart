import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../l10n/app_translations.dart';
import '../screens/login_page.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  static String get _baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) {
      return 'http://164.92.178.58/api';
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://164.92.178.58/api';
      }
    } catch (_) {}
    return 'http://164.92.178.58/api';
  }

  static ApiService? _instance;
  ApiService._();
  static ApiService get instance => _instance ??= ApiService._();

  static String get imageUrlPrefix => _baseUrl.replaceAll('/api', '/storage/');

  static String getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$_baseUrl/image?path=$path';
  }

  // In-memory cache for static config endpoints
  final Map<String, dynamic> _cache = {};

  void clearCache() {
    _cache.clear();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final cacheKey = '$path:${query ?? ''}';
    final isCacheable = path == '/delivery/territories' || path == '/delivery/rates' || path == '/app/settings';

    if (isCacheable && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final res = await http
          .get(_uri(path, query), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      final parsed = _parse(res);
      if (isCacheable) {
        _cache[cacheKey] = parsed;
      }
      return parsed;
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService GET error on $path: $e');
      throw ApiException(
        _translateMessage('Connection timeout or network error. Please try again.'),
        500,
      );
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _parse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService POST error on $path: $e');
      throw ApiException(
        _translateMessage('Connection timeout or network error. Please try again.'),
        500,
      );
    }
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await http
          .patch(
            _uri(path),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _parse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService PATCH error on $path: $e');
      throw ApiException(
        _translateMessage('Connection timeout or network error. Please try again.'),
        500,
      );
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await http
          .put(
            _uri(path),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _parse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService PUT error on $path: $e');
      throw ApiException(
        _translateMessage('Connection timeout or network error. Please try again.'),
        500,
      );
    }
  }

  dynamic _parse(http.Response res) {
    if (res.statusCode == 401) {
      final path = res.request?.url.path ?? '';
      final isAuthRoute = path.contains('/auth/');

      if (!isAuthRoute) {
        clearCache();
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('access_token');
          prefs.remove('user');
        });
        if (mainNavigatorKey.currentContext != null) {
          Navigator.of(mainNavigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
        throw ApiException(
          _translateMessage('Session expired. Please login again.'),
          401,
        );
      }
    }

    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (e) {
      debugPrint('ApiService JSON decode error on status ${res.statusCode}: $e');
      throw ApiException(
        _translateMessage('Server returned an error (${res.statusCode}).'),
        res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message =
        body['message'] ??
        (body['errors'] != null
            ? (body['errors'] as Map).values.expand((e) => e as List).join('\n')
            : 'Request failed (${res.statusCode})');
    throw ApiException(_translateMessage(message.toString()), res.statusCode);
  }

  String _translateMessage(String message) {
    return message
        .split('\n')
        .map(
          (line) => AppTranslations.translate(
            line,
            localeNotifier.value.languageCode,
          ),
        )
        .join('\n');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
