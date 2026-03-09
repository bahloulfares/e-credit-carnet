import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../constants/app_constants.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'SUPER_ADMIN';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.firstName != null && user!.firstName.isNotEmpty
                    ? user.firstName.substring(0, 1).toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
                if (ModalRoute.of(context)?.settings.name != Routes.dashboard) {
                  Navigator.of(context).pushReplacementNamed(Routes.dashboard);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Gestion Épiciers'),
              onTap: () {
                Navigator.of(context).pop();
                if (ModalRoute.of(context)?.settings.name !=
                    Routes.adminEpiciers) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(Routes.adminEpiciers);
                }
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
                if (ModalRoute.of(context)?.settings.name != Routes.dashboard) {
                  Navigator.of(context).pushReplacementNamed(Routes.dashboard);
                }
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clients'),
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).pushNamed(Routes.clients);
              if (context.mounted) {
                ref.read(dashboardRefreshProvider.notifier).refreshStats();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Rafraîchir'),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(dashboardRefreshProvider.notifier).refreshStats();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Données rafraîchies'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(Routes.login);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
