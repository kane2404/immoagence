import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/app_user.dart';
import '../models/contract.dart';
import '../models/issue_report.dart';
import '../models/property.dart';
import '../models/visit.dart';
import '../services/dashboard_api.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';
import 'catalog_screen.dart';
import 'contract_screen.dart';
import 'issue_report_screen.dart';
import 'visit_schedule_screen.dart';

enum RoleServiceType {
  properties,
  contracts,
  receipts,
  issues,
  visits,
  messages,
}

class RoleServiceScreen extends StatefulWidget {
  const RoleServiceScreen({super.key, required this.role, required this.type});

  final UserRole role;
  final RoleServiceType type;

  @override
  State<RoleServiceScreen> createState() => _RoleServiceScreenState();
}

class _RoleServiceScreenState extends State<RoleServiceScreen> {
  final _dashboardApi = const DashboardApi();
  DashboardData? _data;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await _dashboardApi.load();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _data = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _serviceConfig(widget.role, widget.type);

    return Scaffold(
      appBar: AppBar(title: Text(config.title)),
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
                      eyebrow: config.eyebrow,
                      title: config.title,
                      subtitle: config.subtitle,
                      trailing: Icon(
                        config.icon,
                        size: 42,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (config.actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FilledButton.icon(
                          onPressed: () => _openAction(context, widget.type),
                          icon: Icon(config.actionIcon),
                          label: Text(config.actionLabel!),
                        ),
                      ),
                    ..._buildContent(context, widget.type),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, RoleServiceType type) {
    final data = _data;
    return switch (type) {
      RoleServiceType.properties => [
        PremiumResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 2,
          mobileAspectRatio: 2.0,
          desktopAspectRatio: 2.4,
          children: [
            for (final property
                in (data?.properties ?? DemoData.properties).take(6))
              _PropertyServiceCard(property: property),
          ],
        ),
      ],
      RoleServiceType.contracts => [
        if (data == null)
          for (final contract in DemoData.contracts) ...[
            _InfoTile(
              icon: Icons.description_rounded,
              title: contract.reference,
              subtitle:
                  '${_propertyTitle(contract.propertyId)} - ${contract.amount} FCFA',
              badge: _contractStatus(contract.status),
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
          ]
        else
          for (final contract in data.contracts) ...[
            _InfoTile(
              icon: Icons.description_rounded,
              title: contract['reference']?.toString() ?? 'Contrat',
              subtitle:
                  '${contract['property_title'] ?? ''} - ${contract['amount'] ?? 0} FCFA',
              badge: contract['status']?.toString() ?? 'Contrat',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
          ],
      ],
      RoleServiceType.receipts => [
        for (final receipt in DemoData.receipts) ...[
          _InfoTile(
            icon: Icons.receipt_long_rounded,
            title: receipt.reference,
            subtitle:
                '${_propertyTitle(receipt.propertyId)} - ${receipt.amount} FCFA',
            badge: 'Disponible',
            color: AppColors.success,
          ),
          const SizedBox(height: 10),
        ],
      ],
      RoleServiceType.issues => [
        if (data == null)
          for (final issue in DemoData.issueReports) ...[
            _InfoTile(
              icon: Icons.build_rounded,
              title: _issueCategory(issue.category),
              subtitle:
                  '${_propertyTitle(issue.propertyId)} - ${issue.description}',
              badge: _issueStatus(issue.status),
              color: issue.requiresFastAction
                  ? AppColors.danger
                  : AppColors.warning,
            ),
            const SizedBox(height: 10),
          ]
        else
          for (final issue in data.issues) ...[
            _InfoTile(
              icon: Icons.build_rounded,
              title: issue['category']?.toString() ?? 'Signalement',
              subtitle:
                  '${issue['property_title'] ?? ''} - ${issue['description'] ?? ''}',
              badge: issue['status']?.toString() ?? 'Nouveau',
              color: AppColors.warning,
            ),
            const SizedBox(height: 10),
          ],
      ],
      RoleServiceType.visits => [
        if (data == null)
          for (final visit in DemoData.visits) ...[
            _InfoTile(
              icon: Icons.calendar_month_rounded,
              title: _propertyTitle(visit.propertyId),
              subtitle:
                  '${_clientName(visit.clientId)} - ${_formatDateTime(visit.scheduledAt)}',
              badge: _visitStatus(visit.status),
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
          ]
        else
          for (final visit in data.visits) ...[
            _InfoTile(
              icon: Icons.calendar_month_rounded,
              title: visit['property_title']?.toString() ?? 'Visite',
              subtitle: visit['scheduled_at']?.toString() ?? '',
              badge: visit['status']?.toString() ?? 'En attente',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
          ],
      ],
      RoleServiceType.messages => [
        if (data == null)
          const _InfoTile(
            icon: Icons.chat_bubble_rounded,
            title: 'Agence ImmoAgence',
            subtitle: 'Votre dossier est suivi par notre equipe commerciale.',
            badge: 'Agence',
            color: AppColors.primary,
          )
        else
          for (final message in data.messages) ...[
            _InfoTile(
              icon: Icons.chat_bubble_rounded,
              title: message['subject']?.toString() ?? 'Message',
              subtitle: message['body']?.toString() ?? '',
              badge: message['sender_name']?.toString() ?? 'Agence',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
          ],
      ],
    };
  }

  void _openAction(BuildContext context, RoleServiceType type) {
    final firstProperty = DemoData.properties.first;
    final screen = switch (type) {
      RoleServiceType.properties => const CatalogScreen(),
      RoleServiceType.contracts => ContractScreen(property: firstProperty),
      RoleServiceType.issues => IssueReportScreen(
        initialProperty: firstProperty,
      ),
      RoleServiceType.visits => VisitScheduleScreen(
        initialProperty: firstProperty,
      ),
      RoleServiceType.receipts => const CatalogScreen(),
      RoleServiceType.messages => const CatalogScreen(),
    };

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _RoleServiceConfig {
  const _RoleServiceConfig({
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.actionIcon = Icons.open_in_new_rounded,
  });

  final String title;
  final String eyebrow;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final IconData actionIcon;
}

_RoleServiceConfig _serviceConfig(UserRole role, RoleServiceType type) {
  final roleLabel = switch (role) {
    UserRole.owner => 'Proprietaire',
    UserRole.tenant || UserRole.client => 'Locataire',
    UserRole.admin || UserRole.agent => 'Agence',
    UserRole.visitor => 'Visiteur',
  };

  return switch (type) {
    RoleServiceType.properties => _RoleServiceConfig(
      title: role == UserRole.owner ? 'Mes biens' : 'Biens publies',
      eyebrow: roleLabel,
      subtitle:
          'Maisons, terrains, locations et colocations organises pour consultation rapide.',
      icon: Icons.home_work_rounded,
      actionLabel: 'Explorer le catalogue',
      actionIcon: Icons.search_rounded,
    ),
    RoleServiceType.contracts => _RoleServiceConfig(
      title: 'Contrats',
      eyebrow: roleLabel,
      subtitle:
          'Documents, durees, montants et statuts regroupes au meme endroit.',
      icon: Icons.description_rounded,
      actionLabel: 'Demander un contrat',
      actionIcon: Icons.note_add_rounded,
    ),
    RoleServiceType.receipts => _RoleServiceConfig(
      title: 'Recus et paiements',
      eyebrow: roleLabel,
      subtitle: 'Historique des recus, cautions, loyers et reservations.',
      icon: Icons.receipt_long_rounded,
    ),
    RoleServiceType.issues => _RoleServiceConfig(
      title: 'Signalements',
      eyebrow: roleLabel,
      subtitle:
          'Eau, electricite, plomberie et incidents techniques suivis clairement.',
      icon: Icons.build_rounded,
      actionLabel: 'Nouveau signalement',
      actionIcon: Icons.add_alert_rounded,
    ),
    RoleServiceType.visits => _RoleServiceConfig(
      title: 'Visites',
      eyebrow: roleLabel,
      subtitle: 'Demandes de visites et rendez-vous programmes.',
      icon: Icons.calendar_month_rounded,
      actionLabel: 'Programmer une visite',
      actionIcon: Icons.event_available_rounded,
    ),
    RoleServiceType.messages => _RoleServiceConfig(
      title: 'Echanges',
      eyebrow: roleLabel,
      subtitle:
          'Messages importants entre vous, l agence et les equipes terrain.',
      icon: Icons.chat_bubble_rounded,
    ),
  };
}

class _PropertyServiceCard extends StatelessWidget {
  const _PropertyServiceCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              property.location,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Row(
              children: [
                _Badge(text: property.formattedPrice, color: AppColors.primary),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: _Badge(text: badge, color: color),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _propertyTitle(String propertyId) {
  return DemoData.properties
      .firstWhere((property) => property.id == propertyId)
      .title;
}

String _clientName(String userId) {
  return DemoData.users.firstWhere((user) => user.id == userId).fullName;
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} a $hour:$minute';
}

String _contractStatus(ContractStatus status) {
  return switch (status) {
    ContractStatus.draft => 'Brouillon',
    ContractStatus.pendingSignature => 'A signer',
    ContractStatus.signed => 'Signe',
    ContractStatus.cancelled => 'Annule',
  };
}

String _visitStatus(VisitStatus status) {
  return switch (status) {
    VisitStatus.pending => 'En attente',
    VisitStatus.confirmed => 'Confirmee',
    VisitStatus.completed => 'Terminee',
    VisitStatus.cancelled => 'Annulee',
  };
}

String _issueStatus(IssueStatus status) {
  return switch (status) {
    IssueStatus.newReport => 'Nouveau',
    IssueStatus.inProgress => 'En cours',
    IssueStatus.resolved => 'Resolu',
    IssueStatus.rejected => 'Rejete',
  };
}

String _issueCategory(IssueCategory category) {
  return switch (category) {
    IssueCategory.electricity => 'Electricite',
    IssueCategory.water => 'Eau',
    IssueCategory.plumbing => 'Plomberie',
    IssueCategory.lock => 'Serrure',
    IssueCategory.painting => 'Peinture',
    IssueCategory.roof => 'Toiture',
    IssueCategory.internet => 'Internet',
    IssueCategory.neighborhood => 'Voisinage',
    IssueCategory.cleaning => 'Nettoyage',
    IssueCategory.other => 'Autre',
  };
}
