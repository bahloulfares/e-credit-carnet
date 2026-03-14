import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_dashboard_screen.dart';
import 'admin_epiciers_list_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/app_drawer.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Épiciers'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: const [AdminDashboardScreen(), AdminEpiciersListScreen()],
      ),
    );
  }
}
