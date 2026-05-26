import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import 'property_detail_screen.dart';

class ColocationScreen extends StatelessWidget {
  const ColocationScreen({super.key});

  List<Property> get _sharedRooms => DemoData.properties
      .where((property) => property.offerType == PropertyOfferType.colocation)
      .toList();

  @override
  Widget build(BuildContext context) {
    final rooms = _sharedRooms;

    return Scaffold(
      appBar: AppBar(title: const Text('Colocation')),
      body: SafeArea(
        child: ListView(
          key: const Key('colocation_list'),
          padding: const EdgeInsets.all(20),
          children: [
            const _ColocationHeader(),
            const SizedBox(height: 16),
            const _ChargesPanel(),
            const SizedBox(height: 18),
            const _RulesPanel(),
            const SizedBox(height: 18),
            Text(
              '${rooms.length} chambre disponible',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final room in rooms) ...[
              _RoomCard(room: room),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColocationHeader extends StatelessWidget {
  const _ColocationHeader();

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
            'Colocation geree par agence',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Chambres avec regles claires, charges suivies, contrat de colocation et signalements partages.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargesPanel extends StatelessWidget {
  const _ChargesPanel();

  @override
  Widget build(BuildContext context) {
    const charges = [
      _ChargeItem(Icons.water_drop_rounded, 'Eau', 'incluse selon contrat'),
      _ChargeItem(Icons.bolt_rounded, 'Electricite', 'compteur partage'),
      _ChargeItem(Icons.wifi_rounded, 'Internet', 'option selon logement'),
    ];

    return Row(
      children: [
        for (var index = 0; index < charges.length; index++) ...[
          Expanded(child: _ChargeCard(item: charges[index])),
          if (index != charges.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ChargeCard extends StatelessWidget {
  const _ChargeCard({required this.item});

  final _ChargeItem item;

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
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
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

class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    const rules = [
      'Paiement avant le 5 de chaque mois.',
      'Respect des espaces communs et du voisinage.',
      'Signalement rapide des problemes eau, electricite ou plomberie.',
      'Remplacement de colocataire valide par l agence.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regles de colocation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final rule in rules) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});

  final Property room;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PropertyDetailScreen(property: room),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              room.imagePaths.first,
              width: double.infinity,
              height: 176,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RoomBadge(label: 'Chambre disponible'),
                  const SizedBox(height: 10),
                  Text(
                    room.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room.location,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    room.formattedPrice,
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
                      for (final feature in room.features)
                        _RoomBadge(label: feature, color: AppColors.petroleum),
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

class _RoomBadge extends StatelessWidget {
  const _RoomBadge({required this.label, this.color = AppColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

class _ChargeItem {
  const _ChargeItem(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}
