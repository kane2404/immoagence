import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/app_user.dart';
import '../services/admin_api.dart';
import '../services/api_exception.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';
import 'admin_account_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _adminApi = const AdminApi();
  late List<AppUser> _users = List<AppUser>.from(DemoData.users);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _adminApi.users();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlock(AppUser user) async {
    final confirmed = await confirmSensitiveAction(
      context: context,
      title: user.isBlocked ? 'Debloquer le compte' : 'Bloquer le compte',
      message:
          '${user.isBlocked ? 'Debloquer' : 'Bloquer'} le compte de ${user.fullName} ?',
      confirmLabel: user.isBlocked ? 'Debloquer' : 'Bloquer',
    );
    if (!confirmed) return;

    final index = _users.indexWhere((item) => item.id == user.id);
    if (index == -1) return;
    final updated = user.copyWith(isBlocked: !user.isBlocked);
    setState(() {
      _users[index] = updated;
    });

    try {
      await _adminApi.setUserBlocked(user.id, updated.isBlocked);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _users[index] = user);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action locale. API indisponible.')),
      );
    }
  }

  void _changePassword(AppUser user) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Mot de passe - ${user.fullName}'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe temporaire',
              prefixIcon: Icon(Icons.lock_reset_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final password = controller.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(dialogContext).pop();
                try {
                  await _adminApi.changeUserPassword(user.id, password);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Mot de passe de ${user.fullName} modifie.',
                      ),
                    ),
                  );
                } on ApiException catch (error) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe prepare. API indisponible.'),
                    ),
                  );
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _users.where((user) => !user.isBlocked).length;
    final ownerCount = _users
        .where((user) => user.role == UserRole.owner)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Comptes utilisateurs')),
      body: PremiumPage(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              PremiumResponsiveContent(
                maxWidth: 980,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(activeCount: activeCount, ownerCount: ownerCount),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AdminAccountScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Creer admin, proprio ou locataire'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isLoading ? 'Chargement...' : 'Utilisateurs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    for (final user in _users) ...[
                      _UserCard(
                        user: user,
                        onBlock: () => _toggleBlock(user),
                        onPassword: () => _changePassword(user),
                      ),
                      const SizedBox(height: 10),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.activeCount, required this.ownerCount});

  final int activeCount;
  final int ownerCount;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      highlight: true,
      child: PremiumAdaptiveRow(
        breakpoint: 520,
        children: [
          _MiniMetric(
            value: '$activeCount',
            label: 'actifs',
            icon: Icons.verified_user_rounded,
          ),
          _MiniMetric(
            value: '$ownerCount',
            label: 'proprietaires',
            icon: Icons.apartment_rounded,
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onBlock,
    required this.onPassword,
  });

  final AppUser user;
  final VoidCallback onBlock;
  final VoidCallback onPassword;

  @override
  Widget build(BuildContext context) {
    final statusColor = user.isBlocked ? AppColors.danger : AppColors.success;

    return PremiumPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                  child: Icon(Icons.person_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_roleLabel(user.role)} - ${user.email ?? user.phone}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: user.isBlocked ? 'Bloque' : 'Actif',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            PremiumAdaptiveRow(
              children: [
                OutlinedButton.icon(
                  onPressed: onPassword,
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: const Text('Mot de passe'),
                ),
                OutlinedButton.icon(
                  onPressed: onBlock,
                  icon: Icon(
                    user.isBlocked
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                  ),
                  label: Text(user.isBlocked ? 'Debloquer' : 'Bloquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.visitor => 'Visiteur',
    UserRole.tenant || UserRole.client => 'Locataire',
    UserRole.owner => 'Proprietaire',
    UserRole.admin => 'Admin',
    UserRole.agent => 'Agent',
  };
}
