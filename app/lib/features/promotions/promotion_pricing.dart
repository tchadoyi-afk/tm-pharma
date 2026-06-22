import 'promotion_model.dart';

/// Applique la remise active (le cas échéant) au prix unitaire d'un produit.
/// Pure : aucune dépendance à l'heure système, `now` est fourni par l'appelant.
double applyActivePromotion({
  required double unitPrice,
  required List<Promotion> promotions,
  required String productId,
  required DateTime now,
}) {
  final active = promotions.where(
    (p) => p.productId == productId && p.isActiveAt(now),
  );
  if (active.isEmpty) return unitPrice;
  final best = active.reduce(
    (a, b) => a.discountPercent >= b.discountPercent ? a : b,
  );
  return unitPrice * (1 - best.discountPercent / 100);
}
