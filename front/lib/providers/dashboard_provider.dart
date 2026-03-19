import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import 'auth_provider.dart';
import 'sync_queue_provider.dart';

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
    StateNotifierProvider<DashboardRefreshNotifier, DashboardRefreshState>((
      ref,
    ) {
      final dashboardService = ref.watch(dashboardServiceProvider);
      return DashboardRefreshNotifier(dashboardService, ref);
    });

class DashboardRefreshState {
  final bool isSyncing;
  final bool hasSyncError;
  final int retryCountdown;
  final int serverPendingSyncs;
  final DateTime? lastServerSyncAt;

  const DashboardRefreshState({
    this.isSyncing = false,
    this.hasSyncError = false,
    this.retryCountdown = 0,
    this.serverPendingSyncs = 0,
    this.lastServerSyncAt,
  });

  DashboardRefreshState copyWith({
    bool? isSyncing,
    bool? hasSyncError,
    int? retryCountdown,
    int? serverPendingSyncs,
    DateTime? lastServerSyncAt,
  }) {
    return DashboardRefreshState(
      isSyncing: isSyncing ?? this.isSyncing,
      hasSyncError: hasSyncError ?? this.hasSyncError,
      retryCountdown: retryCountdown ?? this.retryCountdown,
      serverPendingSyncs: serverPendingSyncs ?? this.serverPendingSyncs,
      lastServerSyncAt: lastServerSyncAt ?? this.lastServerSyncAt,
    );
  }
}

class DashboardRefreshNotifier extends StateNotifier<DashboardRefreshState> {
  final DashboardService dashboardService;
  final Ref ref;
  DateTime? _lastRefreshAt;
  Timer? _retryCountdownTimer;
  int _autoRetryAttempt = 0;

  DashboardRefreshNotifier(this.dashboardService, this.ref)
    : super(const DashboardRefreshState());

  Future<void> refreshStats() async {
    if (state.isSyncing) {
      return;
    }

    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < const Duration(milliseconds: 800)) {
      return;
    }

    state = state.copyWith(isSyncing: true);
    _lastRefreshAt = now;
    try {
      // Invalidate the provider to refetch data
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(syncStatusProvider);
      await _refreshSyncSignalsSilently();
    } catch (e) {
      // Handle error silently, providers will handle it
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<Map<String, dynamic>> performSync(
    List<Map<String, dynamic>> changes,
  ) async {
    if (state.isSyncing) {
      return {
        'message': 'Sync already in progress',
        'itemsSynced': 0,
        'itemsFailed': 0,
      };
    }

    state = state.copyWith(isSyncing: true);
    try {
      final pendingChanges = changes.isNotEmpty
          ? changes
          : await ref.read(syncQueueProvider.notifier).snapshot();

      if (pendingChanges.isEmpty) {
        return {
          'message': 'No local changes to sync',
          'itemsSynced': 0,
          'itemsFailed': 0,
        };
      }

      final result = await dashboardService.sync(pendingChanges);
      ref.read(syncQueueProvider.notifier).clear();
      _retryCountdownTimer?.cancel();
      _autoRetryAttempt = 0;
      state = state.copyWith(hasSyncError: false, retryCountdown: 0);

      // Refresh stats after sync
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(syncStatusProvider);
      await _refreshSyncSignalsSilently();
      return result;
    } catch (e) {
      _autoRetryAttempt += 1;
      state = state.copyWith(hasSyncError: true);
      await _refreshSyncSignalsSilently();
      _scheduleAutoRetry();
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  void _scheduleAutoRetry() {
    _retryCountdownTimer?.cancel();
    final delaySeconds = _computeRetryDelaySeconds();
    state = state.copyWith(retryCountdown: delaySeconds);

    _retryCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (state.retryCountdown > 1) {
        state = state.copyWith(retryCountdown: state.retryCountdown - 1);
        return;
      }

      timer.cancel();
      state = state.copyWith(retryCountdown: 0);
      try {
        await performSync(const []);
      } catch (_) {
        // L'echec est deja gere par performSync (nouvelle planification).
      }
    });
  }

  int _computeRetryDelaySeconds() {
    final exponent = (_autoRetryAttempt - 1).clamp(0, 4);
    return (5 * (1 << exponent)).clamp(5, 60);
  }

  Future<void> _refreshSyncSignalsSilently() async {
    try {
      final raw = await dashboardService.getSyncStatus();
      final sourceRaw = raw['syncStatus'] ?? raw;
      if (sourceRaw is! Map) {
        return;
      }

      final source = Map<String, dynamic>.from(sourceRaw);

      final syncStatus = SyncStatus.fromJson(source);
      final lastServerSyncAt =
          syncStatus.lastSync?.syncEndTime ??
          syncStatus.lastSync?.syncStartTime;

      state = state.copyWith(
        serverPendingSyncs: syncStatus.pendingSyncs,
        lastServerSyncAt: lastServerSyncAt,
      );
    } catch (_) {
      // Keep sync status handling fully automatic and silent.
    }
  }

  @override
  void dispose() {
    _retryCountdownTimer?.cancel();
    super.dispose();
  }
}
