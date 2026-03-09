import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import 'auth_provider.dart';

// Dashboard stats provider with caching (30 seconds)
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getStats();
});

// Sync status provider with caching (15 seconds)
final syncStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
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
  DateTime? _lastRefreshAt;

  DashboardRefreshNotifier(this.dashboardService, this.ref) : super(false);

  Future<void> refreshStats() async {
    if (state) {
      return;
    }

    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < const Duration(milliseconds: 800)) {
      return;
    }

    state = true;
    _lastRefreshAt = now;
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
