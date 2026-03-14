import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_service.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

final apiHealthProvider = FutureProvider.autoDispose<HealthStatus>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  return healthService.checkHealth();
});
