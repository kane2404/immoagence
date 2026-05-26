import 'package:flutter/material.dart';

import '../models/property.dart';
import '../models/receipt.dart';
import '../services/app_session.dart';
import '../services/document_export_service.dart';
import '../theme/app_colors.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({
    super.key,
    required this.property,
    required this.amount,
    required this.reference,
    required this.phone,
  });

  final Property property;
  final int amount;
  final String reference;
  final String phone;

  @override
  Widget build(BuildContext context) {
    const exportService = DocumentExportService();
    return Scaffold(
      appBar: AppBar(title: const Text('Recu de paiement')),
      body: SafeArea(
        child: ListView(
          key: const Key('receipt_screen'),
          padding: const EdgeInsets.all(20),
          children: [
            const _ReceiptHeader(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReceiptLine(label: 'Reference', value: reference),
                    _ReceiptLine(
                      label: 'Client',
                      value: appSession.user?.fullName ?? 'Client',
                    ),
                    _ReceiptLine(label: 'Telephone', value: phone),
                    _ReceiptLine(label: 'Bien', value: property.title),
                    _ReceiptLine(label: 'Quartier', value: property.location),
                    _ReceiptLine(label: 'Montant', value: '$amount FCFA'),
                    const _ReceiptLine(
                      label: 'Statut',
                      value: 'Paiement confirme',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _ReceiptNotice(),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                final receipt = Receipt(
                  id: 'local_receipt_$reference',
                  reference: reference,
                  paymentId: reference,
                  clientId: appSession.user?.id ?? 'visitor',
                  propertyId: property.id,
                  amount: amount,
                  issuedAt: DateTime.now(),
                  label: 'Recu de paiement PayDunya',
                );
                await exportService.exportReceipt(
                  receipt: receipt,
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
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recu numerique',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Document genere apres confirmation du paiement PayDunya.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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

class _ReceiptNotice extends StatelessWidget {
  const _ReceiptNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ce recu doit rester lie a une verification PayDunya cote backend avant validation definitive.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
