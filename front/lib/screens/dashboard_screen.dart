import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/dashboard_provider.dart';
import '../providers/sync_queue_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _autoRefreshTimer;

  Future<void> _runBackgroundSync() async {
    if (!mounted) return;
    try {
      final queue = await ref.read(syncQueueProvider.notifier).snapshot();
      if (queue.isEmpty) return;
      await ref.read(dashboardRefreshProvider.notifier).performSync(const []);
    } catch (_) {
      // Silent failure: UX shows only a discreet retry option.
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-refresh toutes les 30 secondes
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(dashboardStatsProvider);
        _runBackgroundSync();
      }
    });

    // Auto-sync silencieux au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _runBackgroundSync();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final refreshState = ref.watch(dashboardRefreshProvider);
    final hasSyncError = refreshState.hasSyncError;
    final retryCountdown = refreshState.retryCountdown;
    final isOffline = ref.watch(authStateProvider).isOffline;
    final lockState = ref.watch(appLockProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('dashboard')),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: lockState.isLocked
                ? l10n.t('lockStatusActive')
                : l10n.t('lockStatusInactive'),
            onPressed: lockState.hasPinSet
                ? () {
                    ref.read(appLockProvider.notifier).lock();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.t('lockNowDone'))),
                    );
                  }
                : null,
            icon: Icon(lockState.isLocked ? Icons.lock : Icons.lock_open),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          if (isOffline)
            Material(
              color: Colors.orange.shade700,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.t('offlineMode'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(dashboardRefreshProvider.notifier)
                    .refreshStats();
                await _runBackgroundSync();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: statsAsync.when(
                    data: (stats) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSyncError) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.sync_problem,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.t('syncFailed'),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          retryCountdown > 0
                                              ? '${l10n.t('autoRetry')} ${retryCountdown}s...'
                                              : l10n.t('syncing'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // KPI Cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _StatCard(
                              title: l10n.t('totalClients'),
                              value: stats.totalClients.toString(),
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                            _StatCard(
                              title: l10n.t('totalDebt'),
                              value: '${stats.totalDebt.toStringAsFixed(2)} DT',
                              icon: Icons.money_off,
                              color: Colors.red,
                            ),
                            _StatCard(
                              title: l10n.t('totalCredit'),
                              value:
                                  '${stats.totalCredit.toStringAsFixed(2)} DT',
                              icon: Icons.trending_up,
                              color: Colors.green,
                            ),
                            _StatCard(
                              title: l10n.t('totalPayment'),
                              value:
                                  '${stats.totalPayment.toStringAsFixed(2)} DT',
                              icon: Icons.payment,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Monthly Stats
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('thisMonth'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _MonthlyStatRow(
                                  label: l10n.t('transactions'),
                                  value: stats.monthlyTransactions.toString(),
                                ),
                                const Divider(height: 20),
                                _MonthlyStatRow(
                                  label: l10n.t('credits'),
                                  value:
                                      '${stats.monthlyCredit.toStringAsFixed(2)} DT',
                                  valueColor: Colors.green,
                                ),
                                const Divider(height: 20),
                                _MonthlyStatRow(
                                  label: l10n.t('payments'),
                                  value:
                                      '${stats.monthlyPayment.toStringAsFixed(2)} DT',
                                  valueColor: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Recent Transactions
                        if (stats.recentTransactions.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('recentTransactions'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...stats.recentTransactions.map((tx) {
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: tx.type == 'CREDIT'
                                          ? Colors.green
                                          : Colors.blue,
                                      child: Icon(
                                        tx.type == 'CREDIT'
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(tx.client.fullName),
                                    subtitle: Text(tx.type),
                                    trailing: Text(
                                      '${tx.amount.toStringAsFixed(2)} DT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: tx.type == 'CREDIT'
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('${l10n.t('error')}: $error'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MonthlyStatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
