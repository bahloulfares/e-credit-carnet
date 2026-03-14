import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
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
  String _selectedPaidFilter = 'ALL';
  int? _selectedMonth;
  int? _selectedYear;

  bool? _buildServerPaidFilter() {
    // Apply server-side paid filter only for CREDIT type to avoid excluding
    // PAYMENT rows coming from historical data where isPaid may be false.
    if (_selectedTypeFilter != 'CREDIT') return null;
    if (_selectedPaidFilter == 'ALL') return null;
    return _selectedPaidFilter == 'PAID';
  }

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

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider(widget.clientId));
    final l10n = context.l10n;

    final years = <int>{DateTime.now().year};
    for (final tx in state.transactions) {
      years.add(tx.transactionDate.year);
    }
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));

    final filteredTransactions = state.transactions.where((tx) {
      final typeOk =
          _selectedTypeFilter == 'ALL' || tx.type == _selectedTypeFilter;
      final paidOk = switch (_selectedPaidFilter) {
        'ALL' => true,
        'PAID' => tx.type == 'PAYMENT' || (tx.type == 'CREDIT' && tx.isPaid),
        'UNPAID' => tx.type == 'CREDIT' && !tx.isPaid,
        _ => true,
      };
      final monthOk =
          _selectedMonth == null || tx.transactionDate.month == _selectedMonth;
      final yearOk =
          _selectedYear == null || tx.transactionDate.year == _selectedYear;
      return typeOk && paidOk && monthOk && yearOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.t('transactionsOf')} - ${widget.clientName}'),
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
                  decoration: InputDecoration(labelText: l10n.t('type')),
                  items: [
                    DropdownMenuItem(
                      value: 'ALL',
                      child: Text(l10n.t('allTypes')),
                    ),
                    DropdownMenuItem(
                      value: 'CREDIT',
                      child: Text(l10n.t('creditType')),
                    ),
                    DropdownMenuItem(
                      value: 'PAYMENT',
                      child: Text(l10n.t('paymentType')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedTypeFilter = value;
                    });
                    ref
                        .read(transactionListProvider(widget.clientId).notifier)
                        .applyFilters(
                          type: value == 'ALL' ? null : value,
                          isPaid: _buildServerPaidFilter(),
                          month: _selectedMonth,
                          year: _selectedYear,
                        );
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPaidFilter,
                  decoration: InputDecoration(
                    labelText: l10n.t('paymentStatus'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'ALL',
                      child: Text(l10n.t('allPaymentStatus')),
                    ),
                    DropdownMenuItem(
                      value: 'PAID',
                      child: Text(l10n.t('paidStatus')),
                    ),
                    DropdownMenuItem(
                      value: 'UNPAID',
                      child: Text(l10n.t('unpaidStatus')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedPaidFilter = value;
                    });
                    ref
                        .read(transactionListProvider(widget.clientId).notifier)
                        .applyFilters(
                          type: _selectedTypeFilter == 'ALL'
                              ? null
                              : _selectedTypeFilter,
                          isPaid: _buildServerPaidFilter(),
                          month: _selectedMonth,
                          year: _selectedYear,
                        );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: l10n.t('allMonths'),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n.t('allMonths')),
                          ),
                          ...List.generate(12, (index) {
                            final month = index + 1;
                            return DropdownMenuItem<int?>(
                              value: month,
                              child: Text(l10n.monthName(month)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                          ref
                              .read(
                                transactionListProvider(
                                  widget.clientId,
                                ).notifier,
                              )
                              .applyFilters(
                                type: _selectedTypeFilter == 'ALL'
                                    ? null
                                    : _selectedTypeFilter,
                                isPaid: _buildServerPaidFilter(),
                                month: value,
                                year: _selectedYear,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _selectedYear,
                        decoration: InputDecoration(
                          labelText: l10n.t('allYears'),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n.t('allYears')),
                          ),
                          ...sortedYears.map(
                            (year) => DropdownMenuItem<int?>(
                              value: year,
                              child: Text('$year'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                          ref
                              .read(
                                transactionListProvider(
                                  widget.clientId,
                                ).notifier,
                              )
                              .applyFilters(
                                type: _selectedTypeFilter == 'ALL'
                                    ? null
                                    : _selectedTypeFilter,
                                isPaid: _buildServerPaidFilter(),
                                month: _selectedMonth,
                                year: value,
                              );
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.t('filterByPeriod'),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = null;
                          _selectedYear = null;
                          _selectedTypeFilter = 'ALL';
                          _selectedPaidFilter = 'ALL';
                        });
                        ref
                            .read(
                              transactionListProvider(widget.clientId).notifier,
                            )
                            .applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ],
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
                  ? Center(child: Text(l10n.t('noTransactionsFilter')))
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(l10n.t('endOfTransactionList')),
                            ),
                          );
                        }

                        final tx = filteredTransactions[index];
                        return _TransactionTile(
                          transaction: tx,
                          onEdit: () => _showEditTransactionDialog(tx),
                          onDelete: () => _confirmDeleteTransaction(tx),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('addTransactionFab')),
      ),
    );
  }

  Future<void> _showAddTransactionDialog() async {
    final parentContext = context;
    final l10n = context.l10n;
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
              title: Text(l10n.t('newTransaction')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: InputDecoration(labelText: l10n.t('type')),
                        items: [
                          DropdownMenuItem(
                            value: 'CREDIT',
                            child: Text(l10n.t('credit')),
                          ),
                          DropdownMenuItem(
                            value: 'PAYMENT',
                            child: Text(l10n.t('payment')),
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
                        decoration: InputDecoration(
                          labelText: l10n.t('amount'),
                        ),
                        onChanged: (value) => amountValue = value,
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return l10n.t('amountInvalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: l10n.t('description'),
                        ),
                        onChanged: (value) => descriptionValue = value,
                      ),
                      if (type == 'PAYMENT')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${l10n.t('paymentMethod')}: ${l10n.t('cash')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('cancel')),
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
                                  paymentMethod: type == 'PAYMENT'
                                      ? 'cash'
                                      : null,
                                );

                            if (!mounted) return;
                            ref.invalidate(dashboardStatsProvider);

                            if (!dialogContext.mounted) return;
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(l10n.t('transactionAdded')),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (!mounted) return;
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${l10n.t('transactionError')}: $e',
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
                      : Text(l10n.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTransactionDialog(Transaction transaction) async {
    final parentContext = context;
    final l10n = parentContext.l10n;
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: transaction.amount.toStringAsFixed(2),
    );
    DateTime? dueDateValue = transaction.dueDate;
    final descriptionController = TextEditingController(
      text: transaction.description ?? '',
    );
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text(l10n.t('editTransaction')),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: transaction.type == 'CREDIT'
                          ? l10n.t('credit')
                          : l10n.t('payment'),
                      readOnly: true,
                      decoration: InputDecoration(labelText: l10n.t('type')),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: l10n.t('amount')),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return l10n.t('amountInvalid');
                        }
                        return null;
                      },
                    ),
                    if (transaction.type == 'CREDIT') ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final pickedDate = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: dueDateValue ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );

                                if (pickedDate == null) return;
                                setDialogState(() {
                                  dueDateValue = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                  );
                                });
                              },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.t('dueDate'),
                            suffixIcon: dueDateValue == null
                                ? const Icon(Icons.calendar_today)
                                : IconButton(
                                    tooltip: l10n.t('clearDate'),
                                    onPressed: isSubmitting
                                        ? null
                                        : () {
                                            setDialogState(() {
                                              dueDateValue = null;
                                            });
                                          },
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                          child: Text(
                            dueDateValue == null
                                ? l10n.t('noDueDate')
                                : _formatDate(dueDateValue!),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.t('description'),
                      ),
                      maxLines: 3,
                    ),
                    if (transaction.type == 'PAYMENT')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${l10n.t('paymentMethod')}: ${l10n.t('cash')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.t('cancel')),
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
                            final messenger = ScaffoldMessenger.of(
                              parentContext,
                            );
                            final dialogNavigator = Navigator.of(dialogContext);

                            await ref
                                .read(
                                  transactionListProvider(
                                    widget.clientId,
                                  ).notifier,
                                )
                                .updateTransaction(
                                  transaction.id,
                                  amount: double.parse(
                                    amountController.text.trim(),
                                  ),
                                  description:
                                      descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  dueDate: transaction.type == 'CREDIT'
                                      ? dueDateValue
                                      : null,
                                  paymentMethod: transaction.type == 'PAYMENT'
                                      ? 'cash'
                                      : null,
                                );

                            if (!mounted || !dialogContext.mounted) return;
                            if (dialogNavigator.canPop()) {
                              dialogNavigator.pop();
                            }

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.t('transactionUpdated')),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(
                              parentContext,
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${l10n.t('updateTransactionError')}: $e',
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
                      : Text(l10n.t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    descriptionController.dispose();
  }

  Future<void> _confirmDeleteTransaction(Transaction transaction) async {
    final parentContext = context;
    final l10n = parentContext.l10n;
    final messenger = ScaffoldMessenger.of(parentContext);

    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('deleteTransaction')),
        content: Text(l10n.t('confirmDeleteTransaction')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(transactionListProvider(widget.clientId).notifier)
          .deleteTransaction(transaction.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('transactionDeleted'))),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.t('deleteTransactionError')}: $e')),
      );
    }
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  : (isCredit ? l10n.t('credit') : l10n.t('payment')),
            ),
            const SizedBox(height: 2),
            Text(
              '${transaction.transactionDate.day.toString().padLeft(2, '0')}/${transaction.transactionDate.month.toString().padLeft(2, '0')}/${transaction.transactionDate.year}  ${transaction.transactionDate.hour.toString().padLeft(2, '0')}:${transaction.transactionDate.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.t('edit'))),
            PopupMenuItem(value: 'delete', child: Text(l10n.t('delete'))),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
