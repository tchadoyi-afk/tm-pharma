import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';
import 'purchase_order_model.dart';
import 'purchase_order_status.dart';
import 'reorder_suggestion.dart';

/// Bons de commande (réappro) via la base locale PowerSync (offline-first).
class PurchaseOrderRepository {
  PurchaseOrderRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

  Stream<List<PurchaseOrder>> watchPurchaseOrders() => _db
      .watch(
        'SELECT * FROM purchase_orders WHERE deleted_at IS NULL '
        'ORDER BY created_at DESC',
      )
      .map((rs) => rs.map(PurchaseOrder.fromRow).toList());

  Stream<List<PurchaseOrderItem>> watchItems(String purchaseOrderId) => _db
      .watch(
        'SELECT * FROM purchase_order_items '
        'WHERE purchase_order_id = ? AND deleted_at IS NULL',
        parameters: [purchaseOrderId],
      )
      .map((rs) => rs.map(PurchaseOrderItem.fromRow).toList());

  /// Crée un bon de commande à partir des suggestions de réappro
  /// sélectionnées par l'utilisateur.
  Future<String> createFromSuggestions({
    required String tenantId,
    required List<ReorderSuggestion> suggestions,
    String? supplierId,
    String? createdBy,
  }) async {
    final orderId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'INSERT INTO purchase_orders '
      '(id, tenant_id, supplier_id, status, created_by, created_at, updated_at) '
      "VALUES (?, ?, ?, 'DRAFT', ?, ?, ?)",
      [orderId, tenantId, supplierId, createdBy, now, now],
    );
    for (final s in suggestions) {
      await _db.execute(
        'INSERT INTO purchase_order_items '
        '(id, tenant_id, purchase_order_id, product_id, quantity, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          _uuid.v4(),
          tenantId,
          orderId,
          s.productId,
          s.suggestedQuantity,
          now,
          now,
        ],
      );
    }
    return orderId;
  }

  /// Envoi de la commande au fournisseur — toujours une action humaine
  /// explicite (validation manuelle obligatoire, invariant tous paliers) :
  /// aucun appelant de ce dépôt ne déclenche `markSent` automatiquement.
  Future<void> markSent(String purchaseOrderId) =>
      _setStatus(purchaseOrderId, 'SENT');

  /// Portail fournisseurs : le fournisseur a accusé réception de la commande
  /// (avant livraison physique des produits).
  Future<void> markConfirmed(String purchaseOrderId) =>
      _setStatus(purchaseOrderId, 'CONFIRMED');

  /// Marchandise reçue intégralement.
  Future<void> markReceived(String purchaseOrderId) =>
      _setStatus(purchaseOrderId, 'RECEIVED');

  /// Marchandise reçue partiellement (le reste reste attendu).
  Future<void> markPartiallyReceived(String purchaseOrderId) =>
      _setStatus(purchaseOrderId, 'PARTIALLY_RECEIVED');

  Future<void> cancel(String purchaseOrderId) =>
      _setStatus(purchaseOrderId, 'CANCELLED');

  /// Applique la transition si elle est valide, sinon ignore la demande
  /// (l'UI ne propose déjà que des transitions valides, mais ce garde-fou
  /// protège aussi contre des appels directs au dépôt).
  Future<void> _setStatus(String purchaseOrderId, String status) async {
    final rows = await _db.getAll(
      'SELECT status FROM purchase_orders WHERE id = ?',
      [purchaseOrderId],
    );
    if (rows.isEmpty) return;
    final current = rows.first['status'] as String;
    if (!canTransition(current, status)) return;

    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'UPDATE purchase_orders SET status = ?, updated_at = ? WHERE id = ?',
      [status, now, purchaseOrderId],
    );
  }
}

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepository>((
  ref,
) {
  final sync = ref.watch(syncServiceProvider);
  return PurchaseOrderRepository(sync.db);
});
