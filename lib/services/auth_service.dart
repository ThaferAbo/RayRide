import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import 'http_client_factory.dart'
    if (dart.library.io) 'http_client_factory_native.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthService {
  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const int _port = 9001;

  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  AuthService({
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? createHttpClient();

  // ─── Platform-aware storage ─────────────────────────────

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return await _secureStorage.read(key: key);
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ─── Base URL ───────────────────────────────────────────

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://10.0.2.2:$_port';
    }
    return 'https://localhost:$_port';
  }

  // ─── Register ───────────────────────────────────────────

  Future<AuthResponse?> register(RegisterRequest request) async {
    final url = Uri.parse('$baseUrl/api/Account/register');

    final http.Response response;
    try {
      response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
    } catch (e) {
      throw AuthException(
        'Could not connect to the server. Please check your internet connection.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _saveRegistrationInfo(request);
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final authResponse = AuthResponse.fromJson(body);
          await _saveTokens(authResponse);
          return authResponse;
        }
      } on FormatException {
        // API returned plain text (e.g. "User Registered Successfully")
      }
      return null;
    }

    _handleErrorResponse(response);
  }

  // ─── Login ──────────────────────────────────────────────

  Future<AuthResponse> login(LoginRequest request) async {
    final url = Uri.parse('$baseUrl/api/Account/authenticate');

    final http.Response response;
    try {
      response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
    } catch (e) {
      throw AuthException(
        'Could not connect to the server. Please check your internet connection.',
      );
    }

    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(body);
        await _saveTokens(authResponse);
        return authResponse;
      } on FormatException {
        throw AuthException(
          'Received an invalid response format from the server.',
          statusCode: response.statusCode,
        );
      }
    }

    _handleErrorResponse(response);
  }

  // ─── Token & user data management ─────────────────────

  Future<String?> getToken() async {
    return await _read(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await _read(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> logout() async {
    await _deleteAll();
  }

  // ─── Private helpers ───────────────────────────────────

  Never _handleErrorResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw AuthException(
        response.body.isNotEmpty
            ? response.body
            : 'An unexpected error occurred. (Code: ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final message = _extractErrorMessage(body);
    throw AuthException(message, statusCode: response.statusCode);
  }

  Future<void> _saveRegistrationInfo(RegisterRequest request) async {
    await _write(
      _userKey,
      jsonEncode({
        'firstName': request.firstName,
        'lastName': request.lastName,
        'userName': request.userName,
        'email': request.email,
      }),
    );
  }

  Future<void> _saveTokens(AuthResponse auth) async {
    await _write(_tokenKey, auth.jwToken);
    if (auth.refreshToken != null) {
      await _write(_refreshTokenKey, auth.refreshToken!);
    }

    final existing = await getUserData() ?? {};
    existing['id'] = auth.id;
    existing['userName'] = auth.userName;
    existing['email'] = auth.email;
    existing['roles'] = auth.roles;

    await _write(_userKey, jsonEncode(existing));
  }

  String _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      // .NET API format: {"Message": "...", "Errors": [...]}
      final msg = body['Message'] ?? body['message'];
      if (msg is String && msg.isNotEmpty) return msg;

      final errors = body['Errors'] ?? body['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.join('\n');
      }
      if (errors is Map) {
        final messages = <String>[];
        for (final entry in errors.entries) {
          if (entry.value is List) {
            messages.addAll((entry.value as List).map((e) => e.toString()));
          }
        }
        if (messages.isNotEmpty) return messages.join('\n');
      }

      if (body.containsKey('title')) return body['title'];
    }
    return 'An error occurred while processing the request.';
  }
}
