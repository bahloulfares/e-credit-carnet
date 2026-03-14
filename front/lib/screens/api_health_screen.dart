import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/health_provider.dart';

class ApiHealthScreen extends ConsumerWidget {
  const ApiHealthScreen({super.key});

  String _formatTimestamp(DateTime timestamp) {
    final dd = timestamp.day.toString().padLeft(2, '0');
    final mm = timestamp.month.toString().padLeft(2, '0');
    final yyyy = timestamp.year.toString();
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    final ss = timestamp.second.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min:$ss';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final healthAsync = ref.watch(apiHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('apiHealthTitle')),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.t('refresh'),
            onPressed: () => ref.invalidate(apiHealthProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: healthAsync.when(
          data: (health) {
            final ok = health.reachable;

            return ListView(
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(
                      ok ? Icons.check_circle : Icons.error,
                      color: ok ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      ok
                          ? l10n.t('backendReachable')
                          : l10n.t('backendUnreachable'),
                    ),
                    subtitle: Text(
                      ok
                          ? l10n.t('healthCheckSuccess')
                          : '${l10n.t('error')}: ${health.error ?? l10n.t('unknownStatus')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('endpointLabel'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(health.endpoint),
                        const SizedBox(height: 14),
                        Text(
                          '${l10n.t('responseStatus')}: ${health.status ?? '-'}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.t('responseTime')}: ${health.timestamp == null ? '-' : _formatTimestamp(health.timestamp!)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 46),
                const SizedBox(height: 10),
                Text('${l10n.t('error')}: $error'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(apiHealthProvider),
                  child: Text(l10n.t('retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
