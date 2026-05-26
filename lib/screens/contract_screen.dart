import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/contract.dart';
import '../models/property.dart';
import '../services/api_exception.dart';
import '../services/app_session.dart';
import '../services/contract_api.dart';
import '../services/document_export_service.dart';
import '../services/notification_center.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_surfaces.dart';

class ContractScreen extends StatelessWidget {
  const ContractScreen({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final contractType = _contractTypeLabel(property);
    final reference = 'CTR-${property.id.toUpperCase()}';
    final exportService = const DocumentExportService();
    final contractApi = const ContractApi();

    return Scaffold(
      appBar: AppBar(title: const Text('Contrat')),
      body: PremiumPage(
        child: SafeArea(
          child: ListView(
            key: const Key('contract_screen'),
            padding: const EdgeInsets.all(20),
            children: [
              _ContractHeader(contractType: contractType, reference: reference),
              const SizedBox(height: 16),
              _ContractSummary(property: property),
              const SizedBox(height: 16),
              _TermsPanel(property: property),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    final contractReference = await contractApi.request(
                      propertyId: property.id,
                      type: _contractType(property),
                      amount: property.price,
                      terms: _contractTerms(property),
                    );
                    if (!context.mounted) return;
                    notificationCenter.push(
                      title: 'Contrat prepare',
                      message:
                          'Reference $contractReference pour ${property.title}.',
                      type: AppNotificationType.contract,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Contrat prepare en base : $contractReference',
                        ),
                      ),
                    );
                  } on ApiException catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contrat prepare localement.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_document),
                label: const Text('Preparer la signature'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final contract = Contract(
                    id: 'local_contract_${property.id}',
                    reference: reference,
                    type: _contractType(property),
                    status: ContractStatus.draft,
                    propertyId: property.id,
                    clientId: appSession.user?.id ?? 'visitor',
                    startDate: DateTime.now(),
                    amount: property.price,
                    terms: _contractTerms(property),
                  );
                  await exportService.exportContract(
                    contract: contract,
                    propertyTitle: property.title,
                    clientName: appSession.user?.fullName ?? 'Client',
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Exporter en PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractHeader extends StatelessWidget {
  const _ContractHeader({required this.contractType, required this.reference});

  final String contractType;
  final String reference;

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
            contractType,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reference,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractSummary extends StatelessWidget {
  const _ContractSummary({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return PremiumFormSection(
      title: 'Bien concerne',
      icon: Icons.home_work_rounded,
      children: [
        const SizedBox(height: 12),
        _SummaryLine(label: 'Titre', value: property.title),
        _SummaryLine(label: 'Quartier', value: property.location),
        _SummaryLine(label: 'Montant', value: property.formattedPrice),
        _SummaryLine(
          label: 'Statut',
          value: property.isAvailable ? 'Disponible' : 'Reserve',
        ),
      ],
    );
  }
}

class _TermsPanel extends StatelessWidget {
  const _TermsPanel({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final terms = _contractTerms(property);

    return PremiumFormSection(
      title: 'Conditions principales',
      icon: Icons.rule_rounded,
      children: [
        for (final term in terms) ...[
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
                  term,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

String _contractTypeLabel(Property property) {
  return switch (property.offerType) {
    PropertyOfferType.rent => 'Contrat de location',
    PropertyOfferType.sale =>
      property.type == PropertyType.land
          ? 'Contrat de vente terrain'
          : 'Contrat de vente maison',
    PropertyOfferType.colocation => 'Contrat de colocation',
  };
}

List<String> _contractTerms(Property property) {
  return switch (property.offerType) {
    PropertyOfferType.rent => [
      'Paiement du loyer selon les dates convenues.',
      'Caution et etat des lieux avant remise des cles.',
      'Signalement obligatoire des problemes techniques.',
    ],
    PropertyOfferType.sale => [
      'Verification des documents avant signature definitive.',
      'Reservation validee uniquement apres paiement confirme.',
      'Signature accompagnee par l agence et les parties concernees.',
    ],
    PropertyOfferType.colocation => [
      'Respect des espaces communs et des autres colocataires.',
      'Charges precisees avant entree dans le logement.',
      'Depart ou remplacement valide par l agence.',
    ],
  };
}

ContractType _contractType(Property property) {
  return switch (property.offerType) {
    PropertyOfferType.rent => ContractType.rental,
    PropertyOfferType.sale =>
      property.type == PropertyType.land
          ? ContractType.landSale
          : ContractType.houseSale,
    PropertyOfferType.colocation => ContractType.colocation,
  };
}
