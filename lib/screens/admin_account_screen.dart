import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../services/admin_api.dart';
import '../services/api_exception.dart';
import '../services/notification_center.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<_CreatedAccount> _createdAccounts = [];
  final _adminApi = const AdminApi();
  UserRole _selectedRole = UserRole.owner;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final account = _CreatedAccount(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    try {
      await _adminApi.createAccount(
        fullName: account.fullName,
        email: account.email,
        phone: account.phone,
        password: _passwordController.text,
        role: account.role,
      );
      if (!mounted) return;
      notificationCenter.push(
        title: 'Compte cree',
        message:
            '${account.fullName} a ete ajoute comme ${_roleLabel(account.role)}.',
        type: AppNotificationType.admin,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte ${_roleLabel(account.role)} cree en base.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compte ${_roleLabel(account.role)} prepare localement. API indisponible.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _createdAccounts.insert(0, account);
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _selectedRole = UserRole.owner;
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes agence')),
      body: PremiumPage(
        child: SafeArea(
          child: ListView(
            key: const Key('admin_account_list'),
            padding: EdgeInsets.zero,
            children: [
              PremiumResponsiveContent(
                maxWidth: 860,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AccountHeader(),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: PremiumPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nouveau compte',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 14),
                            _RoleSelector(
                              selectedRole: _selectedRole,
                              onChanged: (role) {
                                setState(() => _selectedRole = role);
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 3) {
                                  return 'Entrez un nom valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_rounded),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                final isEmail = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email);
                                if (!isEmail) {
                                  return 'Entrez un email valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Telephone',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 9) {
                                  return 'Entrez un telephone valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Mot de passe temporaire',
                                prefixIcon: Icon(Icons.lock_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 8) {
                                  return '8 caracteres minimum';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              key: const Key('create_admin_account_button'),
                              onPressed: _isSaving ? null : _createAccount,
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: Text(
                                _isSaving ? 'Creation...' : 'Creer le compte',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Comptes ajoutes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    if (_createdAccounts.isEmpty)
                      const _EmptyAccounts()
                    else
                      for (final account in _createdAccounts)
                        _AccountCard(account: account),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return const PremiumHeroPanel(
      eyebrow: 'Administration',
      title: 'Creation controlee',
      subtitle:
          'Reserve a l agence pour les proprietaires, agents et administrateurs.',
      trailing: Icon(
        Icons.admin_panel_settings_rounded,
        color: AppColors.background,
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  static const roles = [
    UserRole.owner,
    UserRole.agent,
    UserRole.admin,
    UserRole.tenant,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final role in roles)
          ChoiceChip(
            label: Text(_roleLabel(role)),
            selected: selectedRole == role,
            onSelected: (_) => onChanged(role),
            selectedColor: AppColors.primary.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              color: selectedRole == role
                  ? AppColors.primary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Text(
          'Aucun compte cree dans cette session.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final _CreatedAccount account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            foregroundColor: AppColors.primary,
            child: Icon(_roleIcon(account.role)),
          ),
          title: Text(account.fullName),
          subtitle: Text('${_roleLabel(account.role)} - ${account.email}'),
          trailing: const Icon(Icons.verified_user_rounded),
        ),
      ),
    );
  }
}

class _CreatedAccount {
  const _CreatedAccount({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
}

IconData _roleIcon(UserRole role) {
  return switch (role) {
    UserRole.admin => Icons.admin_panel_settings_rounded,
    UserRole.agent => Icons.support_agent_rounded,
    UserRole.owner => Icons.home_work_rounded,
    UserRole.tenant || UserRole.client => Icons.key_rounded,
    UserRole.visitor => Icons.person_search_rounded,
  };
}

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.visitor => 'Visiteur',
    UserRole.tenant => 'Locataire',
    UserRole.owner => 'Proprietaire',
    UserRole.admin => 'Admin',
    UserRole.agent => 'Agent',
    UserRole.client => 'Client',
  };
}
