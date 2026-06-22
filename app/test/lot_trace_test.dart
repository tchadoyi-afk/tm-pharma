import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/traceability/lot_trace_models.dart';

void main() {
  test('merges movements and sale items into one timeline, newest first', () {
    final movements = [
      {
        'created_at': '2026-01-01T08:00:00.000Z',
        'type': 'RECEIPT',
        'quantity_delta': 100,
        'reason': null,
      },
      {
        'created_at': '2026-01-05T08:00:00.000Z',
        'type': 'ADJUSTMENT',
        'quantity_delta': -2,
        'reason': 'casse',
      },
    ];
    final saleItems = [
      {
        'created_at': '2026-01-03T08:00:00.000Z',
        'quantity': 10,
        'sale_id': 'sale-1',
      },
    ];

    final timeline = buildLotTraceTimeline(
      movements: movements,
      saleItems: saleItems,
    );

    expect(timeline.length, 3);
    expect(timeline[0].type, 'ADJUSTMENT');
    expect(timeline[1].type, 'SALE');
    expect(timeline[1].quantityDelta, -10);
    expect(timeline[1].detail, 'sale-1');
    expect(timeline[2].type, 'RECEIPT');
    expect(timeline[2].quantityDelta, 100);
  });

  test('returns an empty timeline when nothing happened on the lot', () {
    final timeline = buildLotTraceTimeline(movements: const [], saleItems: const []);
    expect(timeline, isEmpty);
  });
}
