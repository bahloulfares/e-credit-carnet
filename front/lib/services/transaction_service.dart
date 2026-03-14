import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class TransactionService {
  static const String endpoint = '$baseUrl/transactions';
  final ApiClient apiClient;
  final http.Client httpClient;

  TransactionService({required this.apiClient, http.Client? httpClient})
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

  Future<List<Transaction>> getTransactions({
    String? clientId,
    int skip = 0,
    int take = 20,
    String? type,
    bool? isPaid,
    int? month,
    int? year,
  }) async {
    try {
      String url = '$endpoint?skip=$skip&take=$take';
      if (clientId != null) {
        url += '&clientId=$clientId';
      }
      if (type != null && type != 'ALL') {
        url += '&type=$type';
      }
      if (isPaid != null) {
        url += '&isPaid=$isPaid';
      }
      if (month != null) {
        url += '&month=$month';
      }
      if (year != null) {
        url += '&year=$year';
      }

      final response = await httpClient
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['transactions'] as List)
            .map((e) => Transaction.fromJson(e))
            .toList();
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to load transactions',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<Transaction> getTransactionById(String transactionId) async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$endpoint/$transactionId'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data['transaction']);
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to load transaction',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<Transaction> createTransaction({
    required String clientId,
    required String type,
    required double amount,
    String? description,
    DateTime? dueDate,
    String? paymentMethod,
  }) async {
    try {
      final response = await httpClient
          .post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer ${apiClient.token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'clientId': clientId,
              'type': type,
              'amount': amount,
              'description': description,
              'dueDate': dueDate?.toIso8601String(),
              'paymentMethod': paymentMethod,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data['transaction']);
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to create transaction',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<Transaction> updateTransaction(
    String transactionId, {
    double? amount,
    String? description,
    DateTime? dueDate,
    String? paymentMethod,
  }) async {
    try {
      final response = await httpClient
          .put(
            Uri.parse('$endpoint/$transactionId'),
            headers: {
              'Authorization': 'Bearer ${apiClient.token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'amount': amount,
              'description': description,
              'dueDate': dueDate?.toIso8601String(),
              'paymentMethod': paymentMethod,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data['transaction']);
      } else {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to update transaction',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final response = await httpClient
          .delete(
            Uri.parse('$endpoint/$transactionId'),
            headers: {'Authorization': 'Bearer ${apiClient.token}'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ApiException(
          message:
              jsonDecode(response.body)['error'] ??
              'Failed to delete transaction',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }
}
