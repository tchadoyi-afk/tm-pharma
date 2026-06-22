import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/lifecycle/expiry_alerts.dart';
import 'package:tm_pharma/features/stock/stock_models.dart';

void main() {
  final today = DateTime(2026, 1, 1);

  group('expiryAlertLevel', () {
    test('aucune date -> none', () {
      expect(expiryAlertLevel(null, today), ExpiryAlertLevel.none);
    });

    test('au-delà de 90 jours -> none', () {
      expect(
        expiryAlertLevel(today.add(const Duration(days: 91)), today),
        ExpiryAlertLevel.none,
      );
    });

    test('exactement 90 jours -> j90', () {
      expect(
        expiryAlertLevel(today.add(const Duration(days: 90)), today),
        ExpiryAlertLevel.j90,
      );
    });

    test('exactement 30 jours -> j30', () {
      expect(
        expiryAlertLevel(today.add(const Duration(days: 30)), today),
        ExpiryAlertLevel.j30,
      );
    });

    test('exactement 7 jours -> j7', () {
      expect(
        expiryAlertLevel(today.add(const Duration(days: 7)), today),
        ExpiryAlertLevel.j7,
      );
    });

    test('aujourd\'hui (0 jour) -> j7', () {
      expect(expiryAlertLevel(today, today), ExpiryAlertLevel.j7);
    });

    test('1 jour dans le passé -> expired', () {
      expect(
        expiryAlertLevel(today.subtract(const Duration(days: 1)), today),
        ExpiryAlertLevel.expired,
      );
    });
  });

  group('lotsWithActiveAlerts', () {
    test('filtre et trie par date de péremption croissante', () {
      final lots = [
        _lot('a', today.add(const Duration(days: 200))),
        _lot('b', today.add(const Duration(days: 5))),
        _lot('c', today.add(const Duration(days: 60))),
        _lot('d', null),
      ];
      final result = lotsWithActiveAlerts(lots, today);
      expect(result.map((l) => l.id), ['b', 'c']);
    });
  });
}

Lot _lot(String id, DateTime? expirationDate) => Lot(
  id: id,
  productId: 'p1',
  quantity: 1,
  expirationDate: expirationDate,
);
