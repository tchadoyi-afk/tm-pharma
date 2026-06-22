import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/pos/fefo.dart';
import 'package:tm_pharma/features/stock/stock_models.dart';

void main() {
  group('pickFefoLot', () {
    test('choisit le lot qui périme le plus tôt parmi ceux suffisants', () {
      final lots = [
        Lot(
          id: 'late',
          productId: 'p1',
          quantity: 10,
          expirationDate: DateTime(2030, 1, 1),
        ),
        Lot(
          id: 'early',
          productId: 'p1',
          quantity: 10,
          expirationDate: DateTime(2025, 1, 1),
        ),
      ];
      expect(pickFefoLot(lots, 5)?.id, 'early');
    });

    test('ignore les lots dont la quantité est insuffisante', () {
      final lots = [
        Lot(
          id: 'insuffisant',
          productId: 'p1',
          quantity: 2,
          expirationDate: DateTime(2025, 1, 1),
        ),
        Lot(
          id: 'suffisant',
          productId: 'p1',
          quantity: 10,
          expirationDate: DateTime(2026, 1, 1),
        ),
      ];
      expect(pickFefoLot(lots, 5)?.id, 'suffisant');
    });

    test('lots sans date de péremption priorisés en dernier', () {
      final lots = [
        const Lot(id: 'sans_date', productId: 'p1', quantity: 10),
        Lot(
          id: 'avec_date',
          productId: 'p1',
          quantity: 10,
          expirationDate: DateTime(2030, 1, 1),
        ),
      ];
      expect(pickFefoLot(lots, 5)?.id, 'avec_date');
    });

    test('aucun lot suffisant → null', () {
      final lots = [
        const Lot(id: 'l1', productId: 'p1', quantity: 1),
      ];
      expect(pickFefoLot(lots, 5), isNull);
    });
  });

  group('pickFefoAllocation', () {
    test('un seul lot suffit -> une seule entrée', () {
      final lots = [
        Lot(
          id: 'l1',
          productId: 'p1',
          quantity: 10,
          expirationDate: DateTime(2026, 1, 1),
        ),
      ];
      final allocation = pickFefoAllocation(lots, 5);
      expect(allocation, hasLength(1));
      expect(allocation!.first.lot.id, 'l1');
      expect(allocation.first.quantity, 5);
    });

    test('répartit sur plusieurs lots du plus proche au plus lointain', () {
      final lots = [
        Lot(
          id: 'late',
          productId: 'p1',
          quantity: 10,
          expirationDate: DateTime(2030, 1, 1),
        ),
        Lot(
          id: 'early',
          productId: 'p1',
          quantity: 3,
          expirationDate: DateTime(2025, 1, 1),
        ),
      ];
      final allocation = pickFefoAllocation(lots, 7);
      expect(allocation, hasLength(2));
      expect(allocation![0].lot.id, 'early');
      expect(allocation[0].quantity, 3);
      expect(allocation[1].lot.id, 'late');
      expect(allocation[1].quantity, 4);
    });

    test('stock total insuffisant -> null', () {
      final lots = [
        const Lot(id: 'l1', productId: 'p1', quantity: 2),
        const Lot(id: 'l2', productId: 'p1', quantity: 1),
      ];
      expect(pickFefoAllocation(lots, 5), isNull);
    });

    test('quantité nulle ou négative -> null', () {
      final lots = [const Lot(id: 'l1', productId: 'p1', quantity: 10)];
      expect(pickFefoAllocation(lots, 0), isNull);
      expect(pickFefoAllocation(lots, -1), isNull);
    });
  });
}
