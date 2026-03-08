import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import 'auth_provider.dart';

// Dashboard stats provider
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getStats();
});

// Sync status provider
final syncStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getSyncStatus();
});

// Dashboard State Notifier for refresh operations
final dashboardRefreshProvider =
    StateNotifierProvider<DashboardRefreshNotifier, bool>((ref) {
      final dashboardService = ref.watch(dashboardServiceProvider);
      return DashboardRefreshNotifier(dashboardService, ref);
    });

class DashboardRefreshNotifier extends StateNotifier<bool> {
  final DashboardService dashboardService;
  final Ref ref;

  DashboardRefreshNotifier(this.dashboardService, this.ref) : super(false);

  Future<void> refreshStats() async {
    state = true;
    try {
      // Invalidate the provider to refetch data
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(syncStatusProvider);
    } catch (e) {
      // Handle error silently, providers will handle it
    } finally {
      state = false;
    }
  }

  Future<Map<String, dynamic>> performSync(
    List<Map<String, dynamic>> changes,
  ) async {
    state = true;
    try {
      final result = await dashboardService.sync(changes);
      // Refresh stats after sync
      await refreshStats();
      return result;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}
