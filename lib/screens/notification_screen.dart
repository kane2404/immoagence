import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/app_notification.dart';
import '../models/issue_report.dart';
import '../models/visit.dart';
import '../services/notification_center.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notificationCenter,
      builder: (context, _) {
        final items = notificationCenter.items;

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Notifications'),
              actions: [
                IconButton(
                  tooltip: 'Tout marquer lu',
                  onPressed: notificationCenter.markAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.notifications_rounded), text: 'Alertes'),
                  Tab(icon: Icon(Icons.fact_check_rounded), text: 'Demandes'),
                  Tab(
                    icon: Icon(Icons.calendar_month_rounded),
                    text: 'Calendrier',
                  ),
                  Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Echanges'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _NotificationTab(items: items),
                const _RequestsTab(),
                const _CalendarTab(),
                const _MessagesTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTab extends StatelessWidget {
  const _NotificationTab({required this.items});

  final List<AppNotification> items;

  @override
  Widget build(BuildContext context) {
    return PremiumPage(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            PremiumResponsiveContent(
              maxWidth: 860,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumHeroPanel(
                    eyebrow: 'Suivi',
                    title: '${notificationCenter.unreadCount} non lue(s)',
                    subtitle:
                        'Retrouvez confirmations, contrats, signalements et actions admin.',
                    trailing: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.background,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const PremiumPanel(
                      child: Text('Aucune notification pour le moment.'),
                    )
                  else
                    for (final item in items) ...[
                      _NotificationTile(item: item),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final pendingVisits = DemoData.visits.where(
      (visit) => visit.status == VisitStatus.pending,
    );
    final openIssues = DemoData.issueReports.where(
      (issue) => issue.status != IssueStatus.resolved,
    );

    return _SimpleTabScaffold(
      title: 'Demandes a traiter',
      subtitle: 'Visites, contrats et signalements regroupes par priorite.',
      icon: Icons.fact_check_rounded,
      children: [
        for (final visit in pendingVisits)
          _SimpleTile(
            icon: Icons.calendar_month_rounded,
            title: _propertyTitle(visit.propertyId),
            subtitle:
                'Visite demandee le ${_formatDateTime(visit.scheduledAt)}',
            badge: 'En attente',
            color: AppColors.warning,
          ),
        for (final contract in DemoData.contracts)
          _SimpleTile(
            icon: Icons.description_rounded,
            title: contract.reference,
            subtitle: _propertyTitle(contract.propertyId),
            badge: 'Contrat',
            color: AppColors.primary,
          ),
        for (final issue in openIssues)
          _SimpleTile(
            icon: Icons.build_rounded,
            title: _issueCategory(issue.category),
            subtitle: issue.description,
            badge: 'Signalement',
            color: issue.requiresFastAction
                ? AppColors.danger
                : AppColors.warning,
          ),
      ],
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    return _SimpleTabScaffold(
      title: 'Calendrier',
      subtitle: 'Tous les rendez-vous de visite dans une seule liste.',
      icon: Icons.calendar_month_rounded,
      children: [
        for (final visit in DemoData.visits)
          _SimpleTile(
            icon: Icons.event_available_rounded,
            title: _formatDateTime(visit.scheduledAt),
            subtitle: _propertyTitle(visit.propertyId),
            badge: _visitStatus(visit.status),
            color: AppColors.primary,
          ),
      ],
    );
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return const _SimpleTabScaffold(
      title: 'Echanges',
      subtitle:
          'Fil de discussion prepare pour clients, agence et techniciens.',
      icon: Icons.chat_bubble_rounded,
      children: [
        _SimpleTile(
          icon: Icons.person_rounded,
          title: 'Aminata Diop',
          subtitle: 'Je suis disponible pour la visite demain matin.',
          badge: 'Client',
          color: AppColors.primary,
        ),
        _SimpleTile(
          icon: Icons.engineering_rounded,
          title: 'Equipe technique',
          subtitle: 'Intervention plomberie proposee apres validation.',
          badge: 'Interne',
          color: AppColors.warning,
        ),
        _SimpleTile(
          icon: Icons.description_rounded,
          title: 'Service contrats',
          subtitle: 'Contrat en attente de signature client.',
          badge: 'Agence',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _SimpleTabScaffold extends StatelessWidget {
  const _SimpleTabScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumPage(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            PremiumResponsiveContent(
              maxWidth: 860,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumHeroPanel(
                    eyebrow: 'Centre de suivi',
                    title: title,
                    subtitle: subtitle,
                    trailing: Icon(icon, color: AppColors.background, size: 42),
                  ),
                  const SizedBox(height: 16),
                  if (children.isEmpty)
                    const PremiumPanel(child: Text('Aucun element.'))
                  else
                    for (final child in children) ...[
                      child,
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type);
    return PremiumPanel(
      highlight: !item.isRead,
      child: Row(
        children: [
          Icon(_typeIcon(item.type), color: color),
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
                  item.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            badge,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

IconData _typeIcon(AppNotificationType type) {
  return switch (type) {
    AppNotificationType.visit => Icons.calendar_month_rounded,
    AppNotificationType.issue => Icons.build_rounded,
    AppNotificationType.contract => Icons.description_rounded,
    AppNotificationType.payment => Icons.account_balance_wallet_rounded,
    AppNotificationType.admin => Icons.admin_panel_settings_rounded,
    AppNotificationType.system => Icons.info_rounded,
  };
}

Color _typeColor(AppNotificationType type) {
  return switch (type) {
    AppNotificationType.issue => AppColors.warning,
    AppNotificationType.payment => AppColors.waveBlue,
    AppNotificationType.admin => AppColors.primary,
    _ => AppColors.primary,
  };
}

String _propertyTitle(String propertyId) {
  return DemoData.properties
      .firstWhere((property) => property.id == propertyId)
      .title;
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} a $hour:$minute';
}

String _visitStatus(VisitStatus status) {
  return switch (status) {
    VisitStatus.pending => 'En attente',
    VisitStatus.confirmed => 'Confirmee',
    VisitStatus.completed => 'Terminee',
    VisitStatus.cancelled => 'Annulee',
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
