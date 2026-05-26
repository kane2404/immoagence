import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import 'property_detail_screen.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key, this.landOnly = false});

  final bool landOnly;

  List<Property> get _salesProperties {
    final sales = DemoData.properties.where(
      (property) => property.offerType == PropertyOfferType.sale,
    );

    if (landOnly) {
      return sales
          .where((property) => property.type == PropertyType.land)
          .toList();
    }

    return sales.toList();
  }

  @override
  Widget build(BuildContext context) {
    final properties = _salesProperties;

    return Scaffold(
      appBar: AppBar(
        title: Text(landOnly ? 'Terrains a vendre' : 'Vente immo'),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('sales_list'),
          padding: const EdgeInsets.all(20),
          children: [
            _SalesHeader(landOnly: landOnly),
            const SizedBox(height: 16),
            const _PurchaseChecklist(),
            const SizedBox(height: 18),
            Text(
              '${properties.length} opportunites',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final property in properties) ...[
              _SalePropertyCard(property: property),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalesHeader extends StatelessWidget {
  const _SalesHeader({required this.landOnly});

  final bool landOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.petroleum,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            landOnly ? 'Terrains verifies' : 'Acheter avec suivi agence',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            landOnly
                ? 'Parcelles avec documents disponibles, localisation claire et accompagnement jusqu a la signature.'
                : 'Maisons, villas et terrains avec documents, visite, reservation et contrat de vente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseChecklist extends StatelessWidget {
  const _PurchaseChecklist();

  @override
  Widget build(BuildContext context) {
    const items = [
      _ChecklistItem(Icons.verified_user_rounded, 'Documents verifies'),
      _ChecklistItem(Icons.map_rounded, 'Localisation controlee'),
      _ChecklistItem(Icons.description_rounded, 'Contrat accompagne'),
    ];

    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _ChecklistCard(item: items[index])),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.item});

  final _ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalePropertyCard extends StatelessWidget {
  const _SalePropertyCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  property.imagePaths.first,
                  width: double.infinity,
                  height: 184,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _SaleBadge(label: _propertyTypeLabel(property.type)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: AppColors.textSecondary,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    property.formattedPrice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SaleBadge(
                        label: property.status == PropertyStatus.available
                            ? 'Disponible'
                            : 'Reserve',
                        color: property.status == PropertyStatus.available
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const _SaleBadge(label: 'Dossier disponible'),
                      const _SaleBadge(label: 'Visite possible'),
                    ],
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

class _SaleBadge extends StatelessWidget {
  const _SaleBadge({required this.label, this.color = AppColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

class _ChecklistItem {
  const _ChecklistItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

String _propertyTypeLabel(PropertyType type) {
  return switch (type) {
    PropertyType.apartment => 'Appartement',
    PropertyType.house => 'Maison',
    PropertyType.villa => 'Villa',
    PropertyType.studio => 'Studio',
    PropertyType.land => 'Terrain',
    PropertyType.sharedRoom => 'Colocation',
  };
}
