import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';
import 'promotion_model.dart';

/// Gestion des promotions (remises temporaires par produit).
class PromotionsRepository {
  PromotionsRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Promotion>> watchPromotions() => _db
      .watch(
        'SELECT * FROM promotions WHERE deleted_at IS NULL ORDER BY ends_at',
      )
      .map((rs) => rs.map(Promotion.fromRow).toList());

  Future<void> createPromotion({
    required String tenantId,
    required String productId,
    required double discountPercent,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'INSERT INTO promotions '
      '(id, tenant_id, product_id, discount_percent, starts_at, ends_at, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        _uuid.v4(),
        tenantId,
        productId,
        discountPercent,
        startsAt.toUtc().toIso8601String(),
        endsAt.toUtc().toIso8601String(),
        now,
        now,
      ],
    );
  }
}

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return PromotionsRepository(sync.db);
});
