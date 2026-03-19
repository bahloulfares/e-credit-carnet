import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ccns/providers/auth_provider.dart';
import 'package:ccns/providers/dashboard_provider.dart';
import 'package:ccns/providers/sync_queue_provider.dart';
import 'package:ccns/services/api_client.dart';
import 'package:ccns/services/dashboard_service.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient();

  @override
  String? get token => 'test-token';
}

class _FakeDashboardService extends DashboardService {
  bool shouldFail;
  int syncCalls = 0;

  _FakeDashboardService({this.shouldFail = false})
    : super(apiClient: _FakeApiClient());

  @override
  Future<Map<String, dynamic>> sync(List<Map<String, dynamic>> changes) async {
    syncCalls += 1;
    if (shouldFail) {
      throw ApiException(message: 'sync failed', statusCode: 500);
    }
    return {'message': 'ok', 'itemsSynced': changes.length, 'itemsFailed': 0};
  }
}

void main() {
  group('DashboardRefreshNotifier', () {
    test(
      'performSync returns early when a sync is already in progress',
      () async {
        final fakeService = _FakeDashboardService();
        final container = ProviderContainer(
          overrides: [dashboardServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(dashboardRefreshProvider.notifier);
        notifier.state = notifier.state.copyWith(isSyncing: true);

        final result = await notifier.performSync(const []);

        expect(result['message'], 'Sync already in progress');
        expect(fakeService.syncCalls, 0);
      },
    );

    test(
      'performSync always resets isSyncing to false when sync throws',
      () async {
        final fakeService = _FakeDashboardService(shouldFail: true);
        final container = ProviderContainer(
          overrides: [dashboardServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        container.read(syncQueueProvider.notifier).enqueue({
          'entityType': 'transaction',
          'entityId': 'tx-1',
          'operationType': 'UPDATE',
          'data': {'id': 'tx-1', 'amount': 12.0},
        });

        final notifier = container.read(dashboardRefreshProvider.notifier);

        await expectLater(
          notifier.performSync(const []),
          throwsA(isA<Exception>()),
        );

        final state = container.read(dashboardRefreshProvider);
        expect(state.isSyncing, isFalse);
        expect(state.hasSyncError, isTrue);
      },
    );
  });
}
