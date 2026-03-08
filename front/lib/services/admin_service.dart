import 'dart:convert';
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
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 0);
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
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 0);
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
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 0);
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
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 0);
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
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }
}
