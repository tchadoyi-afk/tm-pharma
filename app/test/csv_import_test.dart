import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/onboarding/csv_import.dart';

void main() {
  group('parseCsv', () {
    test('découpe lignes et colonnes simples', () {
      final rows = parseCsv('a,b,c\n1,2,3');
      expect(rows, [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('gère les champs cités contenant des virgules', () {
      final rows = parseCsv('nom,prix\n"Sirop, 100ml",1500');
      expect(rows[1], ['Sirop, 100ml', '1500']);
    });

    test('chaîne vide → aucune ligne', () {
      expect(parseCsv(''), isEmpty);
    });
  });

  group('parseProductCsv', () {
    const csv =
        'nom,code_barres,prix,dci,categorie\n'
        'Paracétamol,6111000000017,500,Paracétamol 500mg,Antalgique\n'
        'Sans prix,123,abc,,\n'
        ',456,100,,\n'
        'Ibuprofène,6111000000024,750,,';

    test('ignore les lignes sans nom ou prix invalide', () {
      final rows = parseProductCsv(csv);
      expect(rows.length, 2);
      expect(rows[0].name, 'Paracétamol');
      expect(rows[0].sellingPrice, 500);
      expect(rows[0].dciName, 'Paracétamol 500mg');
      expect(rows[1].name, 'Ibuprofène');
    });

    test('en-tête sans colonne nom/prix → liste vide', () {
      expect(parseProductCsv('a,b\n1,2'), isEmpty);
    });
  });

  group('markDuplicates', () {
    test('signale les codes-barres déjà existants', () {
      final rows = [
        const ImportedProductRow(name: 'A', sellingPrice: 1, barcode: '111'),
        const ImportedProductRow(name: 'B', sellingPrice: 1, barcode: '222'),
      ];
      final result = markDuplicates(rows, {'111'});
      expect(result[0].isDuplicate, isTrue);
      expect(result[1].isDuplicate, isFalse);
    });

    test('signale les doublons internes au fichier importé', () {
      final rows = [
        const ImportedProductRow(name: 'A', sellingPrice: 1, barcode: '111'),
        const ImportedProductRow(name: 'A bis', sellingPrice: 1, barcode: '111'),
      ];
      final result = markDuplicates(rows, {});
      expect(result[0].isDuplicate, isFalse);
      expect(result[1].isDuplicate, isTrue);
    });

    test('lignes sans code-barres jamais marquées doublon', () {
      final rows = [
        const ImportedProductRow(name: 'A', sellingPrice: 1),
        const ImportedProductRow(name: 'A bis', sellingPrice: 1),
      ];
      expect(markDuplicates(rows, {}).every((r) => !r.isDuplicate), isTrue);
    });
  });
}
