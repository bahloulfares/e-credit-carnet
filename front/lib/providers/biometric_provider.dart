import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

abstract class BiometricAuthService {
  Future<bool> canCheckBiometrics();
  Future<bool> authenticate();
}

class LocalBiometricAuthService implements BiometricAuthService {
  final LocalAuthentication _localAuth;

  LocalBiometricAuthService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  @override
  Future<bool> canCheckBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  @override
  Future<bool> authenticate() {
    return _localAuth.authenticate(
      localizedReason: 'Deverrouiller ProCredit',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}

final biometricAuthProvider = Provider<BiometricAuthService>((ref) {
  return LocalBiometricAuthService();
});
