import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/locale_provider.dart';
import '../constants/app_constants.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final l10n = context.l10n;
    final user = authState.user;
    final isAdmin = user?.role == 'SUPER_ADMIN';
    final lockState = ref.watch(appLockProvider);

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
              title: Text(l10n.t('dashboard')),
              onTap: () {
                Navigator.of(context).pop();
                if (ModalRoute.of(context)?.settings.name != Routes.dashboard) {
                  Navigator.of(context).pushReplacementNamed(Routes.dashboard);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(l10n.t('gestionEpiciers')),
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
              title: Text(l10n.t('dashboard')),
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
            title: Text(l10n.t('clients')),
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
            title: Text(l10n.t('profile')),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety),
            title: Text(l10n.t('apiHealth')),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.apiHealth);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.t('refresh')),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(dashboardRefreshProvider.notifier).refreshStats();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.t('dataRefreshed')),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          if (lockState.hasPinSet)
            ListTile(
              leading: const Icon(Icons.lock),
              title: Text(l10n.t('lockNow')),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(appLockProvider.notifier).lock();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.t('lockNowDone'))));
              },
            ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('${l10n.t('language')}: ${l10n.t('switchLanguage')}'),
            onTap: () {
              ref.read(localeProvider.notifier).toggle();
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.t('logout'), style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.t('logout')),
                  content: Text(l10n.t('logoutConfirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.t('cancel')),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(l10n.t('logout')),
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
