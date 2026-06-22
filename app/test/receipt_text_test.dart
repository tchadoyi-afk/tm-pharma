import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/invoicing/invoice_models.dart';
import 'package:tm_pharma/features/invoicing/receipt_text.dart';

void main() {
  group('buildReceiptLines', () {
    final invoice = InvoiceData(
      invoiceNumber: 'INV-000001',
      issuedAt: DateTime(2026, 6, 22),
      pharmacy: const PharmacyInfo(legalName: 'Pharmacie du Centre'),
      lines: const [
        InvoiceLine(productName: 'Paracétamol', quantity: 2, unitPrice: 500),
        InvoiceLine(productName: 'Amoxicilline', quantity: 1, unitPrice: 1200),
      ],
    );

    test('inclut le nom de la pharmacie et le numéro de facture', () {
      final lines = buildReceiptLines(invoice);
      expect(lines, contains('Pharmacie du Centre'));
      expect(lines, contains('Facture INV-000001'));
    });

    test('inclut une ligne par produit avec son sous-total', () {
      final lines = buildReceiptLines(invoice);
      expect(lines.any((l) => l.contains('Paracétamol') && l.contains('1000')), isTrue);
      expect(lines.any((l) => l.contains('Amoxicilline') && l.contains('1200')), isTrue);
    });

    test('inclut le total général', () {
      final lines = buildReceiptLines(invoice);
      expect(lines.last, contains('2200'));
    });
  });
}
