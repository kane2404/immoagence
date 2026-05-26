import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/property.dart';
import '../models/app_notification.dart';
import '../services/api_exception.dart';
import '../services/app_session.dart';
import '../services/notification_center.dart';
import '../services/visit_api.dart';
import '../theme/app_colors.dart';

class VisitScheduleScreen extends StatefulWidget {
  const VisitScheduleScreen({super.key, this.initialProperty});

  final Property? initialProperty;

  @override
  State<VisitScheduleScreen> createState() => _VisitScheduleScreenState();
}

class _VisitScheduleScreenState extends State<VisitScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _messageController = TextEditingController();
  final _visitApi = const VisitApi();

  late Property _selectedProperty;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = appSession.user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedProperty = widget.initialProperty ?? DemoData.properties.first;
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitVisit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    setState(() => _isSubmitting = true);
    try {
      await _visitApi.create(
        propertyId: _selectedProperty.id,
        scheduledAt: scheduledAt,
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      notificationCenter.push(
        title: 'Visite demandee',
        message:
            'Votre demande pour ${_selectedProperty.title} est en attente.',
        type: AppNotificationType.visit,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visite enregistree pour ${_selectedProperty.title}.'),
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
        SnackBar(
          content: Text(
            'Visite demandee localement pour ${_selectedProperty.title} le ${_formatDate(_selectedDate)} a ${_selectedTime.format(context)}.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programmer une visite')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('visit_form'),
            padding: const EdgeInsets.all(20),
            children: [
              const _VisitHeader(),
              const SizedBox(height: 16),
              _PropertySelector(
                selectedProperty: _selectedProperty,
                onChanged: (property) {
                  if (property != null) {
                    setState(() => _selectedProperty = property);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Entrez un nom valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telephone',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 9) {
                    return 'Entrez un telephone valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PickerCard(
                      icon: Icons.event_rounded,
                      label: 'Date',
                      value: _formatDate(_selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerCard(
                      icon: Icons.schedule_rounded,
                      label: 'Heure',
                      value: _selectedTime.format(context),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message optionnel',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.message_rounded),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitVisit,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSubmitting ? 'Envoi...' : 'Confirmer la demande',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'L agence confirmera la disponibilite du creneau avant la visite.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitHeader extends StatelessWidget {
  const _VisitHeader();

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
            'Choisissez votre creneau',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Selectionnez un bien, une date et une heure. Un agent validera la demande.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertySelector extends StatelessWidget {
  const _PropertySelector({
    required this.selectedProperty,
    required this.onChanged,
  });

  final Property selectedProperty;
  final ValueChanged<Property?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Property>(
      initialValue: selectedProperty,
      decoration: const InputDecoration(
        labelText: 'Bien concerne',
        prefixIcon: Icon(Icons.home_work_rounded),
      ),
      items: [
        for (final property in DemoData.properties)
          DropdownMenuItem<Property>(
            value: property,
            child: Text(
              property.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
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
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
