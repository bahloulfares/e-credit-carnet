import 'package:ccns/l10n/app_localizations.dart';
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
  @override
  Future<void> initialize() async {}

  @override
  bool get isAuthenticated => true;

  @override
  Future<User> getProfile() async {
    return User(
      id: 'u1',
      email: 'epicier@test.com',
      firstName: 'Ali',
      lastName: 'Shop',
      role: 'EPICIER',
      subscriptionStatus: 'ACTIVE',
    );
  }

  @override
  Future<void> logout() async {}
}

class FakeAuthNotifier extends AuthNotifier {
  int logoutCalls = 0;

  FakeAuthNotifier() : super(FakeApiClient()) {
    state = AuthState(
      isAuthenticated: true,
      user: User(
        id: 'u1',
        email: 'epicier@test.com',
        firstName: 'Ali',
        lastName: 'Shop',
        role: 'EPICIER',
        subscriptionStatus: 'ACTIVE',
      ),
    );
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    state = AuthState();
  }
}

Future<void> _enterPinDigits(
  WidgetTester tester,
  List<int> digitIndices, {
  bool settle = true,
}) async {
  final buttons = find.byType(TextButton);
  expect(buttons, findsWidgets);
  for (final index in digitIndices) {
    await tester.tap(buttons.at(index));
    await tester.pump();
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Drain microtasks without advancing fake clock into the 1-second timer.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }
}

void main() {
  Future<void> enterWrongPinCycle(WidgetTester tester) async {
    await _enterPinDigits(tester, [8, 8, 8, 8]);
    await _enterPinDigits(tester, [8, 8, 8, 8], settle: false);
    await _enterPinDigits(tester, [8, 8, 8, 8], settle: false);
  }

  testWidgets('AppLockScreen unlocks when correct PIN is entered', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final storage = InMemoryAppLockStorage();
    final notifier = AppLockNotifier(storage: storage, iterations: 1);
    await notifier.ready();
    await notifier.setupPin('1234');
    notifier.lock();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AppLockScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(notifier.state.isLocked, isTrue);

    // Digit order in keypad buttons: 1,2,3,4,5,6,7,8,9,0.
    await _enterPinDigits(tester, [0, 1, 2, 3]);

    expect(notifier.state.isLocked, isFalse);
    expect(notifier.state.failedAttempts, 0);
  });

  testWidgets('AppLockScreen blocks for 30s after 3 wrong PIN entries', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final storage = InMemoryAppLockStorage();
    final notifier = AppLockNotifier(storage: storage, iterations: 1);
    await notifier.ready();
    await notifier.setupPin('1234');
    notifier.lock();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AppLockScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter wrong PIN "9999" three times (index 8 == digit 9).
    await _enterPinDigits(tester, [8, 8, 8, 8]);
    await _enterPinDigits(tester, [8, 8, 8, 8], settle: false);
    await _enterPinDigits(tester, [8, 8, 8, 8]);

    expect(notifier.state.isLocked, isTrue);
    expect(notifier.state.isTemporarilyBlocked, isTrue);
    expect(notifier.state.lockedUntil, isNotNull);

    final seconds = notifier.state.secondsRemaining;
    expect(seconds, greaterThanOrEqualTo(25));
    expect(seconds, lessThanOrEqualTo(30));

    // UI now displays detailed lockout feedback with a visible countdown.
    expect(find.textContaining('Trop de tentatives. Attendez'), findsOneWidget);
    expect(find.textContaining('s'), findsWidgets);
  });

  testWidgets('AppLockScreen forces logout after max lockout level', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final storage = InMemoryAppLockStorage();
    final notifier = AppLockNotifier(storage: storage, iterations: 1);
    final authNotifier = FakeAuthNotifier();
    await notifier.ready();
    await notifier.setupPin('1234');
    notifier.lock();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockProvider.overrideWith((ref) => notifier),
          authStateProvider.overrideWith((ref) => authNotifier),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AppLockScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterWrongPinCycle(tester);
    notifier.state = notifier.state.copyWith(
      failedAttempts: 0,
      clearLockedUntil: true,
    );
    await tester.pump();

    await enterWrongPinCycle(tester);
    notifier.state = notifier.state.copyWith(
      failedAttempts: 0,
      clearLockedUntil: true,
    );
    await tester.pump();

    await enterWrongPinCycle(tester);
    await tester.pump();

    expect(notifier.state.requiresLogout, isFalse);
    expect(notifier.state.isLocked, isFalse);
    expect(authNotifier.logoutCalls, 1);
    expect(authNotifier.state.isAuthenticated, isFalse);
  });

  testWidgets('Forgot PIN logs out and clears session lock', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    final storage = InMemoryAppLockStorage();
    final notifier = AppLockNotifier(storage: storage, iterations: 1);
    final authNotifier = FakeAuthNotifier();
    await notifier.ready();
    await notifier.setupPin('1234');
    notifier.lock();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockProvider.overrideWith((ref) => notifier),
          authStateProvider.overrideWith((ref) => authNotifier),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AppLockScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(notifier.state.isLocked, isTrue);

    final forgotPinFinder = find.text('Code PIN oublie ? Se deconnecter');
    await tester.ensureVisible(forgotPinFinder);
    await tester.tap(forgotPinFinder);
    await tester.pumpAndSettle();

    expect(authNotifier.logoutCalls, 1);
    expect(authNotifier.state.isAuthenticated, isFalse);
    expect(notifier.state.isLocked, isFalse);
    expect(notifier.state.requiresLogout, isFalse);
  });
}
