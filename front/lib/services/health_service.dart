import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class HealthStatus {
  final bool reachable;
  final String? status;
  final DateTime? timestamp;
  final String endpoint;
  final String? error;

  HealthStatus({
    required this.reachable,
    required this.endpoint,
    this.status,
    this.timestamp,
    this.error,
  });
}

class HealthService {
  final http.Client httpClient;

  HealthService({http.Client? httpClient})
    : httpClient = httpClient ?? http.Client();

  Uri _buildHealthUri() {
    final apiUri = Uri.parse(baseUrl);
    final segments = List<String>.from(apiUri.pathSegments);

    if (segments.isNotEmpty && segments.last == 'api') {
      segments.removeLast();
    }

    return apiUri.replace(pathSegments: [...segments, 'health']);
  }

  Future<HealthStatus> checkHealth() async {
    final uri = _buildHealthUri();

    try {
      final response = await httpClient
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return HealthStatus(
          reachable: false,
          endpoint: uri.toString(),
          error: 'HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawTimestamp = data['timestamp']?.toString();

      return HealthStatus(
        reachable: true,
        endpoint: uri.toString(),
        status: data['status']?.toString(),
        timestamp: rawTimestamp == null
            ? null
            : DateTime.tryParse(rawTimestamp),
      );
    } on TimeoutException {
      return HealthStatus(
        reachable: false,
        endpoint: uri.toString(),
        error: 'Timeout',
      );
    } on http.ClientException catch (e) {
      return HealthStatus(
        reachable: false,
        endpoint: uri.toString(),
        error: e.message,
      );
    } catch (e) {
      return HealthStatus(
        reachable: false,
        endpoint: uri.toString(),
        error: e.toString(),
      );
    }
  }
}
