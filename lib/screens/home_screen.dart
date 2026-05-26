import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/property.dart';
import '../services/app_session.dart';
import '../theme/app_colors.dart';
import 'agency_dashboard_screen.dart';
import 'auth_screen.dart';
import 'colocation_screen.dart';
import 'role_dashboard_screen.dart';
import 'sales_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _services = [
    _ServiceItem(Icons.apartment, 'Location', 'Appartements et studios'),
    _ServiceItem(Icons.groups_rounded, 'Colocation', 'Chambres partagees'),
    _ServiceItem(Icons.home_work_rounded, 'Vente', 'Maisons et villas'),
    _ServiceItem(Icons.map_rounded, 'Terrains', 'Parcelles verifiees'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ImmoAgence'),
        actions: [
          AnimatedBuilder(
            animation: appSession,
            builder: (context, _) {
              return TextButton.icon(
                onPressed: () {
                  if (appSession.isAuthenticated) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => appSession.isAdmin
                            ? const AgencyDashboardScreen()
                            : RoleDashboardScreen(
                                role: appSession.role,
                                displayName: appSession.user!.fullName,
                              ),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AuthScreen(),
                      ),
                    );
                  }
                },
                icon: Icon(
                  appSession.isAuthenticated
                      ? Icons.dashboard_rounded
                      : Icons.login_rounded,
                ),
                label: Text(appSession.isAuthenticated ? 'Dashboard' : 'Login'),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('home_list'),
          padding: const EdgeInsets.all(20),
          children: const [
            _HeroSearchPanel(),
            SizedBox(height: 18),
            _SectionTitle(title: 'Biens recemment ajoutes'),
            SizedBox(height: 12),
            _RecentProperties(),
            SizedBox(height: 22),
            _SectionTitle(title: 'Services'),
            SizedBox(height: 12),
            _ServicesGrid(),
            SizedBox(height: 22),
            _SectionTitle(title: 'Biens recommandes'),
            SizedBox(height: 12),
            _RecommendedProperties(),
          ],
        ),
      ),
    );
  }
}

class _HeroSearchPanel extends StatelessWidget {
  const _HeroSearchPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.petroleum,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Agence immobiliere au Senegal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Trouvez un logement fiable, visitez, signez et payez avec suivi.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Location, colocation, vente de maisons et terrains avec contrats, recus et assistance technique.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.place_rounded),
              labelText: 'Quartier',
              hintText: 'Ex: Almadies, Plateau, Saly',
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _SearchSelect(
                  icon: Icons.home_work_rounded,
                  label: 'Type',
                  value: 'Tous',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SearchSelect(
                  icon: Icons.payments_rounded,
                  label: 'Budget',
                  value: 'Tout budget',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
            label: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }
}

class _SearchSelect extends StatelessWidget {
  const _SearchSelect({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    value,
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

class _RecentProperties extends StatelessWidget {
  const _RecentProperties();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final property in DemoData.properties.take(3)) ...[
          _RecentPropertyTile(property: property),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecentPropertyTile extends StatelessWidget {
  const _RecentPropertyTile({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            property.imagePaths.first,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          property.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${property.location} - ${property.formattedPrice}'),
        trailing: const Icon(Icons.chevron_right_rounded),
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

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.42,
      children: [
        for (final item in HomeScreen._services) _ServiceCard(item: item),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: Key('service_${item.title}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (item.title == 'Colocation') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ColocationScreen()),
            );
          }

          if (item.title == 'Vente' || item.title == 'Terrains') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SalesScreen(landOnly: item.title == 'Terrains'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedProperties extends StatelessWidget {
  const _RecommendedProperties();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DemoData.properties.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final property = DemoData.properties[index];
          return _PropertyPreviewCard(property: property);
        },
      ),
    );
  }
}

class _PropertyPreviewCard extends StatelessWidget {
  const _PropertyPreviewCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 238,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  property.imagePaths.first,
                  width: 238,
                  height: 112,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _StatusBadge(property: property),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 116,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      property.formattedPrice,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final label = switch (property.offerType) {
      PropertyOfferType.rent => 'Location',
      PropertyOfferType.sale => 'Vente',
      PropertyOfferType.colocation => 'Colocation',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.petroleum,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}
