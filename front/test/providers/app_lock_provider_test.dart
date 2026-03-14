import 'package:flutter_test/flutter_test.dart';
import 'package:ccns/providers/app_lock_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

void main() {
  group('AppLockNotifier', () {
    Future<void> failUnlockThreeTimes(AppLockNotifier notifier) async {
      await notifier.unlock('9999');
      await notifier.unlock('9999');
      await notifier.unlock('9999');
    }

    test(
      'setupPin stores hashed value and unlock succeeds with raw pin',
      () async {
        final storage = InMemoryAppLockStorage();
        final notifier = AppLockNotifier(storage: storage, iterations: 1);
        await notifier.ready();

        await notifier.setupPin('1234');

        final rawStored = await storage.read(key: 'app_lock_pin');
        expect(rawStored, isNotNull);
        expect(rawStored, isNot('1234'));
        expect(rawStored!.startsWith('pbkdf2_sha256\$'), isTrue);

        notifier.lock();
        final unlocked = await notifier.unlock('1234');

        expect(unlocked, isTrue);
        expect(notifier.state.isLocked, isFalse);
        expect(notifier.state.failedAttempts, 0);
      },
    );

    test(
      'legacy plain pin is migrated to hash after successful verify',
      () async {
        final storage = InMemoryAppLockStorage();
        await storage.write(key: 'app_lock_pin', value: '1111');

        final notifier = AppLockNotifier(storage: storage, iterations: 1);
        await notifier.ready();

        final ok = await notifier.verifyPin('1111');
        final stored = await storage.read(key: 'app_lock_pin');

        expect(ok, isTrue);
        expect(stored, isNotNull);
        expect(stored, isNot('1111'));
        expect(stored!.startsWith('pbkdf2_sha256\$'), isTrue);
      },
    );

    test(
      'legacy sha256 pin is migrated to PBKDF2 after successful verify',
      () async {
        final storage = InMemoryAppLockStorage();
        final legacySha = sha256.convert(utf8.encode('7777')).toString();
        await storage.write(key: 'app_lock_pin', value: legacySha);

        final notifier = AppLockNotifier(storage: storage, iterations: 1);
        await notifier.ready();

        final ok = await notifier.verifyPin('7777');
        final stored = await storage.read(key: 'app_lock_pin');

        expect(ok, isTrue);
        expect(stored, isNotNull);
        expect(stored, isNot(legacySha));
        expect(stored!.startsWith('pbkdf2_sha256\$'), isTrue);
      },
    );

    test('three failed attempts temporarily block unlock', () async {
      final storage = InMemoryAppLockStorage();
      final notifier = AppLockNotifier(storage: storage, iterations: 1);
      await notifier.ready();
      await notifier.setupPin('2222');
      notifier.lock();

      final before = DateTime.now();
      await failUnlockThreeTimes(notifier);
      final third = await notifier.unlock('9999');

      expect(third, isFalse);
      expect(notifier.state.failedAttempts, 3);
      expect(notifier.state.isTemporarilyBlocked, isTrue);
      expect(notifier.state.lockedUntil, isNotNull);
      final firstDuration = notifier.state.lockedUntil!.difference(before);
      expect(firstDuration.inSeconds, greaterThanOrEqualTo(25));
      expect(firstDuration.inSeconds, lessThanOrEqualTo(30));
      expect(notifier.state.lockoutLevel, 1);
      expect(notifier.state.requiresLogout, isFalse);
    });

    test(
      'lock duration escalates 30s -> 60s -> 120s and then requires logout',
      () async {
        final storage = InMemoryAppLockStorage();
        final notifier = AppLockNotifier(storage: storage, iterations: 1);
        await notifier.ready();
        await notifier.setupPin('4444');
        notifier.lock();

        final beforeFirst = DateTime.now();
        await failUnlockThreeTimes(notifier);
        final firstDuration = notifier.state.lockedUntil!.difference(
          beforeFirst,
        );
        expect(firstDuration.inSeconds, greaterThanOrEqualTo(25));
        expect(firstDuration.inSeconds, lessThanOrEqualTo(30));
        expect(notifier.state.lockoutLevel, 1);
        expect(notifier.state.requiresLogout, isFalse);

        notifier.state = notifier.state.copyWith(
          failedAttempts: 0,
          clearLockedUntil: true,
        );
        final beforeSecond = DateTime.now();
        await failUnlockThreeTimes(notifier);
        final secondDuration = notifier.state.lockedUntil!.difference(
          beforeSecond,
        );
        expect(secondDuration.inSeconds, greaterThanOrEqualTo(55));
        expect(secondDuration.inSeconds, lessThanOrEqualTo(60));
        expect(notifier.state.lockoutLevel, 2);
        expect(notifier.state.requiresLogout, isFalse);

        notifier.state = notifier.state.copyWith(
          failedAttempts: 0,
          clearLockedUntil: true,
        );
        final beforeThird = DateTime.now();
        await failUnlockThreeTimes(notifier);
        final thirdDuration = notifier.state.lockedUntil!.difference(
          beforeThird,
        );
        expect(thirdDuration.inSeconds, greaterThanOrEqualTo(115));
        expect(thirdDuration.inSeconds, lessThanOrEqualTo(120));
        expect(notifier.state.lockoutLevel, 3);
        expect(notifier.state.requiresLogout, isTrue);
      },
    );

    test('unlockWithBiometrics unlocks and resets lockout state', () async {
      final storage = InMemoryAppLockStorage();
      final notifier = AppLockNotifier(storage: storage, iterations: 1);
      await notifier.ready();
      await notifier.setupPin('5555');
      notifier.lock();

      await failUnlockThreeTimes(notifier);
      notifier.state = notifier.state.copyWith(
        failedAttempts: 0,
        clearLockedUntil: true,
      );
      await failUnlockThreeTimes(notifier);

      final unlocked = await notifier.unlockWithBiometrics();

      expect(unlocked, isTrue);
      expect(notifier.state.isLocked, isFalse);
      expect(notifier.state.failedAttempts, 0);
      expect(notifier.state.lockoutLevel, 0);
      expect(notifier.state.requiresLogout, isFalse);
    });

    test('disablePin rejects wrong pin and accepts correct pin', () async {
      final storage = InMemoryAppLockStorage();
      final notifier = AppLockNotifier(storage: storage, iterations: 1);
      await notifier.ready();
      await notifier.setupPin('3333');

      final wrong = await notifier.disablePin('0000');
      final stillPresent = await storage.read(key: 'app_lock_pin');

      expect(wrong, isFalse);
      expect(stillPresent, isNotNull);

      final ok = await notifier.disablePin('3333');
      final deleted = await storage.read(key: 'app_lock_pin');

      expect(ok, isTrue);
      expect(deleted, isNull);
      expect(notifier.state.hasPinSet, isFalse);
    });
  });
}
