import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';

// ─── Écran de verrouillage ────────────────────────────────────────────────────

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  String? _error;
  Timer? _countdownTimer;
  bool _isBiometricBusy = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onDigit(String d) {
    if (ref.read(appLockProvider).isTemporarilyBlocked || _pin.length >= 4) {
      return;
    }
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final success = await ref.read(appLockProvider.notifier).unlock(_pin);
    if (!mounted) return;
    if (!success) {
      final lockState = ref.read(appLockProvider);
      if (lockState.requiresLogout) {
        await _logout();
        return;
      }
      final l10n = context.l10n;
      setState(() {
        _pin = '';
        _error = l10n.t('pinAuthFailed');
        if (lockState.isTemporarilyBlocked) _startCountdown();
      });
    }
  }

  Future<void> _unlockWithBiometric() async {
    if (_isBiometricBusy) return;
    final l10n = context.l10n;
    setState(() {
      _error = null;
      _isBiometricBusy = true;
    });

    bool success = false;
    try {
      final biometricService = ref.read(biometricAuthProvider);
      final canCheck = await biometricService.canCheckBiometrics();
      if (canCheck) {
        final authenticated = await biometricService.authenticate();
        if (authenticated) {
          success = await ref
              .read(appLockProvider.notifier)
              .unlockWithBiometrics();
        }
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() {
      _isBiometricBusy = false;
      if (!success) _error = l10n.t('pinAuthFailed');
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }
      final remaining = ref.read(appLockProvider).secondsRemaining;
      if (remaining <= 0) {
        _countdownTimer?.cancel();
        setState(() => _error = null);
      }
    });
  }

  Future<void> _logout() async {
    ref.read(appLockProvider.notifier).clearSessionLock();
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.lock_rounded, size: 72, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'ProCrédit',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('pinTitle'),
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  PinDots(filled: _pin.length),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: _error != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _error ?? '',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PinKeypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    disabled: lockState.isTemporarilyBlocked,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isBiometricBusy ? null : _unlockWithBiometric,
                    icon: _isBiometricBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(l10n.t('useBiometric')),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _logout,
                    child: Text(
                      l10n.t('forgotPin'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dialogue saisie PIN (réutilisable) ──────────────────────────────────────

/// Affiche un dialogue de saisie PIN et retourne le PIN saisi (4 chiffres)
/// ou null si annulé.
Future<String?> showPinInputDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinInputDialog(title: title),
  );
}

class _PinInputDialog extends StatefulWidget {
  final String title;
  const _PinInputDialog({required this.title});

  @override
  State<_PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<_PinInputDialog> {
  String _pin = '';

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      Navigator.of(context).pop(_pin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PinDots(filled: _pin.length),
            const SizedBox(height: 20),
            PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(context.l10n.t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets partagés ────────────────────────────────────────────────────────

class PinDots extends StatelessWidget {
  final int filled;
  const PinDots({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? primary : Colors.transparent,
            border: Border.all(color: primary, width: 2),
          ),
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final bool disabled;

  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(['1', '2', '3']),
        _row(['4', '5', '6']),
        _row(['7', '8', '9']),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 64),
            _digitBtn('0'),
            SizedBox(
              width: 72,
              height: 64,
              child: IconButton(
                onPressed: disabled ? null : onBackspace,
                icon: const Icon(Icons.backspace_outlined, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_digitBtn).toList(),
    );
  }

  Widget _digitBtn(String d) {
    return SizedBox(
      width: 72,
      height: 64,
      child: TextButton(
        onPressed: disabled ? null : () => onDigit(d),
        style: TextButton.styleFrom(shape: const CircleBorder()),
        child: Text(
          d,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
