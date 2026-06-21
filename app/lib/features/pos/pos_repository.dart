import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';

/// Accès aux ventes via la base locale PowerSync (offline-first).
/// Toute écriture est immédiate en local et mise en file pour la synchro.
class PosRepository {
  PosRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

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
