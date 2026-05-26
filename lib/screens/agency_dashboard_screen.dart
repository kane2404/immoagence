import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/app_user.dart';
import '../models/contract.dart';
import '../models/app_notification.dart';
import '../models/issue_report.dart';
import '../models/property.dart';
import '../models/visit.dart';
import '../models/wave_payment.dart';
import '../services/admin_api.dart';
import '../services/app_session.dart';
import '../services/notification_center.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';
import 'admin_account_screen.dart';
import 'admin_property_crud_screen.dart';
import 'admin_user_management_screen.dart';
import 'main_navigation_screen.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  final _adminApi = const AdminApi();
  late final Map<String, VisitStatus> _visitStatuses = {
    for (final visit in DemoData.visits) visit.id: visit.status,
  };
  late final Map<String, ContractStatus> _contractStatuses = {
    for (final contract in DemoData.contracts) contract.id: contract.status,
  };
  late final Map<String, IssueStatus> _issueStatuses = {
    for (final issue in DemoData.issueReports) issue.id: issue.status,
  };
  _AdminPriorityFilter _priorityFilter = _AdminPriorityFilter.all;

  @override
  Widget build(BuildContext context) {
    final available = DemoData.properties
        .where((property) => property.status == PropertyStatus.available)
        .length;
    final pendingVisits = _visitStatuses.values
        .where((status) => status == VisitStatus.pending)
        .length;
    final openIssues = _issueStatuses.values
        .where(
          (status) =>
              status == IssueStatus.newReport ||
              status == IssueStatus.inProgress,
        )
        .length;
    final unpaid = DemoData.payments
        .where((payment) => payment.status != PaymentStatus.successful)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau agence'),
        actions: [
          IconButton(
            tooltip: 'Accueil',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const MainNavigationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.home_rounded),
          ),
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
            key: const Key('agency_dashboard_list'),
            padding: EdgeInsets.zero,
            children: [
              PremiumResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(
                      pendingVisits: pendingVisits,
                      openIssues: openIssues,
                      unpaid: unpaid,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Services essentiels',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    PremiumResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 3,
                      mobileAspectRatio: 3.0,
                      desktopAspectRatio: 2.65,
                      children: [
                        _MenuCard(
                          icon: Icons.home_work_rounded,
                          title: 'Biens',
                          subtitle: 'Publier, affecter, vendre et louer.',
                          onTap: () => _open(const AdminPropertyCrudScreen()),
                        ),
                        _MenuCard(
                          icon: Icons.group_rounded,
                          title: 'Utilisateurs',
                          subtitle:
                              'Bloquer, consulter et changer mot de passe.',
                          onTap: () => _open(const AdminUserManagementScreen()),
                        ),
                        _MenuCard(
                          icon: Icons.notifications_active_rounded,
                          title: 'Demandes',
                          subtitle: '$pendingVisits visite(s) a traiter.',
                          onTap: () =>
                              _openService(_AgencyServiceType.requests),
                        ),
                        _MenuCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'Calendrier',
                          subtitle: 'Visites et rendez-vous agence.',
                          onTap: () =>
                              _openService(_AgencyServiceType.calendar),
                        ),
                        _MenuCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Paiements PayDunya',
                          subtitle: 'Loyers, avances et mensualites.',
                          onTap: () =>
                              _openService(_AgencyServiceType.payments),
                        ),
                        _MenuCard(
                          icon: Icons.insights_rounded,
                          title: 'Statistiques',
                          subtitle:
                              '$available biens disponibles, $unpaid due(s).',
                          onTap: () => _open(
                            _AgencyStatsScreen(
                              available: available,
                              pendingVisits: pendingVisits,
                              openIssues: openIssues,
                              unpaid: unpaid,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width < 430
                            ? double.infinity
                            : 260,
                        child: OutlinedButton.icon(
                          onPressed: () => _open(
                            _MoreAgencyServicesScreen(
                              openService: _openService,
                              openScreen: _open,
                            ),
                          ),
                          icon: const Icon(Icons.apps_rounded),
                          label: const Text('Plus de services'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _AdminFilterBar(
                      selected: _priorityFilter,
                      onChanged: (value) =>
                          setState(() => _priorityFilter = value),
                    ),
                    const SizedBox(height: 14),
                    _Section(
                      title: 'Priorites du jour',
                      children: [
                        for (final visit
                            in DemoData.visits
                                .where(
                                  (visit) =>
                                      _visitStatuses[visit.id] ==
                                      VisitStatus.pending,
                                )
                                .where(
                                  (visit) =>
                                      _matchesPriorityFilter(visit: visit),
                                ))
                          _VisitRequestCard(
                            visit: visit,
                            status: _visitStatuses[visit.id]!,
                            onDetails: () => _showVisitDetails(visit),
                            onConfirm: () => _setVisitStatus(
                              visit.id,
                              VisitStatus.confirmed,
                            ),
                            onCancel: () => _setVisitStatus(
                              visit.id,
                              VisitStatus.cancelled,
                            ),
                          ),
                        if (pendingVisits == 0)
                          const _EmptyState(text: 'Aucune visite en attente.'),
                        for (final issue
                            in DemoData.issueReports
                                .where(
                                  (issue) =>
                                      _issueStatuses[issue.id] !=
                                      IssueStatus.resolved,
                                )
                                .where(
                                  (issue) =>
                                      _matchesPriorityFilter(issue: issue),
                                ))
                          _TrackingCard(
                            icon: Icons.build_rounded,
                            title: _issueCategoryLabel(issue.category),
                            subtitle:
                                '${_propertyTitle(issue.propertyId)} - ${issue.description}',
                            badge: _issueStatusLabel(_issueStatuses[issue.id]!),
                            color: issue.requiresFastAction
                                ? AppColors.danger
                                : AppColors.warning,
                            onTap: () => _showIssueDetails(issue),
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

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openService(_AgencyServiceType type) {
    _open(
      _AgencyServiceScreen(
        type: type,
        visitStatuses: _visitStatuses,
        contractStatuses: _contractStatuses,
        issueStatuses: _issueStatuses,
        onVisitTap: _showVisitDetails,
        onContractTap: _showContractDetails,
        onIssueTap: _showIssueDetails,
        onPaymentTap: _showPaymentDetails,
      ),
    );
  }

  bool _matchesPriorityFilter({Visit? visit, IssueReport? issue}) {
    return switch (_priorityFilter) {
      _AdminPriorityFilter.all => true,
      _AdminPriorityFilter.pendingVisits => visit != null,
      _AdminPriorityFilter.unpaidPayments => false,
      _AdminPriorityFilter.contractsToSign => false,
      _AdminPriorityFilter.urgentIssues =>
        issue != null && issue.priority == IssuePriority.urgent,
    };
  }

  void _setVisitStatus(String id, VisitStatus status) {
    setState(() => _visitStatuses[id] = status);
    notificationCenter.push(
      title: 'Visite ${_visitStatusLabel(status).toLowerCase()}',
      message: 'Le statut de la visite a ete mis a jour.',
      type: AppNotificationType.admin,
    );
    _adminApi
        .updateResource('visits', id, {'status': _visitStatusToApi(status)})
        .catchError((_) => <String, dynamic>{});
  }

  void _setContractStatus(String id, ContractStatus status) {
    setState(() => _contractStatuses[id] = status);
    notificationCenter.push(
      title: 'Contrat ${_contractStatusLabel(status).toLowerCase()}',
      message: 'Le statut du contrat a ete mis a jour.',
      type: AppNotificationType.contract,
    );
    _adminApi
        .updateResource('contracts', id, {
          'status': _contractStatusToApi(status),
        })
        .catchError((_) => <String, dynamic>{});
  }

  void _setIssueStatus(String id, IssueStatus status) {
    setState(() => _issueStatuses[id] = status);
    notificationCenter.push(
      title: 'Signalement ${_issueStatusLabel(status).toLowerCase()}',
      message: 'Le suivi technique a ete mis a jour.',
      type: AppNotificationType.issue,
    );
    _adminApi
        .updateResource('issue_reports', id, {
          'status': _issueStatusToApi(status),
        })
        .catchError((_) => <String, dynamic>{});
  }

  void _showVisitDetails(Visit visit) {
    _showDetails(
      title: 'Detail visite',
      rows: [
        _DetailRow('Bien', _propertyTitle(visit.propertyId)),
        _DetailRow('Client', _clientName(visit.clientId)),
        _DetailRow('Date', _formatDateTime(visit.scheduledAt)),
        _DetailRow('Statut', _visitStatusLabel(_visitStatuses[visit.id]!)),
        _DetailRow('Message', visit.message ?? 'Aucun message'),
      ],
      actions: [
        TextButton(
          onPressed: () async {
            final confirmed = await confirmSensitiveAction(
              context: context,
              title: 'Annuler la visite',
              message: 'Confirmer l annulation de cette visite ?',
              confirmLabel: 'Annuler la visite',
            );
            if (!confirmed || !mounted) return;
            Navigator.of(context).pop();
            _setVisitStatus(visit.id, VisitStatus.cancelled);
          },
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _setVisitStatus(visit.id, VisitStatus.confirmed);
          },
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  void _showContractDetails(Contract contract) {
    _showDetails(
      title: 'Detail contrat',
      rows: [
        _DetailRow('Reference', contract.reference),
        _DetailRow('Client', _clientName(contract.clientId)),
        _DetailRow('Bien', _propertyTitle(contract.propertyId)),
        _DetailRow('Montant', '${contract.amount} FCFA'),
        _DetailRow(
          'Statut',
          _contractStatusLabel(_contractStatuses[contract.id]!),
        ),
        _DetailRow('Debut', _formatDate(contract.startDate)),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _setContractStatus(contract.id, ContractStatus.cancelled);
          },
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _setContractStatus(contract.id, ContractStatus.signed);
          },
          child: const Text('Marquer signe'),
        ),
      ],
    );
  }

  void _showIssueDetails(IssueReport issue) {
    _showDetails(
      title: 'Detail signalement',
      rows: [
        _DetailRow('Bien', _propertyTitle(issue.propertyId)),
        _DetailRow('Client', _clientName(issue.clientId)),
        _DetailRow('Categorie', _issueCategoryLabel(issue.category)),
        _DetailRow('Priorite', _priorityLabel(issue.priority)),
        _DetailRow('Statut', _issueStatusLabel(_issueStatuses[issue.id]!)),
        _DetailRow('Description', issue.description),
        _DetailRow('Commentaire', issue.agencyComment ?? 'Aucun commentaire'),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _setIssueStatus(issue.id, IssueStatus.rejected);
          },
          child: const Text('Rejeter'),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _setIssueStatus(issue.id, IssueStatus.inProgress);
          },
          child: const Text('Prendre en charge'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _setIssueStatus(issue.id, IssueStatus.resolved);
          },
          child: const Text('Resolu'),
        ),
      ],
    );
  }

  void _showPaymentDetails(WavePayment payment) {
    _showDetails(
      title: 'Detail paiement',
      rows: [
        _DetailRow('Reference', payment.reference),
        _DetailRow('Client', _clientName(payment.clientId)),
        _DetailRow('Bien', _propertyTitle(payment.propertyId)),
        _DetailRow('Montant', '${payment.amount} FCFA'),
        _DetailRow('Telephone', payment.phone),
        _DetailRow('Statut', _paymentStatusLabel(payment.status)),
      ],
    );
  }

  void _showDetails({
    required String title,
    required List<_DetailRow> rows,
    List<Widget> actions = const [],
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                for (final row in rows) _DetailLine(row: row),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.pendingVisits,
    required this.openIssues,
    required this.unpaid,
  });

  final int pendingVisits;
  final int openIssues;
  final int unpaid;

  @override
  Widget build(BuildContext context) {
    return PremiumHeroPanel(
      eyebrow: 'Direction agence',
      title: 'Pilotage premium',
      subtitle:
          '$pendingVisits visite(s) a confirmer, $openIssues signalement(s) ouverts, $unpaid mensualite(s) a suivre.',
      trailing: const Icon(
        Icons.admin_panel_settings_rounded,
        size: 44,
        color: AppColors.background,
      ),
    );
  }
}

enum _AgencyServiceType {
  requests,
  calendar,
  messages,
  contracts,
  issues,
  payments,
}

enum _AdminPriorityFilter {
  all,
  pendingVisits,
  unpaidPayments,
  contractsToSign,
  urgentIssues,
}

class _AdminFilterBar extends StatelessWidget {
  const _AdminFilterBar({required this.selected, required this.onChanged});

  final _AdminPriorityFilter selected;
  final ValueChanged<_AdminPriorityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = {
      _AdminPriorityFilter.all: 'Tout',
      _AdminPriorityFilter.pendingVisits: 'Visites en attente',
      _AdminPriorityFilter.unpaidPayments: 'Paiements en retard',
      _AdminPriorityFilter.contractsToSign: 'Contrats a signer',
      _AdminPriorityFilter.urgentIssues: 'Signalements urgents',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in items.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected == entry.key,
                onSelected: (_) => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoreAgencyServicesScreen extends StatelessWidget {
  const _MoreAgencyServicesScreen({
    required this.openService,
    required this.openScreen,
  });

  final ValueChanged<_AgencyServiceType> openService;
  final ValueChanged<Widget> openScreen;

  @override
  Widget build(BuildContext context) {
    final services = [
      _MoreServiceItem(
        Icons.person_add_alt_1_rounded,
        'Comptes agence',
        'Creer admin, agent, proprietaire ou locataire.',
        () => openScreen(const AdminAccountScreen()),
      ),
      _MoreServiceItem(
        Icons.chat_bubble_rounded,
        'Echanges',
        'Messages clients et suivi interne.',
        () => openService(_AgencyServiceType.messages),
      ),
      _MoreServiceItem(
        Icons.description_rounded,
        'Contrats',
        'Signatures, annulations et documents.',
        () => openService(_AgencyServiceType.contracts),
      ),
      _MoreServiceItem(
        Icons.build_rounded,
        'Signalements',
        'Incidents techniques et interventions.',
        () => openService(_AgencyServiceType.issues),
      ),
      _MoreServiceItem(
        Icons.calendar_month_rounded,
        'Calendrier',
        'Tous les rendez-vous de visite.',
        () => openService(_AgencyServiceType.calendar),
      ),
      _MoreServiceItem(
        Icons.history_rounded,
        'Historique admin',
        'Toutes les actions sensibles journalisees.',
        () => openScreen(const _AdminAuditScreen()),
      ),
    ];

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
                    const PremiumHeroPanel(
                      eyebrow: 'Agence',
                      title: 'Services complementaires',
                      subtitle:
                          'Les fonctions moins frequentes restent disponibles sans surcharger le tableau de bord.',
                      trailing: Icon(
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
                      desktopAspectRatio: 2.65,
                      children: [
                        for (final service in services)
                          _MenuCard(
                            icon: service.icon,
                            title: service.title,
                            subtitle: service.subtitle,
                            onTap: service.onTap,
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

class _AgencyStatsScreen extends StatelessWidget {
  const _AgencyStatsScreen({
    required this.available,
    required this.pendingVisits,
    required this.openIssues,
    required this.unpaid,
  });

  final int available;
  final int pendingVisits;
  final int openIssues;
  final int unpaid;

  @override
  Widget build(BuildContext context) {
    final rented = DemoData.properties
        .where((property) => property.status == PropertyStatus.rented)
        .length;
    final sold = DemoData.properties
        .where((property) => property.status == PropertyStatus.sold)
        .length;
    final totalRevenue = DemoData.payments
        .where((payment) => payment.status == PaymentStatus.successful)
        .fold<int>(0, (total, payment) => total + payment.amount);
    final owners = DemoData.users
        .where((user) => user.role == UserRole.owner)
        .length;
    final tenants = DemoData.users
        .where((user) => user.role == UserRole.tenant)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: PremiumPage(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              PremiumResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumHeroPanel(
                      eyebrow: 'Performance agence',
                      title: 'Vue statistique',
                      subtitle:
                          '$totalRevenue FCFA confirmes, $pendingVisits visite(s) a confirmer et $openIssues signalement(s) actifs.',
                      trailing: const Icon(
                        Icons.insights_rounded,
                        color: AppColors.background,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumResponsiveGrid(
                      mobileColumns: 2,
                      tabletColumns: 3,
                      desktopColumns: 4,
                      mobileAspectRatio: 1.4,
                      desktopAspectRatio: 1.55,
                      children: [
                        _MetricCard(
                          icon: Icons.home_work_rounded,
                          value: '${DemoData.properties.length}',
                          label: 'biens publies',
                        ),
                        _MetricCard(
                          icon: Icons.key_rounded,
                          value: '$available',
                          label: 'disponibles',
                        ),
                        _MetricCard(
                          icon: Icons.apartment_rounded,
                          value: '$rented',
                          label: 'loues',
                        ),
                        _MetricCard(
                          icon: Icons.sell_rounded,
                          value: '$sold',
                          label: 'vendus',
                        ),
                        _MetricCard(
                          icon: Icons.calendar_month_rounded,
                          value: '$pendingVisits',
                          label: 'visites a confirmer',
                        ),
                        _MetricCard(
                          icon: Icons.report_problem_rounded,
                          value: '$openIssues',
                          label: 'signalements actifs',
                        ),
                        _MetricCard(
                          icon: Icons.warning_rounded,
                          value: '$unpaid',
                          label: 'paiements a suivre',
                        ),
                        _MetricCard(
                          icon: Icons.payments_rounded,
                          value:
                              '${(totalRevenue / 1000000).toStringAsFixed(1)}M',
                          label: 'FCFA confirmes',
                        ),
                        _MetricCard(
                          icon: Icons.people_rounded,
                          value: '$tenants',
                          label: 'locataires',
                        ),
                        _MetricCard(
                          icon: Icons.real_estate_agent_rounded,
                          value: '$owners',
                          label: 'proprietaires',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _StatsInsightCard(),
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

class _MoreServiceItem {
  const _MoreServiceItem(this.icon, this.title, this.subtitle, this.onTap);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _StatsInsightCard extends StatelessWidget {
  const _StatsInsightCard();

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lecture rapide', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            'Prioriser les visites en attente, relancer les paiements non confirmes et traiter les signalements urgents avant les actions de fond.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _AgencyServiceScreen extends StatelessWidget {
  const _AgencyServiceScreen({
    required this.type,
    required this.visitStatuses,
    required this.contractStatuses,
    required this.issueStatuses,
    required this.onVisitTap,
    required this.onContractTap,
    required this.onIssueTap,
    required this.onPaymentTap,
  });

  final _AgencyServiceType type;
  final Map<String, VisitStatus> visitStatuses;
  final Map<String, ContractStatus> contractStatuses;
  final Map<String, IssueStatus> issueStatuses;
  final ValueChanged<Visit> onVisitTap;
  final ValueChanged<Contract> onContractTap;
  final ValueChanged<IssueReport> onIssueTap;
  final ValueChanged<WavePayment> onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final title = _serviceTitle(type);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                      eyebrow: 'Agence',
                      title: title,
                      subtitle: _serviceSubtitle(type),
                      trailing: Icon(
                        _serviceIcon(type),
                        size: 42,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._items(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _items() {
    return switch (type) {
      _AgencyServiceType.requests => [
        for (final visit in DemoData.visits.where(
          (visit) => visitStatuses[visit.id] == VisitStatus.pending,
        )) ...[
          _TrackingCard(
            icon: Icons.notifications_active_rounded,
            title: _propertyTitle(visit.propertyId),
            subtitle:
                '${_clientName(visit.clientId)} - ${_formatDateTime(visit.scheduledAt)}',
            badge: _visitStatusLabel(visitStatuses[visit.id]!),
            color: AppColors.warning,
            onTap: () => onVisitTap(visit),
          ),
        ],
        if (!DemoData.visits.any(
          (visit) => visitStatuses[visit.id] == VisitStatus.pending,
        ))
          const _EmptyState(text: 'Aucune nouvelle demande.'),
      ],
      _AgencyServiceType.calendar => [
        for (final visit in DemoData.visits) ...[
          _TrackingCard(
            icon: Icons.calendar_month_rounded,
            title: _formatDateTime(visit.scheduledAt),
            subtitle:
                '${_propertyTitle(visit.propertyId)} - ${_clientName(visit.clientId)}',
            badge: _visitStatusLabel(visitStatuses[visit.id]!),
            color: AppColors.primary,
            onTap: () => onVisitTap(visit),
          ),
        ],
      ],
      _AgencyServiceType.messages => [
        const _MessageCard(
          sender: 'Aminata Diop',
          subject: 'Confirmation visite',
          message: 'Bonjour, je confirme ma disponibilite pour le rendez-vous.',
        ),
        const _MessageCard(
          sender: 'Equipe technique',
          subject: 'Signalement plomberie',
          message:
              'Intervention proposee demain matin apres validation agence.',
        ),
        const _MessageCard(
          sender: 'Service contrats',
          subject: 'Contrat en attente',
          message: 'Le document est pret pour verification finale.',
        ),
      ],
      _AgencyServiceType.contracts => [
        for (final contract in DemoData.contracts)
          _TrackingCard(
            icon: Icons.description_rounded,
            title: contract.reference,
            subtitle:
                '${_clientName(contract.clientId)} - ${_propertyTitle(contract.propertyId)}',
            badge: _contractStatusLabel(contractStatuses[contract.id]!),
            color: AppColors.primary,
            onTap: () => onContractTap(contract),
          ),
      ],
      _AgencyServiceType.issues => [
        for (final issue in DemoData.issueReports)
          _TrackingCard(
            icon: Icons.build_rounded,
            title: _issueCategoryLabel(issue.category),
            subtitle:
                '${_propertyTitle(issue.propertyId)} - ${issue.description}',
            badge: _issueStatusLabel(issueStatuses[issue.id]!),
            color: issue.requiresFastAction
                ? AppColors.danger
                : AppColors.warning,
            onTap: () => onIssueTap(issue),
          ),
      ],
      _AgencyServiceType.payments => [
        for (final payment in DemoData.payments)
          _TrackingCard(
            icon: Icons.account_balance_wallet_rounded,
            title: payment.reference,
            subtitle:
                '${_clientName(payment.clientId)} - ${payment.amount} FCFA',
            badge: _paymentStatusLabel(payment.status),
            color: AppColors.waveBlue,
            onTap: () => onPaymentTap(payment),
          ),
      ],
    };
  }
}

class _AdminAuditScreen extends StatefulWidget {
  const _AdminAuditScreen();

  @override
  State<_AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<_AdminAuditScreen> {
  final _adminApi = const AdminApi();
  late Future<List<Map<String, dynamic>>> _future = _adminApi.auditLogs();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique admin')),
      body: PremiumPage(
        child: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <Map<String, dynamic>>[];
              return RefreshIndicator(
                onRefresh: () async {
                  final next = _adminApi.auditLogs();
                  setState(() => _future = next);
                  await next;
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    PremiumResponsiveContent(
                      maxWidth: 980,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PremiumHeroPanel(
                            eyebrow: 'Audit',
                            title: 'Historique des actions',
                            subtitle:
                                'Creation, modification et suppression des ressources agence.',
                            trailing: Icon(
                              Icons.history_rounded,
                              color: AppColors.background,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (items.isEmpty)
                            const _EmptyState(
                              text: 'Aucune action journalisee.',
                            )
                          else
                            for (final item in items)
                              _TrackingCard(
                                icon: Icons.history_rounded,
                                title:
                                    '${item['action'] ?? ''} ${item['resource'] ?? ''}',
                                subtitle:
                                    '${item['actor_name'] ?? 'Agence'} - ${item['created_at'] ?? ''}',
                                badge:
                                    item['resource_id']?.toString() ?? 'audit',
                                color: AppColors.primary,
                                onTap: () {},
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.background),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.sender,
    required this.subject,
    required this.message,
  });

  final String sender;
  final String subject;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumPanel(
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sender, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subject, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _VisitRequestCard extends StatelessWidget {
  const _VisitRequestCard({
    required this.visit,
    required this.status,
    required this.onDetails,
    required this.onConfirm,
    required this.onCancel,
  });

  final Visit visit;
  final VisitStatus status;
  final VoidCallback onDetails;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      highlight: true,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _propertyTitle(visit.propertyId),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _Badge(
                  text: _visitStatusLabel(status),
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_clientName(visit.clientId)} - ${_formatDateTime(visit.scheduledAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final width = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: width,
                      child: OutlinedButton.icon(
                        onPressed: onDetails,
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Details'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Annuler'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FilledButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Confirmer'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumPanel(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Badge(text: badge, color: color),
              ],
            ),
          ),
        ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.row});

  final _DetailRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(row.value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

String _serviceTitle(_AgencyServiceType type) {
  return switch (type) {
    _AgencyServiceType.requests => 'Demandes',
    _AgencyServiceType.calendar => 'Calendrier',
    _AgencyServiceType.messages => 'Echanges',
    _AgencyServiceType.contracts => 'Contrats',
    _AgencyServiceType.issues => 'Signalements',
    _AgencyServiceType.payments => 'Paiements PayDunya',
  };
}

String _serviceSubtitle(_AgencyServiceType type) {
  return switch (type) {
    _AgencyServiceType.requests =>
      'Les nouvelles demandes clients a confirmer ou traiter.',
    _AgencyServiceType.calendar =>
      'Les visites programmees et les rendez-vous de l agence.',
    _AgencyServiceType.messages =>
      'Les conversations utiles entre clients, agence et equipes terrain.',
    _AgencyServiceType.contracts => 'Les contrats a signer, annuler ou suivre.',
    _AgencyServiceType.issues =>
      'Les incidents techniques avec priorite et statut.',
    _AgencyServiceType.payments =>
      'Les avances, loyers et paiements a rapprocher.',
  };
}

IconData _serviceIcon(_AgencyServiceType type) {
  return switch (type) {
    _AgencyServiceType.requests => Icons.notifications_active_rounded,
    _AgencyServiceType.calendar => Icons.calendar_month_rounded,
    _AgencyServiceType.messages => Icons.chat_bubble_rounded,
    _AgencyServiceType.contracts => Icons.description_rounded,
    _AgencyServiceType.issues => Icons.build_rounded,
    _AgencyServiceType.payments => Icons.account_balance_wallet_rounded,
  };
}

String _propertyTitle(String propertyId) {
  return DemoData.properties
      .firstWhere((property) => property.id == propertyId)
      .title;
}

String _clientName(String userId) {
  return DemoData.users.firstWhere((user) => user.id == userId).fullName;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)} a $hour:$minute';
}

String _visitStatusLabel(VisitStatus status) {
  return switch (status) {
    VisitStatus.pending => 'En attente',
    VisitStatus.confirmed => 'Confirmee',
    VisitStatus.completed => 'Terminee',
    VisitStatus.cancelled => 'Annulee',
  };
}

String _visitStatusToApi(VisitStatus status) {
  return switch (status) {
    VisitStatus.pending => 'pending',
    VisitStatus.confirmed => 'confirmed',
    VisitStatus.completed => 'completed',
    VisitStatus.cancelled => 'cancelled',
  };
}

String _paymentStatusLabel(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.pending => 'En attente',
    PaymentStatus.successful => 'Reussi',
    PaymentStatus.failed => 'Echoue',
    PaymentStatus.cancelled => 'Annule',
  };
}

String _contractStatusLabel(ContractStatus status) {
  return switch (status) {
    ContractStatus.draft => 'Brouillon',
    ContractStatus.pendingSignature => 'Signature en attente',
    ContractStatus.signed => 'Signe',
    ContractStatus.cancelled => 'Annule',
  };
}

String _contractStatusToApi(ContractStatus status) {
  return switch (status) {
    ContractStatus.draft => 'draft',
    ContractStatus.pendingSignature => 'pending_signature',
    ContractStatus.signed => 'signed',
    ContractStatus.cancelled => 'cancelled',
  };
}

String _issueCategoryLabel(IssueCategory category) {
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

String _issueStatusLabel(IssueStatus status) {
  return switch (status) {
    IssueStatus.newReport => 'Nouveau',
    IssueStatus.inProgress => 'En cours',
    IssueStatus.resolved => 'Resolu',
    IssueStatus.rejected => 'Rejete',
  };
}

String _issueStatusToApi(IssueStatus status) {
  return switch (status) {
    IssueStatus.newReport => 'new_report',
    IssueStatus.inProgress => 'in_progress',
    IssueStatus.resolved => 'resolved',
    IssueStatus.rejected => 'rejected',
  };
}

String _priorityLabel(IssuePriority priority) {
  return switch (priority) {
    IssuePriority.low => 'Faible',
    IssuePriority.normal => 'Normale',
    IssuePriority.urgent => 'Urgente',
  };
}
