/// Bon de commande (réappro) et ses lignes.
class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    this.supplierId,
  });

  final String id;
  final String? supplierId;
  final String status;
  final DateTime createdAt;

  factory PurchaseOrder.fromRow(Map<String, Object?> row) => PurchaseOrder(
    id: row['id'] as String,
    supplierId: row['supplier_id'] as String?,
    status: row['status'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

class PurchaseOrderItem {
  const PurchaseOrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
  });

  final String id;
  final String productId;
  final int quantity;

  factory PurchaseOrderItem.fromRow(Map<String, Object?> row) =>
      PurchaseOrderItem(
        id: row['id'] as String,
        productId: row['product_id'] as String,
        quantity: (row['quantity'] as num).toInt(),
      );
}
