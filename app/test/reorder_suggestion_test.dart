import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/reorder/reorder_suggestion.dart';

void main() {
  group('computeReorderSuggestions', () {
    test('ignore les produits sans seuil défini', () {
      final lines = [
        const ReorderStockLine(
          productId: 'p1',
          productName: 'Paracétamol',
          quantity: 0,
          lowStockThreshold: 0,
        ),
      ];
      expect(computeReorderSuggestions(lines), isEmpty);
    });

    test('ignore les produits au-dessus du seuil', () {
      final lines = [
        const ReorderStockLine(
          productId: 'p1',
          productName: 'Paracétamol',
          quantity: 20,
          lowStockThreshold: 10,
        ),
      ];
      expect(computeReorderSuggestions(lines), isEmpty);
    });

    test('suggère une quantité ramenant à 2x le seuil', () {
      final lines = [
        const ReorderStockLine(
          productId: 'p1',
          productName: 'Paracétamol',
          quantity: 5,
          lowStockThreshold: 10,
        ),
      ];
      final result = computeReorderSuggestions(lines);
      expect(result, hasLength(1));
      expect(result.first.suggestedQuantity, 15);
    });

    test('stock à zéro -> quantité suggérée = 2x le seuil', () {
      final lines = [
        const ReorderStockLine(
          productId: 'p1',
          productName: 'Paracétamol',
          quantity: 0,
          lowStockThreshold: 10,
        ),
      ];
      final result = computeReorderSuggestions(lines);
      expect(result.first.suggestedQuantity, 20);
    });

    test('exactement au seuil -> suggestion incluse avec quantité minimale de 1', () {
      final lines = [
        const ReorderStockLine(
          productId: 'p1',
          productName: 'Paracétamol',
          quantity: 10,
          lowStockThreshold: 10,
        ),
      ];
      final result = computeReorderSuggestions(lines);
      expect(result, hasLength(1));
      expect(result.first.suggestedQuantity, 10);
    });

    test(
      'vélocité × délai fournisseur avance le déclenchement au-delà du seuil bas',
      () {
        // Seuil bas = 10, mais vélocité 5/jour × délai 5j = 25 > seuil :
        // le point de commande réel est 25, donc déclenché même à 20 en stock.
        final lines = [
          const ReorderStockLine(
            productId: 'p1',
            productName: 'Paracétamol',
            quantity: 20,
            lowStockThreshold: 10,
            dailyVelocity: 5,
            leadTimeDays: 5,
          ),
        ];
        final result = computeReorderSuggestions(lines);
        expect(result, hasLength(1));
      },
    );

    test(
      'avec vélocité connue, la quantité suggérée couvre délai + marge de sécurité',
      () {
        // vélocité 4/jour, délai 3j, marge sécurité 14j -> cible = 4*(3+14)=68.
        final lines = [
          const ReorderStockLine(
            productId: 'p1',
            productName: 'Paracétamol',
            quantity: 5,
            lowStockThreshold: 10,
            dailyVelocity: 4,
            leadTimeDays: 3,
          ),
        ];
        final result = computeReorderSuggestions(lines);
        expect(result.first.suggestedQuantity, 63);
      },
    );

    test('sans vélocité (produit jamais vendu), retombe sur 2x le seuil', () {
      final lines = [
        const ReorderStockLine(
          productId: 'p1',
          productName: 'Paracétamol',
          quantity: 5,
          lowStockThreshold: 10,
          leadTimeDays: 7,
        ),
      ];
      final result = computeReorderSuggestions(lines);
      expect(result.first.suggestedQuantity, 15);
    });

    test('reporte le fournisseur par défaut du produit sur la suggestion', () {
      final lines = [
        const ReorderStockLine(
          productId: 'p1',
          productName: 'Paracétamol',
          quantity: 5,
          lowStockThreshold: 10,
          supplierId: 's1',
          supplierName: 'Grossiste A',
        ),
      ];
      final result = computeReorderSuggestions(lines);
      expect(result.first.supplierId, 's1');
      expect(result.first.supplierName, 'Grossiste A');
    });
  });
}
