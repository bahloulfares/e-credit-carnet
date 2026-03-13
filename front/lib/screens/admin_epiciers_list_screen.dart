import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_epicier_model.dart';
import '../providers/admin_provider.dart';
import '../services/api_client.dart';

class AdminEpiciersListScreen extends ConsumerStatefulWidget {
  const AdminEpiciersListScreen({super.key});

  @override
  ConsumerState<AdminEpiciersListScreen> createState() =>
      _AdminEpiciersListScreenState();
}

class _AdminEpiciersListScreenState
    extends ConsumerState<AdminEpiciersListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminEpiciersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEpicierDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel épicier'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
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
          if (state.isLoading && state.epiciers.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.epiciers.isEmpty)
            const Expanded(child: Center(child: Text('Aucun épicier trouvé')))
          else
            Expanded(
              child: ListView.builder(
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
                    onEdit: () => _showEditEpicierDialog(epicier),
                    onToggleStatus: () => _toggleStatus(epicier),
                    onResetPassword: () => _showResetPasswordDialog(epicier),
                  );
                },
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

  Future<void> _showCreateEpicierDialog() async {
    final formKey = GlobalKey<FormState>();
    String email = '';
    String firstName = '';
    String lastName = '';
    String password = '';
    String phone = '';
    String shopName = '';
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Créer un nouvel épicier'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => email = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email requis';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Format email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: (value) => firstName = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Prénom requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        onChanged: (value) => lastName = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nom requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe *',
                          prefixIcon: Icon(Icons.lock),
                          helperText: 'Minimum 8 caractères',
                        ),
                        onChanged: (value) => password = value,
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'Minimum 8 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) => phone = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nom de la boutique',
                          prefixIcon: Icon(Icons.store),
                        ),
                        onChanged: (value) => shopName = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final dialogNavigator = Navigator.of(dialogContext);

                            await ref
                                .read(adminEpiciersProvider.notifier)
                                .createEpicier(
                                  email: email.trim(),
                                  firstName: firstName.trim(),
                                  lastName: lastName.trim(),
                                  password: password,
                                  phone: phone.trim().isEmpty
                                      ? null
                                      : phone.trim(),
                                  shopName: shopName.trim().isEmpty
                                      ? null
                                      : shopName.trim(),
                                );
                            ref.invalidate(adminGlobalStatsProvider);
                            if (!mounted || !dialogContext.mounted) return;
                            if (dialogNavigator.canPop()) {
                              dialogNavigator.pop();
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Épicier créé avec succès'),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(
                              SnackBar(content: Text(_friendlyError(e))),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditEpicierDialog(AdminEpicier epicier) async {
    final formKey = GlobalKey<FormState>();
    String firstName = epicier.firstName;
    String lastName = epicier.lastName;
    String phone = epicier.phone ?? '';
    String shopName = epicier.shopName ?? '';
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Modifier - ${epicier.fullName}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: firstName,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: (value) => firstName = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Prénom requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: lastName,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        onChanged: (value) => lastName = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nom requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) => phone = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: shopName,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la boutique',
                          prefixIcon: Icon(Icons.store),
                        ),
                        onChanged: (value) => shopName = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final dialogNavigator = Navigator.of(dialogContext);

                            await ref
                                .read(adminEpiciersProvider.notifier)
                                .updateEpicier(
                                  epicierId: epicier.id,
                                  firstName: firstName.trim(),
                                  lastName: lastName.trim(),
                                  phone: phone.trim().isEmpty
                                      ? null
                                      : phone.trim(),
                                  shopName: shopName.trim().isEmpty
                                      ? null
                                      : shopName.trim(),
                                );
                            ref.invalidate(adminGlobalStatsProvider);
                            if (!mounted || !dialogContext.mounted) return;
                            if (dialogNavigator.canPop()) {
                              dialogNavigator.pop();
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Épicier modifié avec succès'),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(
                              SnackBar(content: Text(_friendlyError(e))),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EpicierTile extends StatelessWidget {
  final AdminEpicier epicier;
  final VoidCallback onViewClients;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;

  const _EpicierTile({
    required this.epicier,
    required this.onViewClients,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: epicier.isActive ? Colors.green : Colors.grey,
                child: const Icon(Icons.store, color: Colors.white),
              ),
              title: Text(
                epicier.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    epicier.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Clients: ${epicier.clientsCount} • Transactions: ${epicier.transactionsCount}',
                  ),
                ],
              ),
              isThreeLine: true,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: 'Voir les clients',
                    onPressed: onViewClients,
                    icon: const Icon(Icons.groups, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Modifier les informations',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  ),
                  IconButton(
                    tooltip: epicier.isActive
                        ? 'Désactiver le compte'
                        : 'Réactiver le compte',
                    onPressed: onToggleStatus,
                    icon: Icon(
                      epicier.isActive ? Icons.lock : Icons.lock_open,
                      color: epicier.isActive ? Colors.red : Colors.green,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reset mot de passe',
                    onPressed: onResetPassword,
                    icon: const Icon(Icons.lock_reset, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
