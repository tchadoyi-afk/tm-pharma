import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/catalog/product_model.dart';

void main() {
  group('normalizeBarcode', () {
    test('trims whitespace', () {
      expect(normalizeBarcode('  6111000000017  '), '6111000000017');
    });

    test('null stays null', () {
      expect(normalizeBarcode(null), isNull);
    });

    test('empty/blank becomes null', () {
      expect(normalizeBarcode(''), isNull);
      expect(normalizeBarcode('   '), isNull);
    });
  });

  group('Product.fromRow', () {
    test('parses a full row', () {
      final p = Product.fromRow({
        'id': 'p1',
        'name': 'Paracétamol',
        'dci_name': 'Paracétamol 500mg',
        'barcode': '6111000000017',
        'unit': 'boîte',
        'category': 'Antalgique',
        'reference_id': 'r1',
        'selling_price': 500,
      });
      expect(p.id, 'p1');
      expect(p.name, 'Paracétamol');
      expect(p.sellingPrice, 500.0);
    });

    test('defaults missing optional fields', () {
      final p = Product.fromRow({
        'id': 'p1',
        'name': 'Produit X',
        'selling_price': null,
      });
      expect(p.unit, 'unité');
      expect(p.sellingPrice, 0);
      expect(p.barcode, isNull);
    });
  });
}
