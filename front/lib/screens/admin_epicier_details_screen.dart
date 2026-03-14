import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';

class AdminEpicierDetailsScreen extends ConsumerWidget {
  final String epicierId;

  const AdminEpicierDetailsScreen({super.key, required this.epicierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epicierAsync = ref.watch(adminEpicierDetailsProvider(epicierId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details epicier'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Rafraichir',
            onPressed: () {
              ref.invalidate(adminEpicierDetailsProvider(epicierId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: epicierAsync.when(
        data: (epicier) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        epicier.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(epicier.email),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              epicier.isActive ? 'Actif' : 'Desactive',
                            ),
                            backgroundColor: epicier.isActive
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                          ),
                          Chip(
                            label: Text(
                              'Subscription: ${epicier.subscriptionStatus}',
                            ),
                          ),
                        ],
                      ),
                    ],
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
                      const Text(
                        'Coordonnees boutique',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Telephone: ${epicier.phone ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('Nom boutique: ${epicier.shopName ?? '-'}'),
                      const SizedBox(height: 8),
                      Text(
                        'Date creation: ${epicier.createdAt.day.toString().padLeft(2, '0')}/${epicier.createdAt.month.toString().padLeft(2, '0')}/${epicier.createdAt.year}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Clients'),
                            const SizedBox(height: 6),
                            Text(
                              epicier.clientsCount.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Transactions'),
                            const SizedBox(height: 6),
                            Text(
                              epicier.transactionsCount.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 44),
                const SizedBox(height: 10),
                Text('Erreur de chargement: $error'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(adminEpicierDetailsProvider(epicierId));
                  },
                  child: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
