/// Remise temporaire (%) sur un produit, valable sur une période.
class Promotion {
  const Promotion({
    required this.id,
    required this.productId,
    required this.discountPercent,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String productId;
  final double discountPercent;
  final DateTime startsAt;
  final DateTime endsAt;

  bool isActiveAt(DateTime now) =>
      !now.isBefore(startsAt) && !now.isAfter(endsAt);

  factory Promotion.fromRow(Map<String, Object?> row) => Promotion(
    id: row['id'] as String,
    productId: row['product_id'] as String,
    discountPercent: (row['discount_percent'] as num).toDouble(),
    startsAt: DateTime.parse(row['starts_at'] as String),
    endsAt: DateTime.parse(row['ends_at'] as String),
  );
}
