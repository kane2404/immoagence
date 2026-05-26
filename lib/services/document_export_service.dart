import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contract.dart';
import '../models/receipt.dart';

class DocumentExportService {
  const DocumentExportService();

  Future<void> exportContract({
    required Contract contract,
    required String propertyTitle,
    required String clientName,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _page(
          title: 'Contrat ${_contractTypeLabel(contract.type)}',
          reference: contract.reference,
          rows: [
            ('Client', clientName),
            ('Bien', propertyTitle),
            ('Montant', '${contract.amount} FCFA'),
            ('Statut', _contractStatusLabel(contract.status)),
            ('Date debut', _formatDate(contract.startDate)),
            if (contract.endDate != null)
              ('Date fin', _formatDate(contract.endDate!)),
          ],
          terms: contract.terms,
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: '${contract.reference}.pdf',
    );
  }

  Future<void> exportReceipt({
    required Receipt receipt,
    required String propertyTitle,
    required String clientName,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _page(
          title: 'Recu numerique',
          reference: receipt.reference,
          rows: [
            ('Client', clientName),
            ('Bien', propertyTitle),
            ('Libelle', receipt.label),
            ('Montant', '${receipt.amount} FCFA'),
            ('Date', _formatDate(receipt.issuedAt)),
          ],
          terms: const [
            'Document genere par ImmoAgence Senegal.',
            'La validation definitive reste confirmee par l agence.',
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: '${receipt.reference}.pdf',
    );
  }

  pw.Widget _page({
    required String title,
    required String reference,
    required List<(String, String)> rows,
    required List<String> terms,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(28),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.amber800, width: 1.4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IMMOAGENCE SENEGAL',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber800,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Reference : $reference'),
          pw.Divider(height: 28, color: PdfColors.amber800),
          for (final row in rows) ...[
            pw.Text(
              row.$1,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(row.$2, style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
            'Conditions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          for (final term in terms)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text('- $term'),
            ),
          pw.Spacer(),
          pw.Text(
            'Document confidentiel - ImmoAgence Senegal',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _contractTypeLabel(ContractType type) {
  return switch (type) {
    ContractType.rental => 'de location',
    ContractType.colocation => 'de colocation',
    ContractType.landSale => 'de vente terrain',
    ContractType.houseSale => 'de vente maison',
  };
}

String _contractStatusLabel(ContractStatus status) {
  return switch (status) {
    ContractStatus.draft => 'Brouillon',
    ContractStatus.pendingSignature => 'Signature en attente',
    ContractStatus.signed => 'Signe',
    ContractStatus.cancelled => 'Annule',
  };
}
