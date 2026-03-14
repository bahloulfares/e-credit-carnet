import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypt;

abstract class AppLockStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class SecureAppLockStorage implements AppLockStorage {
  final FlutterSecureStorage _secureStorage;

  SecureAppLockStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) => _secureStorage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _secureStorage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _secureStorage.delete(key: key);
}

class AppLockState {
  final bool isLocked;
  final bool hasPinSet;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final int lockoutLevel;
  final bool requiresLogout;

  const AppLockState({
    this.isLocked = false,
    this.hasPinSet = false,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.lockoutLevel = 0,
    this.requiresLogout = false,
  });

  bool get isTemporarilyBlocked =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  int get secondsRemaining {
    if (lockedUntil == null) return 0;
    final diff = lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  AppLockState copyWith({
    bool? isLocked,
    bool? hasPinSet,
    int? failedAttempts,
    DateTime? lockedUntil,
    int? lockoutLevel,
    bool? requiresLogout,
    bool clearLockedUntil = false,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
      lockoutLevel: lockoutLevel ?? this.lockoutLevel,
      requiresLogout: requiresLogout ?? this.requiresLogout,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  static const _pinKey = 'app_lock_pin';
  static const _maxAttempts = 3;
  static const _baseBlockDuration = Duration(seconds: 30);
  static const _maxBlockDuration = Duration(seconds: 120);
  static const _maxLockoutLevelBeforeLogout = 3;
  static const _hashScheme = 'pbkdf2_sha256';
  static const _saltLength = 16;
  static const _derivedKeyLength = 32;

  final AppLockStorage _storage;
  final int _pbkdf2Iterations;
  late final Future<void> _ready;

  AppLockNotifier({AppLockStorage? storage, int iterations = 120000})
    : _storage = storage ?? SecureAppLockStorage(),
      _pbkdf2Iterations = iterations,
      super(const AppLockState()) {
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    final pin = await _storage.read(key: _pinKey);
    if (pin != null) {
      state = const AppLockState(hasPinSet: true, isLocked: true);
    }
  }

  Future<void> ready() => _ready;

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  Future<String> _hashPinWithPbkdf2(String pin, {Uint8List? salt}) async {
    final usedSalt = salt ?? _generateSalt();
    final kdf = crypt.Pbkdf2(
      macAlgorithm: crypt.Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _derivedKeyLength * 8,
    );
    final secretKey = await kdf.deriveKeyFromPassword(
      password: pin,
      nonce: usedSalt,
    );
    final hashBytes = await secretKey.extractBytes();
    final encodedSalt = base64UrlEncode(usedSalt);
    final encodedHash = base64UrlEncode(hashBytes);
    return '$_hashScheme\$$_pbkdf2Iterations\$$encodedSalt\$$encodedHash';
  }

  String _legacySha256Hex(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  bool _isLegacyPlainPin(String? storedPin) {
    if (storedPin == null) return false;
    final plainPinRegex = RegExp(r'^\d{4}$');
    return plainPinRegex.hasMatch(storedPin);
  }

  bool _isLegacySha256Hex(String? storedPin) {
    if (storedPin == null) return false;
    final sha256Regex = RegExp(r'^[a-f0-9]{64}$');
    return sha256Regex.hasMatch(storedPin);
  }

  bool _isPbkdf2Format(String? storedPin) {
    return storedPin != null && storedPin.startsWith('$_hashScheme\$');
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= (a[i] ^ b[i]);
    }
    return diff == 0;
  }

  Future<bool> _matchesPbkdf2Pin(String inputPin, String storedPin) async {
    final parts = storedPin.split(r'$');
    if (parts.length != 4 || parts[0] != _hashScheme) return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    try {
      final salt = Uint8List.fromList(base64Url.decode(parts[2]));
      final expectedHash = base64Url.decode(parts[3]);
      final kdf = crypt.Pbkdf2(
        macAlgorithm: crypt.Hmac.sha256(),
        iterations: iterations,
        bits: expectedHash.length * 8,
      );
      final derived = await kdf.deriveKeyFromPassword(
        password: inputPin,
        nonce: salt,
      );
      final actualHash = await derived.extractBytes();
      return _constantTimeEquals(actualHash, expectedHash);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _matchesPin(String inputPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    if (storedPin == null) return false;

    if (_isLegacyPlainPin(storedPin)) {
      final matches = storedPin == inputPin;
      if (matches) {
        final upgraded = await _hashPinWithPbkdf2(inputPin);
        await _storage.write(key: _pinKey, value: upgraded);
      }
      return matches;
    }

    if (_isLegacySha256Hex(storedPin)) {
      final matches = storedPin == _legacySha256Hex(inputPin);
      if (matches) {
        final upgraded = await _hashPinWithPbkdf2(inputPin);
        await _storage.write(key: _pinKey, value: upgraded);
      }
      return matches;
    }

    if (_isPbkdf2Format(storedPin)) {
      return _matchesPbkdf2Pin(inputPin, storedPin);
    }

    return false;
  }

  /// Tente de déverrouiller. Retourne true si le PIN est correct.
  Future<bool> unlock(String pin) async {
    await _ready;
    if (state.isTemporarilyBlocked) return false;

    if (await _matchesPin(pin)) {
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lockoutLevel: 0,
        requiresLogout: false,
        clearLockedUntil: true,
      );
      return true;
    }

    final newAttempts = state.failedAttempts + 1;
    if (newAttempts >= _maxAttempts) {
      final nextLockoutLevel = state.lockoutLevel + 1;
      final durationMultiplier = 1 << (nextLockoutLevel - 1);
      final blockDuration = Duration(
        seconds: (_baseBlockDuration.inSeconds * durationMultiplier).clamp(
          _baseBlockDuration.inSeconds,
          _maxBlockDuration.inSeconds,
        ),
      );
      final forceLogout = nextLockoutLevel >= _maxLockoutLevelBeforeLogout;
      state = state.copyWith(
        failedAttempts: newAttempts,
        lockedUntil: DateTime.now().add(blockDuration),
        lockoutLevel: nextLockoutLevel,
        requiresLogout: forceLogout,
      );
    } else {
      state = state.copyWith(
        failedAttempts: newAttempts,
        requiresLogout: false,
      );
    }
    return false;
  }

  Future<bool> unlockWithBiometrics() async {
    await _ready;
    if (!state.hasPinSet) return false;
    state = state.copyWith(
      isLocked: false,
      failedAttempts: 0,
      lockoutLevel: 0,
      requiresLogout: false,
      clearLockedUntil: true,
    );
    return true;
  }

  /// Vérifie le PIN sans modifier l'état (pour changement/désactivation).
  Future<bool> verifyPin(String pin) async {
    await _ready;
    return _matchesPin(pin);
  }

  /// Configure ou remplace le code PIN.
  Future<void> setupPin(String pin) async {
    await _ready;
    final hashed = await _hashPinWithPbkdf2(pin);
    await _storage.write(key: _pinKey, value: hashed);
    state = state.copyWith(
      hasPinSet: true,
      isLocked: false,
      failedAttempts: 0,
      lockoutLevel: 0,
      requiresLogout: false,
      clearLockedUntil: true,
    );
  }

  /// Désactive le PIN après vérification. Retourne false si le PIN est incorrect.
  Future<bool> disablePin(String currentPin) async {
    await _ready;
    if (!(await _matchesPin(currentPin))) return false;
    await _storage.delete(key: _pinKey);
    state = state.copyWith(
      hasPinSet: false,
      isLocked: false,
      failedAttempts: 0,
      lockoutLevel: 0,
      requiresLogout: false,
      clearLockedUntil: true,
    );
    return true;
  }

  /// Verrouille l'app (uniquement si un PIN est configuré).
  void lock() {
    if (state.hasPinSet) {
      state = state.copyWith(
        isLocked: true,
        failedAttempts: 0,
        requiresLogout: false,
        clearLockedUntil: true,
      );
    }
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>(
  (ref) => AppLockNotifier(),
);
