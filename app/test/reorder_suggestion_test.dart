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
  });
}
