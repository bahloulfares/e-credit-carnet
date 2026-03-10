import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/admin_epicier_model.dart';
import '../models/client_model.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class AdminService {
  static const String endpoint = '$baseUrl/admin';

  final ApiClient apiClient;
  final http.Client httpClient;

  AdminService({required this.apiClient, http.Client? httpClient})
    : httpClient = httpClient ?? http.Client();

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

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${apiClient.token}',
  };

  Future<List<AdminEpicier>> getEpiciers({
    String? search,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final query = <String, String>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'skip': '$skip',
        'take': '$take',
      };

      final uri = Uri.parse(
        '$endpoint/epiciers',
      ).replace(queryParameters: query);

      final response = await httpClient
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to load epiciers',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['epiciers'] as List<dynamic>? ?? [])
          .map((e) => AdminEpicier.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<AdminGlobalStats> getGlobalStats() async {
    try {
      final response = await httpClient
          .get(Uri.parse('$endpoint/stats'), headers: _headers())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to load admin global stats',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final stats = (data['stats'] as Map<String, dynamic>? ?? {});
      return AdminGlobalStats.fromJson(stats);
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> setEpicierStatus(String id, bool isActive) async {
    try {
      final response = await httpClient
          .patch(
            Uri.parse('$endpoint/epiciers/$id/status'),
            headers: _headers(),
            body: jsonEncode({'isActive': isActive}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to update status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> resetEpicierPassword(String id, String newPassword) async {
    try {
      final response = await httpClient
          .post(
            Uri.parse('$endpoint/epiciers/$id/reset-password'),
            headers: _headers(),
            body: jsonEncode({'newPassword': newPassword}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<List<Client>> getEpicierClients(
    String epicierId, {
    int skip = 0,
    int take = 50,
  }) async {
    try {
      final uri = Uri.parse(
        '$endpoint/epiciers/$epicierId/clients',
      ).replace(queryParameters: {'skip': '$skip', 'take': '$take'});

      final response = await httpClient
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to load epicier clients',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['clients'] as List<dynamic>? ?? [])
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<AdminEpicier> createEpicier({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    String? phone,
    String? shopName,
  }) async {
    try {
      final response = await httpClient
          .post(
            Uri.parse('$endpoint/epiciers'),
            headers: _headers(),
            body: jsonEncode({
              'email': email,
              'firstName': firstName,
              'lastName': lastName,
              'password': password,
              if (phone != null && phone.isNotEmpty) 'phone': phone,
              if (shopName != null && shopName.isNotEmpty) 'shopName': shopName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 201) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to create epicier',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminEpicier.fromJson(data['epicier'] as Map<String, dynamic>);
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<AdminEpicier> updateEpicier(
    String id, {
    String? firstName,
    String? lastName,
    String? phone,
    String? shopName,
  }) async {
    try {
      final response = await httpClient
          .patch(
            Uri.parse('$endpoint/epiciers/$id'),
            headers: _headers(),
            body: jsonEncode({
              if (firstName != null) 'firstName': firstName,
              if (lastName != null) 'lastName': lastName,
              if (phone != null) 'phone': phone,
              if (shopName != null) 'shopName': shopName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to update epicier',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminEpicier.fromJson(data['epicier'] as Map<String, dynamic>);
    } catch (e) {
      throw _mapException(e);
    }
  }
}
