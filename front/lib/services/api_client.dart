import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class ApiClient {
  // Utilise baseUrl depuis app_constants.dart
  static const Duration timeout = Duration(seconds: 30);

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  String? _token;

  ApiClient({http.Client? httpClient, FlutterSecureStorage? secureStorage})
    : _httpClient = httpClient ?? http.Client(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _cachedUserKey = 'cached_user_profile';

  Future<void> initialize() async {
    _token = await _secureStorage.read(key: 'jwt_token');
  }

  Future<void> _saveUserCache(User user) async {
    await _secureStorage.write(
      key: _cachedUserKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<User?> loadUserCache() async {
    final raw = await _secureStorage.read(key: _cachedUserKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  ApiException _mapException(Object error) {
    if (error is ApiException) {
      return error;
    }

    if (error is TimeoutException) {
      return ApiException(
        message: 'Request timeout. Please try again.',
        statusCode: 408,
      );
    }

    if (error is http.ClientException) {
      return ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    }

    return ApiException(message: error.toString(), statusCode: 0);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    String? shopName,
    String? phone,
  }) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'firstName': firstName,
              'lastName': lastName,
              'password': password,
              'shopName': shopName,
              'phone': phone,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        await _secureStorage.write(key: 'jwt_token', value: _token);
        return data;
      } else {
        throw ApiException(
          message: jsonDecode(response.body)['error'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        await _secureStorage.write(key: 'jwt_token', value: _token);
        final user = User.fromJson(data['user']);
        await _saveUserCache(user);
        return data;
      } else {
        throw ApiException(
          message: jsonDecode(response.body)['error'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<User> getProfile() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$baseUrl/auth/profile'), headers: _getHeaders())
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        await _saveUserCache(user);
        return user;
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to get profile',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? phone,
  }) async {
    try {
      final response = await _httpClient
          .put(
            Uri.parse('$baseUrl/auth/profile'),
            headers: _getHeaders(),
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'shopName': shopName,
              'shopAddress': shopAddress,
              'shopPhone': shopPhone,
              'phone': phone,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to update profile',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _httpClient
          .post(Uri.parse('$baseUrl/auth/logout'), headers: _getHeaders())
          .timeout(timeout);
    } catch (_) {
      // Even if logout fails, clear local data
    } finally {
      _token = null;
      await _secureStorage.delete(key: 'jwt_token');
      await _secureStorage.delete(key: _cachedUserKey);
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  String? get token => _token;

  bool get isAuthenticated => _token != null;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
