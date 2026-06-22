import 'invoice_models.dart';

/// Construit le contenu textuel d'un ticket/facture (lignes brutes), avant
/// mise en forme ESC/POS ou PDF. Pure et testable : aucune dépendance
/// d'impression ni de plateforme.
List<String> buildReceiptLines(InvoiceData invoice) {
  final lines = <String>[
    invoice.pharmacy.legalName,
    if (invoice.pharmacy.address != null) invoice.pharmacy.address!,
    if (invoice.pharmacy.phone != null) invoice.pharmacy.phone!,
    'Facture ${invoice.invoiceNumber}',
    invoice.issuedAt.toIso8601String(),
    '----------------------------------------',
  ];
  for (final line in invoice.lines) {
    lines.add(
      '${line.productName}  x${line.quantity}  '
      '${line.subtotal.toStringAsFixed(0)} ${invoice.pharmacy.currency}',
    );
  }
  lines
    ..add('----------------------------------------')
    ..add(
      'TOTAL: ${invoice.total.toStringAsFixed(0)} ${invoice.pharmacy.currency}',
    );
  return lines;
}
