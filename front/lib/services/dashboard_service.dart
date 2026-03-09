import 'dart:convert';
import 'dart:async';
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
      throw _mapException(e);
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
      throw _mapException(e);
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
      throw _mapException(e);
    }
  }
}
