import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.user?.role == 'SUPER_ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Admin',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () async {
                await Navigator.of(context).pushNamed(Routes.adminEpiciers);
                if (!context.mounted) return;
                await ref
                    .read(dashboardRefreshProvider.notifier)
                    .refreshStats();
              },
            ),
          IconButton(
            tooltip: 'Clients',
            icon: const Icon(Icons.people),
            onPressed: () async {
              await Navigator.of(context).pushNamed(Routes.clients);
              if (!context.mounted) return;
              await ref.read(dashboardRefreshProvider.notifier).refreshStats();
            },
          ),
          IconButton(
            tooltip: 'Transactions',
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              await Navigator.of(context).pushNamed(Routes.transactions);
              if (!context.mounted) return;
              await ref.read(dashboardRefreshProvider.notifier).refreshStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardRefreshProvider.notifier).refreshStats();
            },
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(Routes.profile);
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(Routes.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardRefreshProvider.notifier).refreshStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _StatCard(
                        title: 'Total Clients',
                        value: stats.totalClients.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Total Debt',
                        value: '${stats.totalDebt} DT',
                        icon: Icons.money_off,
                        color: Colors.red,
                      ),
                      _StatCard(
                        title: 'Total Credit',
                        value: '${stats.totalCredit} DT',
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: 'Total Payment',
                        value: '${stats.totalPayment} DT',
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
                          const Text(
                            'This Month',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _MonthlyStatRow(
                            label: 'Transactions',
                            value: stats.monthlyTransactions.toString(),
                          ),
                          const Divider(height: 20),
                          _MonthlyStatRow(
                            label: 'Credit',
                            value:
                                '${stats.monthlyCredit.toStringAsFixed(2)} DT',
                            valueColor: Colors.green,
                          ),
                          const Divider(height: 20),
                          _MonthlyStatRow(
                            label: 'Payment',
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
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
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
                                '${tx.amount} DT',
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
            ),
          ),
        ),
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
