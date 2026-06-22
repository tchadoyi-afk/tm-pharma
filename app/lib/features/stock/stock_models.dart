/// Lot d'un produit (péremption + quantité courante).
class Lot {
  const Lot({
    required this.id,
    required this.productId,
    required this.quantity,
    this.lotNumber,
    this.expirationDate,
  });

  final String id;
  final String productId;
  final String? lotNumber;
  final DateTime? expirationDate;
  final int quantity;

  factory Lot.fromRow(Map<String, Object?> row) => Lot(
    id: row['id'] as String,
    productId: row['product_id'] as String,
    lotNumber: row['lot_number'] as String?,
    expirationDate: _parseDate(row['expiration_date'] as String?),
    quantity: (row['quantity'] as num?)?.toInt() ?? 0,
  );
}

/// Fournisseur (par tenant), utilisé à la réception de commande.
class Supplier {
  const Supplier({required this.id, required this.name, this.phone, this.email});

  final String id;
  final String name;
  final String? phone;
  final String? email;

  factory Supplier.fromRow(Map<String, Object?> row) => Supplier(
    id: row['id'] as String,
    name: row['name'] as String,
    phone: row['phone'] as String?,
    email: row['email'] as String?,
  );
}

/// Vue agrégée stock+produit pour l'écran de suivi (jointure produit/lots).
class StockLine {
  const StockLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.lowStockThreshold,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int lowStockThreshold;

  bool get isLow => quantity <= lowStockThreshold;

  factory StockLine.fromRow(Map<String, Object?> row) => StockLine(
    productId: row['product_id'] as String,
    productName: row['name'] as String,
    quantity: (row['total_quantity'] as num?)?.toInt() ?? 0,
    lowStockThreshold: (row['low_stock_threshold'] as num?)?.toInt() ?? 0,
  );
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
