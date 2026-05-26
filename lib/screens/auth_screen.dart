import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_api.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';
import 'role_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.visitor;
  final _authApi = const AuthApi();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _isRegister
          ? await _authApi.register(
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text,
              role: _selectedRole,
            )
          : await _authApi.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              RoleDashboardScreen(role: user.role, displayName: user.fullName),
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API indisponible. Verifiez que le backend est lance.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _selectedRole = UserRole.visitor;
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumPage(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: ListView(
                  key: const Key('auth_form'),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  children: [
                    const _AuthBrandPanel(),
                    const SizedBox(height: 18),
                    PremiumPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PremiumBadge(
                            label: _isRegister
                                ? 'Nouvelle inscription'
                                : 'Acces securise',
                            icon: _isRegister
                                ? Icons.person_add_alt_1_rounded
                                : Icons.verified_user_rounded,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isRegister ? 'Creer un compte' : 'Connexion',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRegister
                                ? 'Les comptes proprietaire, agent et admin sont crees par l agence.'
                                : 'Connectez-vous avec votre email et votre mot de passe.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          if (_isRegister) ...[
                            _RoleSelector(
                              selectedRole: _selectedRole,
                              onChanged: (role) =>
                                  setState(() => _selectedRole = role),
                            ),
                            const SizedBox(height: 18),
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
                            const SizedBox(height: 14),
                          ],
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
                          const SizedBox(height: 14),
                          if (_isRegister) ...[
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
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return '6 caracteres minimum';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: Icon(
                              _isRegister
                                  ? Icons.person_add_rounded
                                  : Icons.login_rounded,
                            ),
                            label: Text(
                              _isLoading
                                  ? 'Traitement...'
                                  : _isRegister
                                  ? 'Creer mon compte'
                                  : 'Se connecter',
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isRegister
                                  ? 'J ai deja un compte'
                                  : 'Creer un nouveau compte',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2415), Color(0xFF121212), Color(0xFF070707)],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumBadge(
            label: 'IMMOAGENCE PREMIUM',
            icon: Icons.workspace_premium_rounded,
          ),
          const SizedBox(height: 18),
          Text(
            'Votre espace immobilier noir & or',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 10),
          Text(
            'Location, vente, colocation, paiements, contrats et suivi agence.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  static const roles = [UserRole.visitor, UserRole.tenant];

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
