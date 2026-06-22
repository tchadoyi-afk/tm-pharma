import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/fraud/fraud_signals.dart';

void main() {
  group('detectFraudSignals', () {
    test('liste vide -> aucun signal', () {
      expect(detectFraudSignals(const []), isEmpty);
    });

    test('aucune anomalie -> aucun signal', () {
      final sales = [
        FraudSaleSample(totalAmount: 1000, soldAt: DateTime(2026, 1, 1, 10)),
        FraudSaleSample(totalAmount: 1200, soldAt: DateTime(2026, 1, 1, 11)),
        FraudSaleSample(totalAmount: 900, soldAt: DateTime(2026, 1, 1, 12)),
      ];
      expect(detectFraudSignals(sales), isEmpty);
    });

    test('remises répétées juste sous le seuil -> signal', () {
      final sales = List.generate(
        3,
        (i) => FraudSaleSample(
          totalAmount: 1000,
          soldAt: DateTime(2026, 1, 1, 10 + i),
          discountPercent: 9.5,
        ),
      );
      final signals = detectFraudSignals(sales, approvalThresholdPercent: 10);
      expect(
        signals.any((s) => s.type == FraudSignalType.discountJustUnderThreshold),
        isTrue,
      );
    });

    test('vente hors plage horaire -> signal', () {
      final sales = [
        FraudSaleSample(totalAmount: 1000, soldAt: DateTime(2026, 1, 1, 3)),
      ];
      final signals = detectFraudSignals(
        sales,
        openingHour: 7,
        closingHour: 21,
      );
      expect(
        signals.any((s) => s.type == FraudSignalType.offHours),
        isTrue,
      );
    });

    test('montant largement supérieur à la moyenne -> signal', () {
      final sales = [
        FraudSaleSample(totalAmount: 1000, soldAt: DateTime(2026, 1, 1, 10)),
        FraudSaleSample(totalAmount: 1100, soldAt: DateTime(2026, 1, 1, 11)),
        FraudSaleSample(totalAmount: 900, soldAt: DateTime(2026, 1, 1, 12)),
        FraudSaleSample(totalAmount: 1050, soldAt: DateTime(2026, 1, 1, 13)),
        FraudSaleSample(totalAmount: 200000, soldAt: DateTime(2026, 1, 1, 14)),
      ];
      final signals = detectFraudSignals(sales);
      expect(
        signals.any((s) => s.type == FraudSignalType.amountOutlier),
        isTrue,
      );
    });
  });
}
