import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/app_notification.dart';
import '../models/issue_report.dart';
import '../models/property.dart';
import '../services/api_exception.dart';
import '../services/issue_api.dart';
import '../services/notification_center.dart';
import '../services/photo_upload_service.dart';
import '../theme/app_colors.dart';

class IssueReportScreen extends StatefulWidget {
  const IssueReportScreen({super.key, this.initialProperty});

  final Property? initialProperty;

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _issueApi = const IssueApi();
  final _photoUploadService = const PhotoUploadService();

  late Property _selectedProperty;
  IssueCategory _selectedCategory = IssueCategory.plumbing;
  IssuePriority _selectedPriority = IssuePriority.normal;
  String? _photoUrl;
  bool _isSubmitting = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.initialProperty ?? DemoData.properties.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _issueApi.create(
        propertyId: _selectedProperty.id,
        category: _selectedCategory,
        priority: _selectedPriority,
        description: _descriptionController.text.trim(),
        photoUrl: _photoUrl,
      );
      if (!mounted) return;
      _descriptionController.clear();
      _photoUrl = null;
      notificationCenter.push(
        title: 'Signalement envoye',
        message:
            '${_categoryLabel(_selectedCategory)} pour ${_selectedProperty.title}.',
        type: AppNotificationType.issue,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signalement enregistre : ${_categoryLabel(_selectedCategory)}.',
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
        SnackBar(
          content: Text(
            'Signalement local : ${_categoryLabel(_selectedCategory)} - ${_priorityLabel(_selectedPriority)}.',
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
      appBar: AppBar(title: const Text('Signaler un probleme')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('issue_report_form'),
            padding: const EdgeInsets.all(20),
            children: [
              const _IssueHeader(),
              const SizedBox(height: 16),
              DropdownButtonFormField<Property>(
                initialValue: _selectedProperty,
                decoration: const InputDecoration(
                  labelText: 'Logement concerne',
                  prefixIcon: Icon(Icons.home_repair_service_rounded),
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
                onChanged: (property) {
                  if (property != null) {
                    setState(() => _selectedProperty = property);
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<IssueCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Type de probleme',
                  prefixIcon: Icon(Icons.report_problem_rounded),
                ),
                items: [
                  for (final category in IssueCategory.values)
                    DropdownMenuItem<IssueCategory>(
                      value: category,
                      child: Text(_categoryLabel(category)),
                    ),
                ],
                onChanged: (category) {
                  if (category != null) {
                    setState(() => _selectedCategory = category);
                  }
                },
              ),
              const SizedBox(height: 14),
              _PrioritySelector(
                selectedPriority: _selectedPriority,
                onChanged: (priority) =>
                    setState(() => _selectedPriority = priority),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description du probleme',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 12) {
                    return 'Decrivez le probleme avec au moins 12 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _PhotoPickerCard(
                photoUrl: _photoUrl,
                isUploading: _isUploadingPhoto,
                onPick: _pickPhoto,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitIssue,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Envoi...' : 'Envoyer le signalement',
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Suivi agence',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final issue in DemoData.issueReports) ...[
                _ExistingIssueCard(issue: issue),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final url = await _photoUploadService.pickAndUpload(
        fileName: 'signalement-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      if (url != null) {
        setState(() => _photoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo ajoutee au signalement.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload photo impossible.')));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }
}

class _IssueHeader extends StatelessWidget {
  const _IssueHeader();

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
            'Assistance technique',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Declare un souci electricite, eau, plomberie, serrure ou entretien. L agence suit le traitement.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selectedPriority,
    required this.onChanged,
  });

  final IssuePriority selectedPriority;
  final ValueChanged<IssuePriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final priority in IssuePriority.values) ...[
          Expanded(
            child: ChoiceChip(
              label: Text(_priorityLabel(priority)),
              selected: selectedPriority == priority,
              onSelected: (_) => onChanged(priority),
              selectedColor: _priorityColor(priority).withValues(alpha: 0.14),
              labelStyle: TextStyle(
                color: selectedPriority == priority
                    ? _priorityColor(priority)
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (priority != IssuePriority.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({
    required this.photoUrl,
    required this.isUploading,
    required this.onPick,
  });

  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    photoUrl == null
                        ? 'Ajouter une photo du probleme depuis la galerie.'
                        : 'Photo jointe au signalement.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isUploading ? null : onPick,
                icon: const Icon(Icons.upload_rounded),
                label: Text(isUploading ? 'Upload...' : 'Photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExistingIssueCard extends StatelessWidget {
  const _ExistingIssueCard({required this.issue});

  final IssueReport issue;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(issue.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(
                  label: _categoryLabel(issue.category),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _Badge(label: _statusLabel(issue.status), color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              issue.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (issue.agencyComment != null) ...[
              const SizedBox(height: 10),
              Text(
                issue.agencyComment!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

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
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _categoryLabel(IssueCategory category) {
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

String _priorityLabel(IssuePriority priority) {
  return switch (priority) {
    IssuePriority.low => 'Faible',
    IssuePriority.normal => 'Normal',
    IssuePriority.urgent => 'Urgent',
  };
}

Color _priorityColor(IssuePriority priority) {
  return switch (priority) {
    IssuePriority.low => AppColors.textSecondary,
    IssuePriority.normal => AppColors.primary,
    IssuePriority.urgent => AppColors.danger,
  };
}

String _statusLabel(IssueStatus status) {
  return switch (status) {
    IssueStatus.newReport => 'Nouveau',
    IssueStatus.inProgress => 'En cours',
    IssueStatus.resolved => 'Resolu',
    IssueStatus.rejected => 'Rejete',
  };
}

Color _statusColor(IssueStatus status) {
  return switch (status) {
    IssueStatus.newReport => AppColors.warning,
    IssueStatus.inProgress => AppColors.primary,
    IssueStatus.resolved => AppColors.success,
    IssueStatus.rejected => AppColors.danger,
  };
}
