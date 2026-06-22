import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/invoicing/invoice_numbering.dart';

void main() {
  group('formatInvoiceNumber', () {
    test('pad le compteur sur 6 chiffres', () {
      expect(formatInvoiceNumber(prefix: 'INV', number: 1), 'INV-000001');
    });

    test('respecte le préfixe fourni', () {
      expect(formatInvoiceNumber(prefix: 'PHX', number: 42), 'PHX-000042');
    });

    test('ne tronque pas un compteur dépassant 6 chiffres', () {
      expect(
        formatInvoiceNumber(prefix: 'INV', number: 1234567),
        'INV-1234567',
      );
    });
  });
}
