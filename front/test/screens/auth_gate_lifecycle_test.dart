import 'package:ccns/main.dart';
import 'package:ccns/models/user_model.dart';
import 'package:ccns/providers/app_lock_provider.dart';
import 'package:ccns/providers/auth_provider.dart';
import 'package:ccns/screens/app_lock_screen.dart';
import 'package:ccns/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryAppLockStorage implements AppLockStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}

class FakeApiClient extends ApiClient {
  final User user;

  FakeApiClient(this.user);

  @override
  Future<void> initialize() async {}

  @override
  bool get isAuthenticated => true;

  @override
  Future<User> getProfile() async => user;

  @override
  Future<void> logout() async {}
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AuthState initial)
    : super(
        FakeApiClient(
          initial.user ??
              User(
                id: '1',
                email: 'admin@test.com',
                firstName: 'Admin',
                lastName: 'User',
                role: 'SUPER_ADMIN',
                subscriptionStatus: 'ACTIVE',
              ),
        ),
      ) {
    state = initial;
  }
}

void main() {
  testWidgets('AuthGate locks app after configured background timeout', (
    tester,
  ) async {
    var now = DateTime(2026, 3, 14, 10, 0, 0);

    final storage = InMemoryAppLockStorage();
    final lockNotifier = AppLockNotifier(storage: storage, iterations: 1);
    await lockNotifier.ready();
    await lockNotifier.setupPin('1234');

    final user = User(
      id: '42',
      email: 'boss@shop.com',
      firstName: 'Boss',
      lastName: 'Admin',
      role: 'SUPER_ADMIN',
      subscriptionStatus: 'ACTIVE',
    );

    final authState = AuthState(
      user: user,
      isAuthenticated: true,
      isLoading: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockProvider.overrideWith((ref) => lockNotifier),
          authStateProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
        ],
        child: MaterialApp(
          home: AuthGateScreen(
            lockTimeout: const Duration(seconds: 1),
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(lockNotifier.state.isLocked, isFalse);
    expect(find.byType(AppLockScreen), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    now = now.add(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(lockNotifier.state.isLocked, isTrue);
    expect(find.byType(AppLockScreen), findsOneWidget);
  });
}
