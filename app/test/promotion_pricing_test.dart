import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/promotions/promotion_model.dart';
import 'package:tm_pharma/features/promotions/promotion_pricing.dart';

void main() {
  final now = DateTime(2026, 6, 15);

  Promotion promo({
    required String productId,
    required double discountPercent,
    required int startOffsetDays,
    required int endOffsetDays,
  }) {
    return Promotion(
      id: 'promo-$productId-$discountPercent',
      productId: productId,
      discountPercent: discountPercent,
      startsAt: now.add(Duration(days: startOffsetDays)),
      endsAt: now.add(Duration(days: endOffsetDays)),
    );
  }

  group('applyActivePromotion', () {
    test('aucune promotion -> prix inchangé', () {
      final price = applyActivePromotion(
        unitPrice: 1000,
        promotions: const [],
        productId: 'p1',
        now: now,
      );
      expect(price, 1000);
    });

    test('promotion active sur un autre produit -> prix inchangé', () {
      final promotions = [
        promo(productId: 'other', discountPercent: 20, startOffsetDays: -1, endOffsetDays: 1),
      ];
      final price = applyActivePromotion(
        unitPrice: 1000,
        promotions: promotions,
        productId: 'p1',
        now: now,
      );
      expect(price, 1000);
    });

    test('promotion active simple -> applique la remise', () {
      final promotions = [
        promo(productId: 'p1', discountPercent: 20, startOffsetDays: -1, endOffsetDays: 1),
      ];
      final price = applyActivePromotion(
        unitPrice: 1000,
        promotions: promotions,
        productId: 'p1',
        now: now,
      );
      expect(price, 800);
    });

    test('plusieurs promotions actives -> applique la plus forte remise', () {
      final promotions = [
        promo(productId: 'p1', discountPercent: 10, startOffsetDays: -1, endOffsetDays: 1),
        promo(productId: 'p1', discountPercent: 30, startOffsetDays: -2, endOffsetDays: 2),
      ];
      final price = applyActivePromotion(
        unitPrice: 1000,
        promotions: promotions,
        productId: 'p1',
        now: now,
      );
      expect(price, 700);
    });

    test('promotion pas encore commencée -> ignorée', () {
      final promotions = [
        promo(productId: 'p1', discountPercent: 50, startOffsetDays: 1, endOffsetDays: 5),
      ];
      final price = applyActivePromotion(
        unitPrice: 1000,
        promotions: promotions,
        productId: 'p1',
        now: now,
      );
      expect(price, 1000);
    });

    test('promotion déjà expirée -> ignorée', () {
      final promotions = [
        promo(productId: 'p1', discountPercent: 50, startOffsetDays: -10, endOffsetDays: -1),
      ];
      final price = applyActivePromotion(
        unitPrice: 1000,
        promotions: promotions,
        productId: 'p1',
        now: now,
      );
      expect(price, 1000);
    });
  });
}
