/// Produit du catalogue d'une pharmacie (tenant).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sellingPrice,
    this.barcode,
    this.dciName,
    this.unit = 'unité',
    this.category,
    this.referenceId,
    this.lowStockThreshold = 0,
    this.defaultSupplierId,
  });

  final String id;
  final String name;
  final String? dciName;
  final String? barcode;
  final String unit;
  final String? category;
  final String? referenceId;
  final double sellingPrice;
  final int lowStockThreshold;
  /// Fournisseur par défaut pour le réappro (réappro affiné).
  final String? defaultSupplierId;

  factory Product.fromRow(Map<String, Object?> row) => Product(
    id: row['id'] as String,
    name: row['name'] as String,
    dciName: row['dci_name'] as String?,
    barcode: row['barcode'] as String?,
    unit: (row['unit'] as String?) ?? 'unité',
    category: row['category'] as String?,
    referenceId: row['reference_id'] as String?,
    sellingPrice: (row['selling_price'] as num?)?.toDouble() ?? 0,
    lowStockThreshold: (row['low_stock_threshold'] as num?)?.toInt() ?? 0,
    defaultSupplierId: row['default_supplier_id'] as String?,
  );
}

/// Entrée du catalogue de référence DCI (partagé entre tenants).
class ReferenceProduct {
  const ReferenceProduct({
    required this.id,
    required this.dciName,
    required this.unit,
    this.barcode,
    this.category,
  });

  final String id;
  final String dciName;
  final String? barcode;
  final String unit;
  final String? category;

  factory ReferenceProduct.fromRow(Map<String, Object?> row) =>
      ReferenceProduct(
        id: row['id'] as String,
        dciName: row['dci_name'] as String,
        barcode: row['barcode'] as String?,
        unit: (row['unit'] as String?) ?? 'unité',
        category: row['category'] as String?,
      );
}

/// Normalise un code-barres saisi/scanné (espaces parasites retirés).
/// `null`/vide → `null` (pas de code associé).
String? normalizeBarcode(String? raw) {
  final trimmed = raw?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
