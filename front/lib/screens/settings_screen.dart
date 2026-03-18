import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_lock_provider.dart';
import '../providers/theme_provider.dart';
import 'app_lock_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(l10n.t('darkThemeTitle')),
              subtitle: Text(l10n.t('darkThemeSubtitle')),
              trailing: Switch(
                value: currentTheme == ThemeMode.dark,
                onChanged: (value) {
                  ref
                      .read(themeProvider.notifier)
                      .setTheme(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _PinManagementCard(),
        ],
      ),
    );
  }
}

class _PinManagementCard extends ConsumerWidget {
  const _PinManagementCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockProvider);
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.t('pinManagement'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('pinTooltip'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (!lockState.hasPinSet) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _setupPin(context, ref),
                  icon: const Icon(Icons.add_moderator_outlined),
                  label: Text(l10n.t('enablePin')),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(appLockProvider.notifier).lock();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.t('lockNowDone'))),
                    );
                  },
                  icon: const Icon(Icons.lock),
                  label: Text(l10n.t('lockNow')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _changePin(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.t('changePin')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _disablePin(context, ref),
                  icon: const Icon(Icons.no_encryption_outlined),
                  label: Text(l10n.t('disablePin')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _setupPin(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final newPin = await showPinInputDialog(
      context,
      title: l10n.t('pinSetHint'),
    );
    if (newPin == null || !context.mounted) return;
    final confirm = await showPinInputDialog(
      context,
      title: l10n.t('pinConfirmHint'),
    );
    if (!context.mounted) return;
    if (confirm != newPin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('pinMismatch'))));
      return;
    }
    await ref.read(appLockProvider.notifier).setupPin(newPin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('pinSetSuccess'))));
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = await showPinInputDialog(
      context,
      title: l10n.t('pinDisableHint'),
    );
    if (current == null || !context.mounted) return;
    final valid = await ref.read(appLockProvider.notifier).verifyPin(current);
    if (!valid) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('pinDisableFailed'))));
      return;
    }
    if (!context.mounted) return;
    final newPin = await showPinInputDialog(
      context,
      title: l10n.t('pinSetHint'),
    );
    if (newPin == null || !context.mounted) return;
    final confirm = await showPinInputDialog(
      context,
      title: l10n.t('pinConfirmHint'),
    );
    if (!context.mounted) return;
    if (confirm != newPin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('pinMismatch'))));
      return;
    }
    await ref.read(appLockProvider.notifier).setupPin(newPin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('pinChangeSuccess'))));
  }

  Future<void> _disablePin(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = await showPinInputDialog(
      context,
      title: l10n.t('pinDisableHint'),
    );
    if (current == null || !context.mounted) return;
    final success = await ref
        .read(appLockProvider.notifier)
        .disablePin(current);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.t('pinDisableSuccess') : l10n.t('pinDisableFailed'),
        ),
      ),
    );
  }
}
