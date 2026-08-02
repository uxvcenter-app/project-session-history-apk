import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_config.dart';

/// Exception levée pour toute erreur retournée par l'API (avec le message
/// lisible renvoyé par le backend, ex: "Email ou mot de passe incorrect.").
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Client HTTP centralisé pour parler au backend ASP.NET Core.
/// Gère l'ajout automatique du token JWT et le parsing des erreurs.
class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  static const _tokenKey = 'jwt_token';
  String? _cachedToken;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<String?> get token async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = 'Une erreur est survenue (${response.statusCode}).';
    try {
      final body = _decode(response);
      if (body is Map && body['message'] != null) {
        message = body['message'] as String;
      } else if (body is Map && body['title'] != null) {
        message = body['title'] as String; // erreurs de validation ASP.NET
      }
    } catch (_) {
      // corps non-JSON, on garde le message générique
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ---------------- AUTH ----------------

  Future<String> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/register'),
      headers: await _headers(),
      body: jsonEncode({'fullName': fullName, 'email': email, 'password': password}),
    );
    _throwIfError(response);
    final body = _decode(response);
    return body['message'] as String;
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      _uri('/api/auth/verify-email'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'code': code}),
    );
    _throwIfError(response);
    final body = _decode(response) as Map<String, dynamic>;
    await saveToken(body['token'] as String);
    return body;
  }

  Future<String> resendCode(String email) async {
    final response = await http.post(
      _uri('/api/auth/resend-code'),
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );
    _throwIfError(response);
    final body = _decode(response);
    return body['message'] as String;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    _throwIfError(response);
    final body = _decode(response) as Map<String, dynamic>;
    await saveToken(body['token'] as String);
    return body;
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<String> forgotPassword(String email) async {
    final response = await http.post(
      _uri('/api/auth/forgot-password'),
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );
    _throwIfError(response);
    final body = _decode(response);
    return body['message'] as String;
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      _uri('/api/auth/reset-password'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    _throwIfError(response);
    final body = _decode(response);
    return body['message'] as String;
  }

  // ---------------- SESSIONS ----------------

  Future<List<dynamic>> getSessions() async {
    final response = await http.get(_uri('/api/sessions'), headers: await _headers(auth: true));
    _throwIfError(response);
    return _decode(response) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri('/api/sessions'),
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    _throwIfError(response);
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSession(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      _uri('/api/sessions/$id'),
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    _throwIfError(response);
    return _decode(response) as Map<String, dynamic>;
  }

  Future<void> deleteSession(String id) async {
    final response = await http.delete(_uri('/api/sessions/$id'), headers: await _headers(auth: true));
    _throwIfError(response);
  }

  Future<List<dynamic>> searchSessions(String query) async {
    final response = await http.get(
      _uri('/api/sessions/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: await _headers(auth: true),
    );
    _throwIfError(response);
    return _decode(response) as List<dynamic>;
  }
}
