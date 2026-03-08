import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_provider.dart';
import '../constants/app_constants.dart';

class ClientDetailsScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailsScreen> createState() =>
      _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends ConsumerState<ClientDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientDetailsProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        centerTitle: true,
        actions: [
          clientAsync.when(
            data: (client) => IconButton(
              tooltip: client.isActive
                  ? 'Désactiver (non-paiement)'
                  : 'Réactiver',
              icon: Icon(
                client.isActive ? Icons.person_off : Icons.person,
                color: client.isActive ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleClientStatus(client.isActive),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: clientAsync.when(
        data: (client) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Phone: ${client.phone ?? 'N/A'}'),
                      Text('Email: ${client.email ?? 'N/A'}'),
                      Text('Address: ${client.address ?? 'N/A'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        title: 'Total Credit',
                        value: '${client.totalCredit.toStringAsFixed(2)} DT',
                        color: Colors.green,
                      ),
                      _SummaryRow(
                        title: 'Total Payment',
                        value: '${client.totalPayment.toStringAsFixed(2)} DT',
                        color: Colors.blue,
                      ),
                      _SummaryRow(
                        title: 'Current Debt',
                        value: '${client.totalDebt.toStringAsFixed(2)} DT',
                        color: client.totalDebt > 0 ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).pushNamed(
                      Routes.transactions,
                      arguments: {
                        'clientId': client.id,
                        'clientName': client.fullName,
                      },
                    );
                    if (!mounted) return;
                    ref.invalidate(clientDetailsProvider(widget.clientId));
                    await ref
                        .read(clientListProvider.notifier)
                        .loadClients(refresh: true);
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View Transactions'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _toggleClientStatus(bool currentStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentStatus ? 'Désactiver le client ?' : 'Réactiver le client ?',
        ),
        content: Text(
          currentStatus
              ? 'Le client ne pourra plus être sélectionné pour de nouvelles transactions.\nSes données seront conservées.'
              : 'Le client pourra à nouveau effectuer des transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.red : Colors.green,
            ),
            child: Text(currentStatus ? 'Désactiver' : 'Réactiver'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(clientListProvider.notifier)
          .setClientStatus(widget.clientId, !currentStatus);

      if (!mounted) return;
      ref.invalidate(clientDetailsProvider(widget.clientId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'Client désactivé' : 'Client réactivé'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
