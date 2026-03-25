import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/client_model.dart';
import '../providers/client_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/dashboard_provider.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('clientDetails')),
        centerTitle: true,
        actions: [
          clientAsync.when(
            data: (client) => IconButton(
              tooltip: l10n.t('editClient'),
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditClientDialog(client),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          clientAsync.when(
            data: (client) => IconButton(
              tooltip: client.isActive
                  ? l10n.t('deactivateClient')
                  : l10n.t('reactivateClient'),
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
                      if (!client.isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.t('inactive'),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text('${l10n.t('phone')}: ${client.phone ?? '-'}'),
                      Text('${l10n.t('email')}: ${client.email ?? '-'}'),
                      Text('${l10n.t('address')}: ${client.address ?? '-'}'),
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
                      Text(
                        l10n.t('financialSummary'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        title: l10n.t('clientTotalCredit'),
                        value: '${client.totalCredit.toStringAsFixed(2)} DT',
                        color: Colors.green,
                      ),
                      _SummaryRow(
                        title: l10n.t('clientTotalPayment'),
                        value: '${client.totalPayment.toStringAsFixed(2)} DT',
                        color: Colors.blue,
                      ),
                      _SummaryRow(
                        title: l10n.t('currentDebt'),
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
                  onPressed: () =>
                      _showAddTransactionDialog(client.id, client.fullName),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.t('addTransaction')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
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
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: Text(l10n.t('viewAllTransactions')),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${l10n.t('error')}: $error')),
      ),
    );
  }

  Future<void> _toggleClientStatus(bool currentStatus) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentStatus
              ? l10n.t('deactivateClient')
              : l10n.t('reactivateClient'),
        ),
        content: Text(
          currentStatus
              ? l10n.t('deactivateClientMsg')
              : l10n.t('reactivateClientMsg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.red : Colors.green,
            ),
            child: Text(
              currentStatus ? l10n.t('deactivate') : l10n.t('reactivate'),
            ),
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
          content: Text(
            currentStatus
                ? l10n.t('clientDeactivated')
                : l10n.t('clientReactivated'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.t('error')}: $e')));
    }
  }

  Future<void> _showEditClientDialog(Client client) async {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: client.firstName);
    final lastNameController = TextEditingController(text: client.lastName);
    final phoneController = TextEditingController(text: client.phone ?? '');
    final emailController = TextEditingController(text: client.email ?? '');
    final addressController = TextEditingController(text: client.address ?? '');
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.t('editClient')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: l10n.t('firstName'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.t('firstNameRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: l10n.t('lastName'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.t('lastNameRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(labelText: l10n.t('phone')),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: l10n.t('email')),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}',
                          );
                          if (!emailRegex.hasMatch(text)) {
                            return l10n.t('invalidEmailFormat');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: l10n.t('address'),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
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
                                .read(clientListProvider.notifier)
                                .updateClient(
                                  client.id,
                                  firstName: firstNameController.text.trim(),
                                  lastName: lastNameController.text.trim(),
                                  phone: phoneController.text.trim().isEmpty
                                      ? null
                                      : phoneController.text.trim(),
                                  email: emailController.text.trim().isEmpty
                                      ? null
                                      : emailController.text.trim(),
                                  address: addressController.text.trim().isEmpty
                                      ? null
                                      : addressController.text.trim(),
                                );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (_) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(l10n.t('updateClientError')),
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

    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();

    if (result == true && mounted) {
      ref.invalidate(clientDetailsProvider(widget.clientId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('clientUpdated'))));
    }
  }

  Future<void> _showAddTransactionDialog(
    String clientId,
    String clientName,
  ) async {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    String type = 'CREDIT';
    String amountValue = '';
    String descriptionValue = '';
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${l10n.t('addTransaction')} - $clientName'),
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
                      if (type == 'PAYMENT')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${l10n.t('paymentMethod')}: ${l10n.t('cash')}\n${l10n.t('cashOnlyForNow')}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: l10n.t('description'),
                        ),
                        maxLines: 2,
                        onChanged: (value) => descriptionValue = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
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

                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            await ref
                                .read(
                                  transactionListProvider(clientId).notifier,
                                )
                                .createTransaction(
                                  clientId: clientId,
                                  type: type,
                                  amount: double.parse(amountValue),
                                  description: descriptionValue.trim().isEmpty
                                      ? null
                                      : descriptionValue.trim(),
                                  paymentMethod: type == 'PAYMENT'
                                      ? 'cash'
                                      : null,
                                );

                            if (navigator.canPop()) {
                              navigator.pop(true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            messenger.showSnackBar(
                              SnackBar(content: Text('${l10n.t('error')}: $e')),
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

    if (result == true) {
      if (!mounted) return;
      // Rafraîchir les stats du client ET le dashboard
      ref.invalidate(clientDetailsProvider(widget.clientId));
      ref.invalidate(dashboardStatsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('transactionAdded'))));
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
