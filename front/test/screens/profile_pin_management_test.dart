import 'package:ccns/l10n/app_localizations.dart';
import 'package:ccns/models/user_model.dart';
import 'package:ccns/providers/app_lock_provider.dart';
import 'package:ccns/providers/auth_provider.dart';
import 'package:ccns/screens/profile_screen.dart';
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
  FakeAuthNotifier(AuthState initial) : super(FakeApiClient(initial.user!)) {
    state = initial;
  }
}

void main() {
  User buildUser() {
    return User(
      id: '1',
      email: 'epicier@test.com',
      firstName: 'Ali',
      lastName: 'Shop',
      role: 'EPICIER',
      subscriptionStatus: 'ACTIVE',
    );
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    required AppLockNotifier lockNotifier,
  }) async {
    final authState = AuthState(
      user: buildUser(),
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
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows enable PIN action when no PIN is configured', (
    tester,
  ) async {
    final storage = InMemoryAppLockStorage();
    final lockNotifier = AppLockNotifier(storage: storage, iterations: 1);
    await lockNotifier.ready();

    await pumpProfile(tester, lockNotifier: lockNotifier);

    expect(find.text('Activer le verrouillage PIN'), findsOneWidget);
    expect(find.text('Changer le code PIN'), findsNothing);
    expect(find.text('Desactiver le verrouillage PIN'), findsNothing);
    expect(find.text('Verrouiller maintenant'), findsNothing);
  });

  testWidgets('shows lock now action and locks app when tapped', (
    tester,
  ) async {
    final storage = InMemoryAppLockStorage();
    final lockNotifier = AppLockNotifier(storage: storage, iterations: 1);
    await lockNotifier.ready();
    await lockNotifier.setupPin('1234');

    await pumpProfile(tester, lockNotifier: lockNotifier);

    expect(find.text('Verrouiller maintenant'), findsOneWidget);

    await tester.ensureVisible(find.text('Verrouiller maintenant'));
    await tester.tap(find.text('Verrouiller maintenant'));
    await tester.pumpAndSettle();

    expect(lockNotifier.state.isLocked, isTrue);
    expect(find.text('Application verrouillee'), findsOneWidget);
  });
}
