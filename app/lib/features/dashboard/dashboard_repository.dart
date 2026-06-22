import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';

import '../../core/sync/sync_service.dart';
import 'dashboard_kpis.dart';

/// Calcule les KPI du tableau de bord (Sprint 11) à partir de la base
/// locale PowerSync — fonctionne hors-ligne, comme le reste de l'app.
class DashboardRepository {
  DashboardRepository(this._db);
  final PowerSyncDatabase _db;

  Future<DashboardKpis> getKpis() async {
    final todayStart = DateTime.now().toUtc();
    final dayStart = DateTime.utc(
      todayStart.year,
      todayStart.month,
      todayStart.day,
    ).toIso8601String();
    final in30Days = todayStart
        .add(const Duration(days: 30))
        .toIso8601String()
        .substring(0, 10);

    final salesRows = await _db.getAll(
      "SELECT COUNT(*) AS c, COALESCE(SUM(total_amount), 0) AS total "
      "FROM sales WHERE status = 'COMPLETED' AND sold_at >= ? AND deleted_at IS NULL",
      [dayStart],
    );

    final lowStockRows = await _db.getAll(
      'SELECT COUNT(*) AS c FROM ('
      '  SELECT p.id, p.low_stock_threshold, COALESCE(SUM(l.quantity), 0) AS qty '
      '  FROM products p '
      '  LEFT JOIN lots l ON l.product_id = p.id AND l.deleted_at IS NULL '
      '  WHERE p.deleted_at IS NULL '
      '  GROUP BY p.id, p.low_stock_threshold '
      '  HAVING qty <= p.low_stock_threshold'
      ')',
    );

    final expiringRows = await _db.getAll(
      'SELECT COUNT(*) AS c FROM lots '
      'WHERE deleted_at IS NULL AND quantity > 0 AND expiration_date IS NOT NULL '
      'AND expiration_date <= ?',
      [in30Days],
    );

    final stockValueRows = await _db.getAll(
      'SELECT COALESCE(SUM(l.quantity * p.selling_price), 0) AS value '
      'FROM lots l JOIN products p ON p.id = l.product_id '
      'WHERE l.deleted_at IS NULL AND p.deleted_at IS NULL',
    );

    return DashboardKpis.fromRows(
      salesRow: salesRows.first,
      lowStockCount: (lowStockRows.first['c'] as num?)?.toInt() ?? 0,
      expiringSoonCount: (expiringRows.first['c'] as num?)?.toInt() ?? 0,
      stockValueRow: stockValueRows.first,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return DashboardRepository(sync.db);
});
