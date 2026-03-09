import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/client_model.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class ClientService {
  static const String endpoint = '$baseUrl/clients';
  final ApiClient apiClient;
  final http.Client httpClient;

  ClientService({required this.apiClient, http.Client? httpClient})
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

  Future<List<Client>> getClients({int skip = 0, int take = 10}) async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$endpoint?skip=$skip&take=$take'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['clients'] as List)
            .map((e) => Client.fromJson(e))
            .toList();
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to load clients',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<Client> getClient(String clientId) async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$endpoint/$clientId'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Client.fromJson(data['client']);
      } else {
        throw ApiException(
          message: jsonDecode(response.body)['error'] ?? 'Client not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<Client> createClient({
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await httpClient
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiClient.token}',
            },
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'phone': phone,
              'email': email,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Client.fromJson(data['client']);
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to create client',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<Client> updateClient(
    String clientId, {
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await httpClient
          .put(
            Uri.parse('$endpoint/$clientId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiClient.token}',
            },
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'phone': phone,
              'email': email,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Client.fromJson(data['client']);
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to update client',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      final response = await httpClient
          .delete(
            Uri.parse('$endpoint/$clientId'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ?? 'Failed to delete client',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<List<Client>> searchClients(String query) async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$endpoint/search?q=$query'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['clients'] as List)
            .map((e) => Client.fromJson(e))
            .toList();
      } else {
        throw ApiException(
          message: jsonDecode(response.body)['error'] ?? 'Search failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> setClientStatus(String id, bool isActive) async {
    try {
      final response = await httpClient
          .patch(
            Uri.parse('$endpoint/$id/status'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiClient.token}',
            },
            body: jsonEncode({'isActive': isActive}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to update client status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }
}
