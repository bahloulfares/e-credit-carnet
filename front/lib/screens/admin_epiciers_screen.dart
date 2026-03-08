import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_epicier_model.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../services/api_client.dart';

class AdminEpiciersScreen extends ConsumerStatefulWidget {
  const AdminEpiciersScreen({super.key});

  @override
  ConsumerState<AdminEpiciersScreen> createState() =>
      _AdminEpiciersScreenState();
}

class _AdminEpiciersScreenState extends ConsumerState<AdminEpiciersScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(adminEpiciersProvider.notifier).loadEpiciers();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminEpiciersProvider);
    final statsAsync = ref.watch(adminGlobalStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion Épiciers',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Clients',
            icon: const Icon(Icons.people),
            onPressed: () async {
              await Navigator.of(context).pushNamed(Routes.clients);
              if (!context.mounted) return;
              ref.invalidate(adminGlobalStatsProvider);
            },
          ),
          IconButton(
            tooltip: 'Transactions',
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              await Navigator.of(context).pushNamed(Routes.transactions);
              if (!context.mounted) return;
              ref.invalidate(adminGlobalStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminGlobalStatsProvider);
              ref.invalidate(adminEpiciersProvider);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _AdminStatCard(
                        title: 'Épiciers',
                        value:
                            '${stats.totalEpiciers} (${stats.activeEpiciers} actifs)',
                        icon: Icons.store,
                        color: Colors.indigo,
                      ),
                      _AdminStatCard(
                        title: 'Total Clients',
                        value: stats.totalClients.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _AdminStatCard(
                        title: 'Total Dette',
                        value: '${stats.totalDebt.toStringAsFixed(2)} DT',
                        icon: Icons.money_off,
                        color: Colors.red,
                      ),
                      _AdminStatCard(
                        title: 'Total Transactions',
                        value: stats.totalTransactions.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This Month (données réelles)',
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
                            label: 'Crédit',
                            value:
                                '${stats.monthlyCredit.toStringAsFixed(2)} DT',
                            valueColor: Colors.green,
                          ),
                          const Divider(height: 20),
                          _MonthlyStatRow(
                            label: 'Paiement',
                            value:
                                '${stats.monthlyPayment.toStringAsFixed(2)} DT',
                            valueColor: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Cumul global',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _MonthlyStatRow(
                            label: 'Total Crédit',
                            value: '${stats.totalCredit.toStringAsFixed(2)} DT',
                            valueColor: Colors.green,
                          ),
                          const Divider(height: 20),
                          _MonthlyStatRow(
                            label: 'Total Paiement',
                            value:
                                '${stats.totalPayment.toStringAsFixed(2)} DT',
                            valueColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Impossible de charger les statistiques globales.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher (email, nom, boutique)',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) {
                      ref
                          .read(adminEpiciersProvider.notifier)
                          .loadEpiciers(search: value, refresh: true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Rechercher',
                  onPressed: () {
                    ref
                        .read(adminEpiciersProvider.notifier)
                        .loadEpiciers(
                          search: _searchController.text,
                          refresh: true,
                        );
                  },
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: state.isLoading && state.epiciers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.epiciers.isEmpty
                ? const Center(child: Text('Aucun épicier trouvé'))
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(adminEpiciersProvider.notifier)
                          .loadEpiciers(search: state.search, refresh: true);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          state.epiciers.length +
                          (state.hasMore || state.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.epiciers.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text('Fin de la liste des épiciers'),
                            ),
                          );
                        }

                        final epicier = state.epiciers[index];
                        return _EpicierTile(
                          epicier: epicier,
                          onViewClients: () => _showEpicierClients(epicier),
                          onToggleStatus: () => _toggleStatus(epicier),
                          onResetPassword: () =>
                              _showResetPasswordDialog(epicier),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(AdminEpicier epicier) async {
    try {
      await ref.read(adminEpiciersProvider.notifier).toggleStatus(epicier);
      ref.invalidate(adminGlobalStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            epicier.isActive
                ? 'Compte épicier désactivé'
                : 'Compte épicier activé',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  Future<void> _showEpicierClients(AdminEpicier epicier) async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final clients = await adminService.getEpicierClients(epicier.id);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Clients - ${epicier.fullName}'),
            content: SizedBox(
              width: 420,
              child: clients.isEmpty
                  ? const Text('Aucun client actif pour cet épicier.')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: clients.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (_, index) {
                        final client = clients[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(client.phone ?? 'Sans téléphone'),
                            Text(
                              'Dette: ${client.totalDebt.toStringAsFixed(2)} DT',
                              style: TextStyle(
                                color: client.totalDebt > 0
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  Future<void> _showResetPasswordDialog(AdminEpicier epicier) async {
    final formKey = GlobalKey<FormState>();
    String passwordValue = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Reset mot de passe - ${epicier.fullName}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
              ),
              onChanged: (value) => passwordValue = value,
              validator: (value) {
                if (value == null || value.trim().length < 8) {
                  return 'Minimum 8 caractères';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref
                      .read(adminEpiciersProvider.notifier)
                      .resetPassword(
                        epicierId: epicier.id,
                        newPassword: passwordValue.trim(),
                      );
                  ref.invalidate(adminGlobalStatsProvider);
                  if (!mounted) return;
                  if (!dialogContext.mounted) return;
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mot de passe réinitialisé')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) return 'Session expirée. Reconnectez-vous.';
      if (error.statusCode == 403) return 'Accès réservé aux administrateurs.';
      if (error.message.isNotEmpty) return error.message;
    }
    return 'Opération impossible pour le moment.';
  }
}

class _EpicierTile extends StatelessWidget {
  final AdminEpicier epicier;
  final VoidCallback onViewClients;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;

  const _EpicierTile({
    required this.epicier,
    required this.onViewClients,
    required this.onToggleStatus,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: epicier.isActive ? Colors.green : Colors.grey,
          child: const Icon(Icons.store, color: Colors.white),
        ),
        title: Text(epicier.fullName),
        subtitle: Text(
          '${epicier.email}\nClients: ${epicier.clientsCount} • Transactions: ${epicier.transactionsCount}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              tooltip: 'Voir les clients',
              onPressed: onViewClients,
              icon: const Icon(Icons.groups),
            ),
            IconButton(
              tooltip: epicier.isActive
                  ? 'Désactiver le compte'
                  : 'Réactiver le compte',
              onPressed: onToggleStatus,
              icon: Icon(
                epicier.isActive ? Icons.lock : Icons.lock_open,
                color: epicier.isActive ? Colors.red : Colors.green,
                size: 22,
              ),
            ),
            IconButton(
              tooltip: 'Reset mot de passe',
              onPressed: onResetPassword,
              icon: const Icon(Icons.lock_reset),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatCard({
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 30),
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
                      fontSize: 18,
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
