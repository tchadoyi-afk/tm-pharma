import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';
import 'stock_models.dart';

/// Stocks par lot, fournisseurs et mouvements (réception/ajustement),
/// via la base locale PowerSync (offline-first).
class StockRepository {
  StockRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

  /// Stock courant par produit (somme des lots), pour repérer les ruptures.
  Stream<List<StockLine>> watchStockLines() {
    return _db
        .watch(
          'SELECT p.id AS product_id, p.name AS name, '
          'p.low_stock_threshold AS low_stock_threshold, '
          'COALESCE(SUM(l.quantity), 0) AS total_quantity '
          'FROM products p '
          'LEFT JOIN lots l ON l.product_id = p.id AND l.deleted_at IS NULL '
          'WHERE p.deleted_at IS NULL '
          'GROUP BY p.id, p.name, p.low_stock_threshold '
          'ORDER BY p.name',
        )
        .map((rs) => rs.map(StockLine.fromRow).toList());
  }

  Stream<List<Lot>> watchLots(String productId) {
    return _db
        .watch(
          'SELECT * FROM lots WHERE product_id = ? AND deleted_at IS NULL '
          'ORDER BY expiration_date',
          parameters: [productId],
        )
        .map((rs) => rs.map(Lot.fromRow).toList());
  }

  Stream<List<Supplier>> watchSuppliers() {
    return _db
        .watch(
          'SELECT * FROM suppliers WHERE deleted_at IS NULL ORDER BY name',
        )
        .map((rs) => rs.map(Supplier.fromRow).toList());
  }

  Future<String> createSupplier({
    required String tenantId,
    required String name,
    String? phone,
    String? email,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'INSERT INTO suppliers (id, tenant_id, name, phone, email, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, tenantId, name, phone, email, now, now],
    );
    return id;
  }

  /// Réceptionne une quantité (nouveau lot ou complément d'un lot existant
  /// par numéro de lot) et journalise le mouvement (traçabilité GS1).
  Future<void> receiveStock({
    required String tenantId,
    required String productId,
    required int quantity,
    String? lotNumber,
    DateTime? expirationDate,
    String? supplierId,
    String? createdBy,
  }) async {
    if (quantity <= 0) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final expirationStr = expirationDate?.toIso8601String().substring(0, 10);

    String lotId;
    final existing = lotNumber == null
        ? const <Map<String, Object?>>[]
        : await _db.getAll(
            'SELECT id FROM lots WHERE product_id = ? AND lot_number = ? '
            'AND deleted_at IS NULL LIMIT 1',
            [productId, lotNumber],
          );
    if (existing.isNotEmpty) {
      lotId = existing.first['id'] as String;
      await _db.execute(
        'UPDATE lots SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
        [quantity, now, lotId],
      );
    } else {
      lotId = _uuid.v4();
      await _db.execute(
        'INSERT INTO lots (id, tenant_id, product_id, lot_number, '
        'expiration_date, quantity, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          lotId,
          tenantId,
          productId,
          lotNumber,
          expirationStr,
          quantity,
          now,
          now,
        ],
      );
    }

    await _db.execute(
      'INSERT INTO stock_movements (id, tenant_id, product_id, lot_id, '
      'supplier_id, type, quantity_delta, created_by, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        _uuid.v4(),
        tenantId,
        productId,
        lotId,
        supplierId,
        'RECEIPT',
        quantity,
        createdBy,
        now,
        now,
      ],
    );
  }

  /// Ajustement manuel d'un lot (correction d'inventaire, perte, casse…).
  Future<void> adjustLot({
    required String tenantId,
    required String lotId,
    required String productId,
    required int quantityDelta,
    String? reason,
    String? createdBy,
  }) async {
    if (quantityDelta == 0) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'UPDATE lots SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
      [quantityDelta, now, lotId],
    );
    await _db.execute(
      'INSERT INTO stock_movements (id, tenant_id, product_id, lot_id, '
      'type, quantity_delta, reason, created_by, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        _uuid.v4(),
        tenantId,
        productId,
        lotId,
        'ADJUSTMENT',
        quantityDelta,
        reason,
        createdBy,
        now,
        now,
      ],
    );
  }
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return StockRepository(sync.db);
});
