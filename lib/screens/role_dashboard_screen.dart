import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/app_session.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';
import 'agency_dashboard_screen.dart';
import 'main_navigation_screen.dart';
import 'role_service_screen.dart';

class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({
    super.key,
    required this.role,
    required this.displayName,
  });

  final UserRole role;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final config = _dashboardConfig(role);
    final essentialItems = config.items.take(5).toList();
    final extraItems = config.items.skip(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(config.title),
        actions: [
          IconButton(
            tooltip: 'Deconnexion',
            onPressed: () {
              appSession.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const MainNavigationScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: PremiumPage(
        child: SafeArea(
          child: ListView(
            key: const Key('role_dashboard'),
            padding: EdgeInsets.zero,
            children: [
              PremiumResponsiveContent(
                maxWidth: 1040,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumHeroPanel(
                      eyebrow: config.eyebrow,
                      title: 'Bonjour $displayName',
                      subtitle: config.subtitle,
                      trailing: Icon(
                        config.icon,
                        size: 42,
                        color: AppColors.background.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        PremiumBadge(
                          label: _roleLabel(role),
                          icon: Icons.badge,
                        ),
                        const PremiumBadge(
                          label: 'Espace securise',
                          icon: Icons.lock_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    PremiumResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 3,
                      mobileAspectRatio: 3.0,
                      desktopAspectRatio: 3.15,
                      children: [
                        for (final item in essentialItems)
                          _DashboardActionCard(
                            item: item,
                            onTap: () => _openItem(context, item),
                          ),
                      ],
                    ),
                    if (extraItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _MoreRoleServicesScreen(
                                role: role,
                                items: extraItems,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.apps_rounded),
                          label: const Text('Plus de services'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => role == UserRole.admin
                                  ? const AgencyDashboardScreen()
                                  : const MainNavigationScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          role == UserRole.admin
                              ? Icons.dashboard_rounded
                              : Icons.explore_rounded,
                        ),
                        label: Text(
                          role == UserRole.admin
                              ? 'Ouvrir le tableau agence'
                              : 'Explorer l application',
                        ),
                      ),
                    ),
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

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({required this.item, required this.onTap});

  final _DashboardItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: AppColors.background),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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

class _MoreRoleServicesScreen extends StatelessWidget {
  const _MoreRoleServicesScreen({required this.role, required this.items});

  final UserRole role;
  final List<_DashboardItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus de services')),
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
                    PremiumHeroPanel(
                      eyebrow: _roleLabel(role),
                      title: 'Services complementaires',
                      subtitle:
                          'Des fonctions utiles restent accessibles sans encombrer votre tableau de bord.',
                      trailing: const Icon(
                        Icons.apps_rounded,
                        color: AppColors.background,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 3,
                      mobileAspectRatio: 3.0,
                      desktopAspectRatio: 3.15,
                      children: [
                        for (final item in items)
                          _DashboardActionCard(
                            item: item,
                            onTap: () => _openItem(context, item),
                          ),
                      ],
                    ),
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

class _DashboardConfig {
  const _DashboardConfig({
    required this.title,
    required this.eyebrow,
    required this.icon,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String eyebrow;
  final IconData icon;
  final String subtitle;
  final List<_DashboardItem> items;
}

class _DashboardItem {
  const _DashboardItem(this.icon, this.title, this.subtitle, this.type);

  final IconData icon;
  final String title;
  final String subtitle;
  final RoleServiceType? type;
}

_DashboardConfig _dashboardConfig(UserRole role) {
  return switch (role) {
    UserRole.visitor => const _DashboardConfig(
      title: 'Dashboard visiteur',
      eyebrow: 'Consultation',
      icon: Icons.travel_explore_rounded,
      subtitle:
          'Consultez les maisons, terrains et locations publies par l agence.',
      items: [
        _DashboardItem(
          Icons.search_rounded,
          'Explorer les biens',
          'Locations, ventes, terrains et colocations.',
          RoleServiceType.properties,
        ),
        _DashboardItem(
          Icons.login_rounded,
          'Connexion requise pour agir',
          'Visite, paiement, contrat et signalement necessitent un compte.',
          null,
        ),
      ],
    ),
    UserRole.tenant || UserRole.client => const _DashboardConfig(
      title: 'Dashboard locataire',
      eyebrow: 'Residence',
      icon: Icons.key_rounded,
      subtitle: 'Suivez vos visites, paiements, contrats et signalements.',
      items: [
        _DashboardItem(
          Icons.description_rounded,
          'Votre contrat',
          'Duree, montant, conditions et statut.',
          RoleServiceType.contracts,
        ),
        _DashboardItem(
          Icons.receipt_long_rounded,
          'Recus de paiement',
          'Loyers, cautions, reservations et PayDunya.',
          RoleServiceType.receipts,
        ),
        _DashboardItem(
          Icons.build_rounded,
          'Signaler un probleme',
          'Eau, electricite, plomberie, serrure ou autre.',
          RoleServiceType.issues,
        ),
        _DashboardItem(
          Icons.search_rounded,
          'Biens publies',
          'Voir les maisons et terrains disponibles.',
          RoleServiceType.properties,
        ),
        _DashboardItem(
          Icons.calendar_month_rounded,
          'Visites',
          'Demandes et rendez-vous programmes.',
          RoleServiceType.visits,
        ),
        _DashboardItem(
          Icons.chat_bubble_rounded,
          'Echanges',
          'Messages avec l agence.',
          RoleServiceType.messages,
        ),
      ],
    ),
    UserRole.owner => const _DashboardConfig(
      title: 'Dashboard proprietaire',
      eyebrow: 'Patrimoine',
      icon: Icons.apartment_rounded,
      subtitle: 'Controlez vos biens, documents, revenus et demandes agence.',
      items: [
        _DashboardItem(
          Icons.home_work_rounded,
          'Mes maisons et terrains',
          'Biens a vendre, a louer ou occupes.',
          RoleServiceType.properties,
        ),
        _DashboardItem(
          Icons.description_rounded,
          'Contrats',
          'Documents lies a vos biens.',
          RoleServiceType.contracts,
        ),
        _DashboardItem(
          Icons.search_rounded,
          'Biens publies',
          'Consulter et demander des visites.',
          RoleServiceType.visits,
        ),
        _DashboardItem(
          Icons.receipt_long_rounded,
          'Paiements et recus',
          'Suivi des revenus et justificatifs.',
          RoleServiceType.receipts,
        ),
        _DashboardItem(
          Icons.chat_bubble_rounded,
          'Echanges',
          'Messages avec l agence.',
          RoleServiceType.messages,
        ),
      ],
    ),
    UserRole.admin || UserRole.agent => const _DashboardConfig(
      title: 'Dashboard admin',
      eyebrow: 'Direction agence',
      icon: Icons.admin_panel_settings_rounded,
      subtitle:
          'Pilotez les biens, clients, visites, paiements et signalements.',
      items: [
        _DashboardItem(
          Icons.home_work_rounded,
          'CRUD terrains et maisons',
          'Publier, modifier et affecter les biens.',
          null,
        ),
        _DashboardItem(
          Icons.manage_accounts_rounded,
          'Comptes agence',
          'Creer admin, agent, proprietaire et locataire.',
          null,
        ),
        _DashboardItem(
          Icons.report_problem_rounded,
          'Signalements et mensualites',
          'Suivre incidents, retards et paiements.',
          null,
        ),
      ],
    ),
  };
}

void _openItem(BuildContext context, _DashboardItem item) {
  final type = item.type;
  if (type == null) return;

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RoleServiceScreen(role: appSession.role, type: type),
    ),
  );
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
