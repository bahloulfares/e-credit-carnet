import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/transaction_model.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const TransactionsScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final ScrollController _scrollController;
  String _selectedTypeFilter = 'ALL';

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

    final filteredTransactions = state.transactions.where((tx) {
      return _selectedTypeFilter == 'ALL' || tx.type == _selectedTypeFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions - ${widget.clientName}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedTypeFilter,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Tous')),
                    DropdownMenuItem(value: 'CREDIT', child: Text('Crédits')),
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
                        return _TransactionTile(transaction: tx);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
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
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
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
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await ref
                                .read(
                                  transactionListProvider(
                                    widget.clientId,
                                  ).notifier,
                                )
                                .createTransaction(
                                  clientId: widget.clientId,
                                  type: type,
                                  amount: double.parse(amountValue),
                                  description: descriptionValue.trim().isEmpty
                                      ? null
                                      : descriptionValue.trim(),
                                );

                            if (!mounted) return;
                            ref.invalidate(dashboardStatsProvider);

                            if (!dialogContext.mounted) return;
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Transaction ajoutée avec succès',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to create transaction: $e',
                                ),
                              ),
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
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

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
        subtitle: Text(
          transaction.description?.isNotEmpty == true
              ? transaction.description!
              : transaction.type,
        ),
      ),
    );
  }
}
