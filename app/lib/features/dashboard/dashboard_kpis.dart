/// KPI agrégés du tableau de bord (Sprint 11), calculés à partir des
/// résultats de requêtes SQL déjà agrégées côté local (fonctions pures
/// pour rester testables sans dépendance à la base).
class DashboardKpis {
  const DashboardKpis({
    required this.salesTodayCount,
    required this.salesTodayTotal,
    required this.lowStockCount,
    required this.expiringSoonCount,
    required this.stockValue,
  });

  final int salesTodayCount;
  final double salesTodayTotal;
  final int lowStockCount;
  final int expiringSoonCount;
  final double stockValue;

  factory DashboardKpis.fromRows({
    required Map<String, Object?> salesRow,
    required int lowStockCount,
    required int expiringSoonCount,
    required Map<String, Object?> stockValueRow,
  }) {
    return DashboardKpis(
      salesTodayCount: (salesRow['c'] as num?)?.toInt() ?? 0,
      salesTodayTotal: (salesRow['total'] as num?)?.toDouble() ?? 0,
      lowStockCount: lowStockCount,
      expiringSoonCount: expiringSoonCount,
      stockValue: (stockValueRow['value'] as num?)?.toDouble() ?? 0,
    );
  }
}
