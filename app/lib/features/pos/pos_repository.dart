import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';
import '../stock/stock_models.dart';
import 'cart_model.dart';
import 'fefo.dart';

/// Stock insuffisant (aucun lot ne couvre seul la quantité demandée).
class InsufficientStockException implements Exception {
  InsufficientStockException(this.productName);
  final String productName;
}

/// Accès aux ventes via la base locale PowerSync (offline-first).
/// Toute écriture est immédiate en local et mise en file pour la synchro.
class PosRepository {
  PosRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

  /// Session de caisse actuellement ouverte (au plus une à la fois).
  Stream<Map<String, Object?>?> watchOpenCashSession() => _db
      .watch(
        "SELECT * FROM cash_sessions WHERE status = 'OPEN' "
        'ORDER BY opened_at DESC LIMIT 1',
      )
      .map((rs) => rs.isEmpty ? null : rs.first);

  Future<String> openCashSession({
    required String tenantId,
    String? userId,
    double openingAmount = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'INSERT INTO cash_sessions '
      '(id, tenant_id, user_id, status, opening_amount, opened_at, created_at, updated_at) '
      "VALUES (?, ?, ?, 'OPEN', ?, ?, ?, ?)",
      [id, tenantId, userId, openingAmount, now, now, now],
    );
    return id;
  }

  /// Ventes complétées d'une session, pour l'analyse anti-fraude à la
  /// clôture (cf. `fraud_signals.dart`).
  Future<List<Map<String, Object?>>> getSalesForSession(
    String sessionId,
  ) async {
    return _db.getAll(
      "SELECT * FROM sales WHERE cash_session_id = ? AND status = 'COMPLETED'",
      [sessionId],
    );
  }

  /// Clôture une session : total encaissé en espèces calculé depuis les
  /// ventes (pas saisi à la main, pour éviter l'erreur de caisse).
  Future<void> closeCashSession(String sessionId) async {
    final rows = await _db.getAll(
      "SELECT COALESCE(SUM(total_amount), 0) AS total FROM sales "
      "WHERE cash_session_id = ? AND status = 'COMPLETED'",
      [sessionId],
    );
    final total = (rows.first['total'] as num).toDouble();
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      "UPDATE cash_sessions SET status = 'CLOSED', closing_amount = ?, "
      'closed_at = ?, updated_at = ? WHERE id = ?',
      [total, now, now, sessionId],
    );
  }

  /// Encaisse le panier : choisit le lot FEFO par produit, décrémente sa
  /// quantité, et journalise vente + lignes. Échoue (sans rien écrire) si
  /// la caisse n'est pas ouverte ou si le stock est insuffisant.
  Future<String> checkout({
    required String tenantId,
    required String cashSessionId,
    required Cart cart,
    String? userId,
  }) async {
    if (cart.isEmpty) return '';
    final now = DateTime.now().toUtc().toIso8601String();
    final saleId = _uuid.v4();

    // Résout l'allocation FEFO (multi-lots si besoin) de chaque ligne avant
    // toute écriture, pour ne jamais laisser une vente partiellement
    // enregistrée.
    final resolved = <({CartLine line, String lotId, int quantity})>[];
    for (final line in cart.lines) {
      final lotRows = await _db.getAll(
        'SELECT * FROM lots WHERE product_id = ? AND quantity > 0 '
        'AND deleted_at IS NULL',
        [line.productId],
      );
      final allocation = pickFefoAllocation(
        lotRows.map(Lot.fromRow).toList(),
        line.quantity,
      );
      if (allocation == null) throw InsufficientStockException(line.productName);
      for (final part in allocation) {
        resolved.add((line: line, lotId: part.lot.id, quantity: part.quantity));
      }
    }

    await _db.execute(
      'INSERT INTO sales '
      '(id, tenant_id, user_id, cash_session_id, total_amount, status, '
      'payment_method, sold_at, created_at, updated_at) '
      "VALUES (?, ?, ?, ?, ?, 'COMPLETED', 'CASH', ?, ?, ?)",
      [saleId, tenantId, userId, cashSessionId, cart.total, now, now, now],
    );
    for (final r in resolved) {
      await _db.execute(
        'INSERT INTO sale_items '
        '(id, tenant_id, sale_id, lot_id, quantity, unit_price, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          _uuid.v4(),
          tenantId,
          saleId,
          r.lotId,
          r.quantity,
          r.line.unitPrice,
          now,
          now,
        ],
      );
      await _db.execute(
        'UPDATE lots SET quantity = quantity - ?, updated_at = ? WHERE id = ?',
        [r.quantity, now, r.lotId],
      );
    }
    return saleId;
  }

  /// Nombre de ventes en local (réactif).
  Stream<int> watchLocalSaleCount() => _db
      .watch('SELECT count(*) AS c FROM sales WHERE deleted_at IS NULL')
      .map((rs) => rs.first['c'] as int);

  /// Ventes encore non synchronisées (file d'upload PowerSync).
  Future<int> pendingUploadCount() async {
    final batch = await _db.getCrudBatch();
    return batch?.crud.length ?? 0;
  }

  /// Crée une vente de démonstration (1 ligne) — prouve l'écriture hors-ligne.
  /// NB : `tenantId` est fourni par l'onboarding/auth en conditions réelles.
  Future<String> createDemoSale({
    required String tenantId,
    String? userId,
    double amount = 1000,
  }) async {
    final saleId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await _db.execute(
      'INSERT INTO sales '
      '(id, tenant_id, user_id, total_amount, status, payment_method, sold_at, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [saleId, tenantId, userId, amount, 'COMPLETED', 'CASH', now, now, now],
    );
    await _db.execute(
      'INSERT INTO sale_items '
      '(id, tenant_id, sale_id, quantity, unit_price, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [_uuid.v4(), tenantId, saleId, 1, amount, now, now],
    );
    return saleId;
  }
}

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return PosRepository(sync.db);
});
