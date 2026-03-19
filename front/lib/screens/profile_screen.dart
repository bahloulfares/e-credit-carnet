import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _shopNameController;
  late final TextEditingController _shopAddressController;
  late final TextEditingController _shopPhoneController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _shopNameController = TextEditingController();
    _shopAddressController = TextEditingController();
    _shopPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    super.dispose();
  }

  void _initFromUser(AuthState authState) {
    if (_initialized || authState.user == null) return;
    final user = authState.user!;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    _shopNameController.text = user.shopName ?? '';
    _shopAddressController.text = user.shopAddress ?? '';
    _shopPhoneController.text = user.shopPhone ?? '';
    _initialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final notifier = ref.read(authStateProvider.notifier);
    try {
      await notifier.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        shopName: _shopNameController.text.trim().isEmpty
            ? null
            : _shopNameController.text.trim(),
        shopAddress: _shopAddressController.text.trim().isEmpty
            ? null
            : _shopAddressController.text.trim(),
        shopPhone: _shopPhoneController.text.trim().isEmpty
            ? null
            : _shopPhoneController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('profileUpdatedSuccess'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.t('error')}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = context.l10n;
    final user = authState.user;
    _initFromUser(authState);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('myProfile')), centerTitle: true),
        body: Center(child: Text(l10n.t('userNotConnected'))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('myProfile')), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
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
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.email),
                        const SizedBox(height: 4),
                        Text('${l10n.t('roleLabel')}: ${user.role}'),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.t('subscriptionLabel')}: ${user.subscriptionStatus}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopNameController,
                  decoration: InputDecoration(labelText: l10n.t('shopName')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopAddressController,
                  decoration: InputDecoration(labelText: l10n.t('address')),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopPhoneController,
                  decoration: InputDecoration(labelText: l10n.t('phone')),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading ? null : _saveProfile,
                    icon: authState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(l10n.t('saveProfile')),
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
