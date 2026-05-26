import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/property.dart';
import '../services/admin_api.dart';
import '../services/api_exception.dart';
import '../services/notification_center.dart';
import '../services/photo_upload_service.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';

class AdminPropertyCrudScreen extends StatefulWidget {
  const AdminPropertyCrudScreen({super.key});

  @override
  State<AdminPropertyCrudScreen> createState() =>
      _AdminPropertyCrudScreenState();
}

class _AdminPropertyCrudScreenState extends State<AdminPropertyCrudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _adminApi = const AdminApi();
  final _photoUploadService = const PhotoUploadService();

  final List<AppUser> _users = [...DemoData.users];
  final List<_ManagedProperty> _properties = [
    for (final property in DemoData.properties)
      _ManagedProperty(property: property, ownerId: 'user_003', tenantId: null),
  ];

  PropertyType _type = PropertyType.house;
  PropertyOfferType _offerType = PropertyOfferType.sale;
  PropertyStatus _status = PropertyStatus.available;
  String? _ownerId = 'user_003';
  String? _tenantId;
  _ManagedProperty? _editingItem;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final results = await Future.wait([
        _adminApi.properties(),
        _adminApi.users(),
      ]);
      final properties = results[0] as List<Property>;
      final users = results[1] as List<AppUser>;
      if (!mounted || properties.isEmpty) return;
      setState(() {
        _users
          ..clear()
          ..addAll(users);
        _properties
          ..clear()
          ..addAll([
            for (final property in properties)
              _ManagedProperty(
                property: property,
                ownerId: null,
                tenantId: null,
              ),
          ]);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final editingItem = _editingItem;
    final property = Property(
      id:
          editingItem?.property.id ??
          'property_local_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      type: _type,
      offerType: _offerType,
      status: _status,
      price: int.parse(_priceController.text.trim()),
      location: _locationController.text.trim(),
      imagePaths: [DemoData.properties.first.imagePaths.first],
      description: 'Bien publie par l administrateur.',
      features: ['Document verifie', 'Suivi agence', 'Disponible'],
    );

    var savedProperty = property;
    try {
      if (editingItem == null) {
        savedProperty = await _adminApi.createProperty(
          title: property.title,
          type: property.type,
          offerType: property.offerType,
          price: property.price,
          location: property.location,
          description: property.description,
          imageUrl: _imageUrlController.text.trim(),
          ownerId: _ownerId,
          tenantId: _tenantId,
        );
      } else {
        savedProperty = await _adminApi.updateProperty(
          id: editingItem.property.id,
          title: property.title,
          type: property.type,
          offerType: property.offerType,
          price: property.price,
          location: property.location,
          description: property.description,
          imageUrl: _imageUrlController.text.trim(),
          ownerId: _ownerId,
          tenantId: _tenantId,
          status: _status,
        );
      }
      if (!mounted) return;
      notificationCenter.push(
        title: editingItem == null ? 'Bien publie' : 'Bien modifie',
        message: '${property.title} est synchronise avec PostgreSQL.',
        type: AppNotificationType.admin,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editingItem == null
                ? 'Bien publie en base PostgreSQL.'
                : 'Bien modifie en base PostgreSQL.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bien ajoute localement. API indisponible.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          final managed = _ManagedProperty(
            property: savedProperty,
            ownerId: _ownerId,
            tenantId: _tenantId,
          );
          final index = _properties.indexWhere(
            (item) => item.property.id == managed.property.id,
          );
          if (index == -1) {
            _properties.insert(0, managed);
          } else {
            _properties[index] = managed;
          }
          _titleController.clear();
          _locationController.clear();
          _priceController.clear();
          _imageUrlController.clear();
          _type = PropertyType.house;
          _offerType = PropertyOfferType.sale;
          _status = PropertyStatus.available;
          _ownerId = 'user_003';
          _tenantId = null;
          _editingItem = null;
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteProperty(_ManagedProperty item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le bien'),
        content: Text('Supprimer "${item.property.title}" du catalogue ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminApi.deleteResource('properties', item.property.id);
      if (!mounted) return;
      setState(() => _properties.remove(item));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bien supprime.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _pickPropertyImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final url = await _photoUploadService.pickAndUpload(
        fileName: _titleController.text.trim().isEmpty
            ? 'bien-${DateTime.now().millisecondsSinceEpoch}'
            : _titleController.text.trim(),
      );
      if (!mounted) return;
      if (url != null) {
        setState(() => _imageUrlController.text = url);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image du bien ajoutee.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload image impossible.')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _editProperty(_ManagedProperty item) {
    setState(() {
      _editingItem = item;
      _titleController.text = item.property.title;
      _locationController.text = item.property.location;
      _priceController.text = item.property.price.toString();
      _imageUrlController.text = item.property.imagePaths.first;
      _type = item.property.type;
      _offerType = item.property.offerType;
      _status = item.property.status;
      _ownerId = item.ownerId;
      _tenantId = item.tenantId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final owners = _users.where((user) => user.role == UserRole.owner).toList();
    final tenants = _users
        .where((user) => user.role == UserRole.tenant)
        .toList();
    final selectedOwnerId = owners.any((user) => user.id == _ownerId)
        ? _ownerId
        : null;
    final selectedTenantId = tenants.any((user) => user.id == _tenantId)
        ? _tenantId
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Biens et affectations')),
      body: PremiumPage(
        child: SafeArea(
          child: ListView(
            key: const Key('admin_property_crud_list'),
            padding: EdgeInsets.zero,
            children: [
              PremiumResponsiveContent(
                maxWidth: 980,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: _formKey,
                      child: PremiumPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingItem == null
                                  ? 'Publier un bien'
                                  : 'Modifier le bien',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Titre du bien',
                                prefixIcon: Icon(Icons.home_work_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().length < 4
                                  ? 'Titre requis'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Quartier / Ville',
                                prefixIcon: Icon(Icons.place_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().length < 2
                                  ? 'Localisation requise'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Prix FCFA',
                                prefixIcon: Icon(Icons.payments_rounded),
                              ),
                              validator: (value) {
                                final parsed = int.tryParse(
                                  value?.trim() ?? '',
                                );
                                return parsed == null || parsed <= 0
                                    ? 'Prix valide requis'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _imageUrlController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'URL image reelle',
                                prefixIcon: Icon(Icons.image_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _isUploadingImage
                                  ? null
                                  : _pickPropertyImage,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(
                                _isUploadingImage
                                    ? 'Upload image...'
                                    : 'Uploader une photo',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<PropertyType>(
                              initialValue: _type,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                prefixIcon: Icon(Icons.category_rounded),
                              ),
                              items: [
                                for (final type in PropertyType.values)
                                  DropdownMenuItem(
                                    value: type,
                                    child: Text(_typeLabel(type)),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _type = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<PropertyOfferType>(
                              initialValue: _offerType,
                              decoration: const InputDecoration(
                                labelText: 'Offre',
                                prefixIcon: Icon(Icons.sell_rounded),
                              ),
                              items: [
                                for (final offer in PropertyOfferType.values)
                                  DropdownMenuItem(
                                    value: offer,
                                    child: Text(_offerLabel(offer)),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _offerType = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<PropertyStatus>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Statut',
                                prefixIcon: Icon(Icons.verified_rounded),
                              ),
                              items: [
                                for (final status in PropertyStatus.values)
                                  DropdownMenuItem(
                                    value: status,
                                    child: Text(_statusLabel(status)),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _status = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              initialValue: selectedOwnerId,
                              decoration: const InputDecoration(
                                labelText: 'Proprietaire',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Non affecte'),
                                ),
                                for (final owner in owners)
                                  DropdownMenuItem(
                                    value: owner.id,
                                    child: Text(owner.fullName),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _ownerId = value),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              initialValue: selectedTenantId,
                              decoration: const InputDecoration(
                                labelText: 'Locataire',
                                prefixIcon: Icon(Icons.key_rounded),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Non affecte'),
                                ),
                                for (final tenant in tenants)
                                  DropdownMenuItem(
                                    value: tenant.id,
                                    child: Text(tenant.fullName),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _tenantId = value),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _isSaving ? null : _saveProperty,
                              icon: const Icon(Icons.publish_rounded),
                              label: Text(
                                _isSaving
                                    ? 'Enregistrement...'
                                    : _editingItem == null
                                    ? 'Publier'
                                    : 'Enregistrer',
                              ),
                            ),
                            if (_editingItem != null) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          _editingItem = null;
                                          _titleController.clear();
                                          _locationController.clear();
                                          _priceController.clear();
                                          _imageUrlController.clear();
                                        });
                                      },
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Annuler modification'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isLoading ? 'Chargement...' : 'Biens publies',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    for (final item in _properties)
                      _ManagedPropertyCard(
                        item: item,
                        onEdit: () => _editProperty(item),
                        onDelete: () => _deleteProperty(item),
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

class _ManagedPropertyCard extends StatelessWidget {
  const _ManagedPropertyCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final _ManagedProperty item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.home_work_rounded),
          ),
          title: Text(item.property.title),
          subtitle: Text(
            '${_offerLabel(item.property.offerType)} - ${item.property.location}',
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Modifier',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => 'Disponible',
    PropertyStatus.reserved => 'Reserve',
    PropertyStatus.rented => 'Loue',
    PropertyStatus.sold => 'Vendu',
  };
}

class _ManagedProperty {
  const _ManagedProperty({
    required this.property,
    required this.ownerId,
    required this.tenantId,
  });

  final Property property;
  final String? ownerId;
  final String? tenantId;
}

String _offerLabel(PropertyOfferType offer) {
  return switch (offer) {
    PropertyOfferType.rent => 'Location',
    PropertyOfferType.sale => 'Vente',
    PropertyOfferType.colocation => 'Colocation',
  };
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
