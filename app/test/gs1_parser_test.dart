import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/stock/gs1_parser.dart';

void main() {
  final gs = String.fromCharCode(29);

  group('parseGs1', () {
    test('parses GTIN + péremption + lot (AI 01/17/10 dans cet ordre)', () {
      final data = parseGs1('0106111000000017173104301012345$gs');
      expect(data.gtin, '06111000000017');
      expect(data.expirationDate, DateTime(2031, 4, 30));
      expect(data.lotNumber, '12345');
    });

    test('AI 17 décode AAMMJJ en date', () {
      final data = parseGs1('17240615');
      expect(data.expirationDate, DateTime(2024, 6, 15));
    });

    test('AI 10 (lot) en fin de chaîne sans séparateur', () {
      final data = parseGs1('10LOT42');
      expect(data.lotNumber, 'LOT42');
    });

    test('AI 10 (lot) suivi d\'un autre AI, séparé par FNC1', () {
      final data = parseGs1('10LOT42${gs}17240101');
      expect(data.lotNumber, 'LOT42');
      expect(data.expirationDate, DateTime(2024, 1, 1));
    });

    test('chaîne vide ou non reconnue → Gs1Data vide', () {
      expect(parseGs1('').isEmpty, isTrue);
      expect(parseGs1('xyz').isEmpty, isTrue);
    });
  });
}
