import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/app_user.dart';
import '../models/contract.dart';
import '../models/issue_report.dart';
import '../models/visit.dart';
import '../models/wave_payment.dart';
import '../services/app_session.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSession,
      builder: (context, _) {
        if (!appSession.isAuthenticated) {
          return const _VisitorProfileGate();
        }

        final client = appSession.user!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil client'),
            actions: [
              IconButton(
                tooltip: 'Modifier le profil',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_rounded),
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
                key: const Key('profile_list'),
                padding: EdgeInsets.zero,
                children: [
                  PremiumResponsiveContent(
                    maxWidth: 980,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileHeader(client: client),
                        const SizedBox(height: 16),
                        PremiumAdaptiveRow(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ProfileEditScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.manage_accounts_rounded),
                              label: const Text('Modifier profil'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                appSession.signOut();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const MainNavigationScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Deconnexion'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProfileStats(clientId: client.id),
                        const SizedBox(height: 22),
                        _Section(
                          title: 'Visites',
                          children: [
                            for (final visit in DemoData.visits.where(
                              (item) => item.clientId == client.id,
                            ))
                              _HistoryCard(
                                icon: Icons.calendar_month_rounded,
                                title: _propertyTitle(visit.propertyId),
                                subtitle:
                                    '${_visitStatusLabel(visit.status)} - ${_formatDateTime(visit.scheduledAt)}',
                              ),
                          ],
                        ),
                        _Section(
                          title: 'Paiements',
                          children: [
                            for (final payment in DemoData.payments.where(
                              (item) => item.clientId == client.id,
                            ))
                              _HistoryCard(
                                icon: Icons.account_balance_wallet_rounded,
                                title: payment.reference,
                                subtitle:
                                    '${payment.amount} FCFA - ${_paymentStatusLabel(payment.status)}',
                              ),
                          ],
                        ),
                        _Section(
                          title: 'Contrats',
                          children: [
                            for (final contract in DemoData.contracts.where(
                              (item) => item.clientId == client.id,
                            ))
                              _HistoryCard(
                                icon: Icons.description_rounded,
                                title: contract.reference,
                                subtitle:
                                    '${_contractStatusLabel(contract.status)} - ${contract.amount} FCFA',
                              ),
                          ],
                        ),
                        _Section(
                          title: 'Recus',
                          children: [
                            for (final receipt in DemoData.receipts.where(
                              (item) => item.clientId == client.id,
                            ))
                              _HistoryCard(
                                icon: Icons.receipt_long_rounded,
                                title: receipt.reference,
                                subtitle:
                                    '${receipt.label} - ${receipt.amount} FCFA',
                              ),
                          ],
                        ),
                        _Section(
                          title: 'Signalements',
                          children: [
                            for (final issue in DemoData.issueReports.where(
                              (item) => item.clientId == client.id,
                            ))
                              _HistoryCard(
                                icon: Icons.build_rounded,
                                title: _issueCategoryLabel(issue.category),
                                subtitle:
                                    '${_issueStatusLabel(issue.status)} - ${issue.description}',
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
      },
    );
  }
}

class _VisitorProfileGate extends StatelessWidget {
  const _VisitorProfileGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode visiteur')),
      body: PremiumPage(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              PremiumResponsiveContent(
                maxWidth: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PremiumHeroPanel(
                      eyebrow: 'Mode visiteur',
                      title: 'Vous consultez en visiteur',
                      subtitle:
                          'Les biens restent visibles. Connectez-vous pour demander une visite, acheter, payer, consulter vos contrats ou signaler un probleme.',
                      trailing: Icon(
                        Icons.travel_explore_rounded,
                        color: AppColors.background,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Se connecter ou creer un compte'),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.client});

  final AppUser client;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      highlight: true,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _initials(client.fullName),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.background),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  client.phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                if (client.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    client.email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    final visits = DemoData.visits
        .where((item) => item.clientId == clientId)
        .length;
    final payments = DemoData.payments
        .where((item) => item.clientId == clientId)
        .length;
    final issues = DemoData.issueReports
        .where((item) => item.clientId == clientId)
        .length;

    return PremiumAdaptiveRow(
      breakpoint: 620,
      children: [
        _StatCard(value: '$visits', label: 'visites'),
        _StatCard(value: '$payments', label: 'paiements'),
        _StatCard(value: '$issues', label: 'suivis'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
          if (children.isEmpty)
            Text(
              'Aucun element pour le moment.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumPanel(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
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
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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

String _visitStatusLabel(VisitStatus status) {
  return switch (status) {
    VisitStatus.pending => 'En attente',
    VisitStatus.confirmed => 'Confirmee',
    VisitStatus.completed => 'Terminee',
    VisitStatus.cancelled => 'Annulee',
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
