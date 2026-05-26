import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/property.dart';
import '../services/property_api.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';
import '../widgets/property_image.dart';
import 'property_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _propertyApi = const PropertyApi();
  final _searchController = TextEditingController();
  PropertyOfferType? _selectedOfferType;
  PropertyType? _selectedType;
  PropertyStatus? _selectedStatus;
  RangeValues _budgetRange = const RangeValues(0, 100000000);
  bool? _furnishedOnly;
  double _minSurface = 0;
  int _minRooms = 0;
  int _visibleCount = 10;
  late Future<List<Property>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Property>> _loadProperties() async {
    try {
      final properties = await _propertyApi.list();
      return properties.isEmpty ? DemoData.properties : properties;
    } catch (_) {
      return DemoData.properties;
    }
  }

  List<Property> _filteredProperties(List<Property> source) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((property) {
      final matchesQuery =
          query.isEmpty ||
          property.location.toLowerCase().contains(query) ||
          property.title.toLowerCase().contains(query) ||
          property.description.toLowerCase().contains(query);
      final matchesOffer =
          _selectedOfferType == null ||
          property.offerType == _selectedOfferType;
      final matchesType =
          _selectedType == null || property.type == _selectedType;
      final matchesStatus =
          _selectedStatus == null || property.status == _selectedStatus;
      final matchesBudget =
          property.price >= _budgetRange.start &&
          property.price <= _budgetRange.end;
      final matchesSurface =
          property.surfaceArea == null || property.surfaceArea! >= _minSurface;
      final matchesRooms =
          property.rooms == null || property.rooms! >= _minRooms;
      final matchesFurnished =
          _furnishedOnly == null || property.isFurnished == _furnishedOnly;
      return matchesQuery &&
          matchesOffer &&
          matchesType &&
          matchesStatus &&
          matchesBudget &&
          matchesSurface &&
          matchesRooms &&
          matchesFurnished;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue des biens'),
        actions: [
          IconButton(
            tooltip: 'Filtres',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Property>>(
          future: _propertiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: PremiumLoadingState(label: 'Chargement du catalogue...'),
              );
            }
            final properties = _filteredProperties(
              snapshot.data ?? DemoData.properties,
            );
            final visibleProperties = properties.take(_visibleCount).toList();
            return RefreshIndicator(
              onRefresh: () async {
                final future = _loadProperties();
                setState(() => _propertiesFuture = future);
                await future;
              },
              child: ListView(
                key: const Key('catalog_list'),
                padding: const EdgeInsets.all(20),
                children: [
                  const _CatalogHeader(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _visibleCount = 10),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Quartier, titre ou description',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OfferFilterBar(
                    selectedOfferType: _selectedOfferType,
                    onChanged: (value) =>
                        setState(() => _selectedOfferType = value),
                  ),
                  const SizedBox(height: 12),
                  _AdvancedFilters(
                    selectedType: _selectedType,
                    selectedStatus: _selectedStatus,
                    budgetRange: _budgetRange,
                    furnishedOnly: _furnishedOnly,
                    minSurface: _minSurface,
                    minRooms: _minRooms,
                    onTypeChanged: (value) =>
                        setState(() => _selectedType = value),
                    onStatusChanged: (value) =>
                        setState(() => _selectedStatus = value),
                    onBudgetChanged: (value) =>
                        setState(() => _budgetRange = value),
                    onFurnishedChanged: (value) =>
                        setState(() => _furnishedOnly = value),
                    onSurfaceChanged: (value) =>
                        setState(() => _minSurface = value),
                    onRoomsChanged: (value) =>
                        setState(() => _minRooms = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${properties.length} biens trouves',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (properties.isEmpty)
                    const PremiumEmptyState(
                      title: 'Aucun bien trouve',
                      message: 'Ajustez les filtres ou elargissez le budget.',
                      icon: Icons.search_off_rounded,
                    ),
                  for (final property in visibleProperties) ...[
                    _CatalogPropertyCard(property: property),
                    const SizedBox(height: 12),
                  ],
                  if (visibleProperties.length < properties.length)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _visibleCount += 10),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Charger plus'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tous les biens de l agence',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Parcourez les locations, colocations, maisons a vendre et terrains disponibles.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({
    required this.selectedType,
    required this.selectedStatus,
    required this.budgetRange,
    required this.furnishedOnly,
    required this.minSurface,
    required this.minRooms,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onBudgetChanged,
    required this.onFurnishedChanged,
    required this.onSurfaceChanged,
    required this.onRoomsChanged,
  });

  final PropertyType? selectedType;
  final PropertyStatus? selectedStatus;
  final RangeValues budgetRange;
  final bool? furnishedOnly;
  final double minSurface;
  final int minRooms;
  final ValueChanged<PropertyType?> onTypeChanged;
  final ValueChanged<PropertyStatus?> onStatusChanged;
  final ValueChanged<RangeValues> onBudgetChanged;
  final ValueChanged<bool?> onFurnishedChanged;
  final ValueChanged<double> onSurfaceChanged;
  final ValueChanged<int> onRoomsChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Recherche avancee'),
      children: [
        DropdownButtonFormField<PropertyType?>(
          initialValue: selectedType,
          decoration: const InputDecoration(labelText: 'Type de bien'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tous')),
            for (final type in PropertyType.values)
              DropdownMenuItem(value: type, child: Text(_typeLabel(type))),
          ],
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<PropertyStatus?>(
          initialValue: selectedStatus,
          decoration: const InputDecoration(labelText: 'Statut'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tous')),
            for (final status in PropertyStatus.values)
              DropdownMenuItem(
                value: status,
                child: Text(_statusLabel(status)),
              ),
          ],
          onChanged: onStatusChanged,
        ),
        const SizedBox(height: 10),
        Text(
          'Budget: ${budgetRange.start.round()} - ${budgetRange.end.round()} FCFA',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        RangeSlider(
          values: budgetRange,
          min: 0,
          max: 100000000,
          divisions: 20,
          onChanged: onBudgetChanged,
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<bool?>(
                initialValue: furnishedOnly,
                decoration: const InputDecoration(labelText: 'Meuble'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tous')),
                  DropdownMenuItem(value: true, child: Text('Oui')),
                  DropdownMenuItem(value: false, child: Text('Non')),
                ],
                onChanged: onFurnishedChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: minRooms,
                decoration: const InputDecoration(labelText: 'Pieces min.'),
                items: [
                  for (var i = 0; i <= 6; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(i == 0 ? 'Tous' : '$i+'),
                    ),
                ],
                onChanged: (value) => onRoomsChanged(value ?? 0),
              ),
            ),
          ],
        ),
        Slider(
          value: minSurface,
          min: 0,
          max: 500,
          divisions: 10,
          label: '${minSurface.round()} m2 min.',
          onChanged: onSurfaceChanged,
        ),
      ],
    );
  }
}

class _OfferFilterBar extends StatelessWidget {
  const _OfferFilterBar({
    required this.selectedOfferType,
    required this.onChanged,
  });

  final PropertyOfferType? selectedOfferType;
  final ValueChanged<PropertyOfferType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tous',
            selected: selectedOfferType == null,
            onTap: () => onChanged(null),
          ),
          _FilterChip(
            label: 'Location',
            selected: selectedOfferType == PropertyOfferType.rent,
            onTap: () => onChanged(PropertyOfferType.rent),
          ),
          _FilterChip(
            label: 'Vente',
            selected: selectedOfferType == PropertyOfferType.sale,
            onTap: () => onChanged(PropertyOfferType.sale),
          ),
          _FilterChip(
            label: 'Colocation',
            selected: selectedOfferType == PropertyOfferType.colocation,
            onTap: () => onChanged(PropertyOfferType.colocation),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.14),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _CatalogPropertyCard extends StatelessWidget {
  const _CatalogPropertyCard({required this.property});

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
            PropertyImage(
              path: property.imagePaths.first,
              width: double.infinity,
              height: 176,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _OfferBadge(offerType: property.offerType),
                      const Spacer(),
                      _AvailabilityBadge(status: property.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
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
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final feature in property.features.take(3))
                        _FeaturePill(label: feature),
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

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({required this.offerType});

  final PropertyOfferType offerType;

  @override
  Widget build(BuildContext context) {
    final label = switch (offerType) {
      PropertyOfferType.rent => 'Location',
      PropertyOfferType.sale => 'Vente',
      PropertyOfferType.colocation => 'Colocation',
    };

    return _FeaturePill(label: label, color: AppColors.primary);
  }
}

String _typeLabel(PropertyType type) {
  return switch (type) {
    PropertyType.apartment => 'Appartement',
    PropertyType.house => 'Maison',
    PropertyType.villa => 'Villa',
    PropertyType.studio => 'Studio',
    PropertyType.land => 'Terrain',
    PropertyType.sharedRoom => 'Colocation',
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

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.status});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PropertyStatus.available => ('Disponible', AppColors.success),
      PropertyStatus.reserved => ('Reserve', AppColors.warning),
      PropertyStatus.rented => ('Loue', AppColors.textSecondary),
      PropertyStatus.sold => ('Vendu', AppColors.textSecondary),
    };

    return _FeaturePill(label: label, color: color);
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.label,
    this.color = AppColors.textSecondary,
  });

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
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
