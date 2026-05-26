import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/app_session.dart';
import '../theme/app_colors.dart';
import '../widgets/property_image.dart';
import 'auth_screen.dart';
import 'contract_screen.dart';
import 'issue_report_screen.dart';
import 'visit_schedule_screen.dart';
import 'wave_payment_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail du bien')),
      body: SafeArea(
        child: ListView(
          key: const Key('property_detail_list'),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _PropertyGallery(property: property),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _InfoBadge(label: _offerLabel(property.offerType)),
                      const SizedBox(width: 8),
                      _InfoBadge(
                        label: _statusLabel(property.status),
                        color: _statusColor(property.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    property.title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          property.location,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    property.formattedPrice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Resume'),
                  const SizedBox(height: 10),
                  _SummaryGrid(property: property),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Description'),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Equipements et atouts'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final feature in property.features)
                        _InfoBadge(label: feature, color: AppColors.petroleum),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: property.isAvailable
                        ? () {
                            if (!appSession.isAuthenticated) {
                              _requireAccount(context);
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    WavePaymentScreen(property: property),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.account_balance_wallet_rounded),
                    label: const Text('Payer avec PayDunya'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: property.isAvailable
                        ? () {
                            if (!appSession.isAuthenticated) {
                              _requireAccount(context);
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => VisitScheduleScreen(
                                  initialProperty: property,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Programmer une visite'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!appSession.isAuthenticated) {
                        _requireAccount(context);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ContractScreen(property: property),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description_rounded),
                    label: const Text('Demander le contrat'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!appSession.isAuthenticated) {
                        _requireAccount(context);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              IssueReportScreen(initialProperty: property),
                        ),
                      );
                    },
                    icon: const Icon(Icons.water_damage_rounded),
                    label: const Text('Signaler un probleme'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _requireAccount(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Connexion requise'),
      content: const Text(
        'Le mode visiteur permet de consulter les biens. Connectez-vous pour acheter, payer, demander une visite ou signaler un probleme.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
          },
          child: const Text('Se connecter'),
        ),
      ],
    ),
  );
}

class _PropertyGallery extends StatelessWidget {
  const _PropertyGallery({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PropertyImage(
          path: property.imagePaths.first,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${property.imagePaths.length} photo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        Icons.king_bed_rounded,
        'Pieces',
        property.rooms?.toString() ?? '-',
      ),
      _SummaryItem(
        Icons.bathtub_rounded,
        'Douches',
        property.bathrooms?.toString() ?? '-',
      ),
      _SummaryItem(
        Icons.square_foot_rounded,
        'Surface',
        property.surfaceArea == null
            ? '-'
            : '${property.surfaceArea!.round()} m2',
      ),
      _SummaryItem(
        Icons.chair_rounded,
        'Meuble',
        property.isFurnished ? 'Oui' : 'Non',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final item in items) _SummaryCard(item: item)],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, this.color = AppColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

String _offerLabel(PropertyOfferType offerType) {
  return switch (offerType) {
    PropertyOfferType.rent => 'Location',
    PropertyOfferType.sale => 'Vente',
    PropertyOfferType.colocation => 'Colocation',
  };
}

String _statusLabel(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => 'Disponible',
    PropertyStatus.reserved => 'Reserve',
    PropertyStatus.rented => 'Loue',
    PropertyStatus.sold => 'Vendu',
  };
}

Color _statusColor(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => AppColors.success,
    PropertyStatus.reserved => AppColors.warning,
    PropertyStatus.rented => AppColors.textSecondary,
    PropertyStatus.sold => AppColors.textSecondary,
  };
}
