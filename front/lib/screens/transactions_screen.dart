import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/client_provider.dart';
import '../models/transaction_model.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? clientId;
  final String? clientName;

  const TransactionsScreen({super.key, this.clientId, this.clientName});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final ScrollController _scrollController;
  String _selectedTypeFilter = 'ALL';
  bool _onlyUnpaidCredits = false;
  String? _selectedClientFilter; // null = tous les clients

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref
          .read(transactionListProvider(widget.clientId).notifier)
          .loadTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider(widget.clientId));
    final clientsState = widget.clientId == null
        ? ref.watch(clientListProvider)
        : null;

    final filteredTransactions = state.transactions.where((tx) {
      final matchesType =
          _selectedTypeFilter == 'ALL' || tx.type == _selectedTypeFilter;
      final matchesUnpaid =
          !_onlyUnpaidCredits || (tx.type == 'CREDIT' && !tx.isPaid);
      final matchesClient =
          _selectedClientFilter == null ||
          tx.client?.id == _selectedClientFilter;
      return matchesType && matchesUnpaid && matchesClient;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.clientName == null
              ? 'Transactions'
              : 'Transactions - ${widget.clientName}',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTypeFilter,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Tous')),
                          DropdownMenuItem(
                            value: 'CREDIT',
                            child: Text('Crédits'),
                          ),
                          DropdownMenuItem(
                            value: 'PAYMENT',
                            child: Text('Paiements'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedTypeFilter = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Impayés'),
                      selected: _onlyUnpaidCredits,
                      onSelected: (selected) {
                        setState(() {
                          _onlyUnpaidCredits = selected;
                        });
                      },
                    ),
                  ],
                ),
                if (widget.clientId == null && clientsState != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Client'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedClientFilter,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tous les clients'),
                            ),
                            ...clientsState.clients.map(
                              (client) => DropdownMenuItem<String?>(
                                value: client.id,
                                child: Text(client.fullName),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClientFilter = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(transactionListProvider(widget.clientId).notifier)
                    .loadTransactions(refresh: true);
              },
              child: state.isLoading && state.transactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTransactions.isEmpty
                  ? const Center(
                      child: Text('Aucune transaction pour ce filtre'),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          filteredTransactions.length +
                          (state.hasMore || state.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredTransactions.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text('Fin de la liste des transactions'),
                            ),
                          );
                        }

                        final tx = filteredTransactions[index];
                        return _TransactionTile(
                          transaction: tx,
                          showClientInfo: widget.clientId == null,
                          onMarkPaid: tx.type == 'CREDIT' && !tx.isPaid
                              ? () => _showMarkAsPaidDialog(tx.id)
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.clientId == null
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Open transactions from a client to add one.',
                    ),
                  ),
                );
              }
            : _showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Future<void> _showAddTransactionDialog() async {
    final formKey = GlobalKey<FormState>();
    String type = 'CREDIT';
    String amountValue = '';
    String descriptionValue = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Transaction'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'CREDIT',
                          child: Text('Credit'),
                        ),
                        DropdownMenuItem(
                          value: 'PAYMENT',
                          child: Text('Payment'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            type = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Amount'),
                      onChanged: (value) => amountValue = value,
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      onChanged: (value) => descriptionValue = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate() ||
                        widget.clientId == null) {
                      return;
                    }

                    try {
                      await ref
                          .read(
                            transactionListProvider(widget.clientId).notifier,
                          )
                          .createTransaction(
                            clientId: widget.clientId!,
                            type: type,
                            amount: double.parse(amountValue),
                            description: descriptionValue.trim().isEmpty
                                ? null
                                : descriptionValue.trim(),
                          );

                      if (!mounted) return;
                      if (!dialogContext.mounted) return;
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create transaction: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMarkAsPaidDialog(String transactionId) async {
    String? paymentMethod = 'cash'; // Valeur par défaut

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Marquer comme payé'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sélectionnez la méthode de paiement :'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Méthode de paiement',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Row(
                          children: [
                            Icon(Icons.money, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Espèce'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'D17',
                        child: Row(
                          children: [
                            Icon(Icons.phone_android, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('D17'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Flouci',
                        child: Row(
                          children: [
                            Icon(Icons.payment, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Flouci'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Row(
                          children: [
                            Icon(Icons.account_balance, color: Colors.purple),
                            SizedBox(width: 8),
                            Text('Virement bancaire'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        paymentMethod = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(transactionListProvider(widget.clientId).notifier)
          .markAsPaid(transactionId, paymentMethod: paymentMethod);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction marquée comme payée')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool showClientInfo;
  final Future<void> Function()? onMarkPaid;

  const _TransactionTile({
    required this.transaction,
    required this.showClientInfo,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == 'CREDIT';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit ? Colors.orange : Colors.green,
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text('${transaction.amount.toStringAsFixed(2)} DT'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              transaction.description?.isNotEmpty == true
                  ? transaction.description!
                  : transaction.type,
            ),
            if (showClientInfo && transaction.client != null)
              Text(
                'Client: ${transaction.client!.fullName}${transaction.client!.phone?.isNotEmpty == true ? ' • ${transaction.client!.phone}' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: onMarkPaid == null
            ? null
            : TextButton(onPressed: onMarkPaid, child: const Text('Mark paid')),
      ),
    );
  }
}
