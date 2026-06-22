import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/dashboard/dashboard_kpis.dart';

void main() {
  test('builds KPIs from raw aggregate rows', () {
    final kpis = DashboardKpis.fromRows(
      salesRow: {'c': 5, 'total': 12500.0},
      lowStockCount: 3,
      expiringSoonCount: 2,
      stockValueRow: {'value': 980000.0},
    );

    expect(kpis.salesTodayCount, 5);
    expect(kpis.salesTodayTotal, 12500.0);
    expect(kpis.lowStockCount, 3);
    expect(kpis.expiringSoonCount, 2);
    expect(kpis.stockValue, 980000.0);
  });

  test('defaults to zero when rows have null aggregates', () {
    final kpis = DashboardKpis.fromRows(
      salesRow: const {'c': null, 'total': null},
      lowStockCount: 0,
      expiringSoonCount: 0,
      stockValueRow: const {'value': null},
    );

    expect(kpis.salesTodayCount, 0);
    expect(kpis.salesTodayTotal, 0);
    expect(kpis.stockValue, 0);
  });
}
