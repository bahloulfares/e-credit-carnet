import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/client_provider.dart';
import '../services/api_client.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(clientListProvider.notifier);

    try {
      await notifier.createClient(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final message = _friendlyErrorMessage(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  String _friendlyErrorMessage(Object error) {
    final l10n = context.l10n;

    if (error is ApiException) {
      if (error.statusCode == 401) {
        return l10n.t('sessionExpired');
      }
      if (error.statusCode == 403) {
        return l10n.t('roleAccessDenied');
      }
      if (error.statusCode == 409) {
        return l10n.t('similarClientExists');
      }
      if (error.message.isNotEmpty) {
        return error.message;
      }
    }

    return l10n.t('createClientFailed');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('addClient')), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: l10n.t('firstName')),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.t('firstNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: l10n.t('lastName')),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.t('lastNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: l10n.t('phone')),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.t('email')),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: l10n.t('address')),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _saveClient,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.t('saveClient')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
