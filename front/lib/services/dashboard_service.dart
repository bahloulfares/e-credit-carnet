import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_model.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class DashboardService {
  static const String endpoint = '$baseUrl/dashboard';
  final ApiClient apiClient;
  final http.Client httpClient;

  DashboardService({required this.apiClient, http.Client? httpClient})
    : httpClient = httpClient ?? http.Client();

  Future<DashboardStats> getStats() async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$endpoint/stats'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardStats.fromJson(data['stats']);
      } else {
        throw ApiException(
          message: jsonDecode(response.body)['error'] ?? 'Failed to load stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$endpoint/sync-status'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to load sync status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  Future<Map<String, dynamic>> sync(List<Map<String, dynamic>> changes) async {
    try {
      final response = await httpClient
          .post(
            Uri.parse('$baseUrl/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiClient.token}',
            },
            body: jsonEncode({'changes': changes}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(
          message: jsonDecode(response.body)['error'] ?? 'Sync failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }
}
