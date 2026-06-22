import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/audit/audit_models.dart';
import 'package:tm_pharma/features/audit/csv_export.dart';

void main() {
  test('builds a header row even with no entries', () {
    final csv = buildAuditCsv(const []);
    expect(csv, 'created_at,action,entity,entity_id,user_id,before,after');
  });

  test('escapes commas and quotes in cells', () {
    final entry = AuditEntry(
      id: '1',
      userId: 'u1',
      action: 'SALE',
      entity: 'sales',
      entityId: 's1',
      before: null,
      after: '{"note":"a, b \\"c\\""}',
      createdAt: DateTime.utc(2026, 1, 1, 10, 30),
    );
    final csv = buildAuditCsv([entry]);
    final lines = csv.split('\n');
    expect(lines.length, 2);
    expect(lines[1], contains('"{""note"":""a, b \\""c\\""""}"'));
  });

  test('renders one row per entry in order', () {
    final entries = [
      AuditEntry(
        id: '1',
        userId: null,
        action: 'STOCK_RECEIPT',
        entity: 'lots',
        entityId: 'l1',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      AuditEntry(
        id: '2',
        userId: null,
        action: 'SALE',
        entity: 'sales',
        entityId: 's1',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    ];
    final csv = buildAuditCsv(entries);
    final lines = csv.split('\n');
    expect(lines.length, 3);
    expect(lines[1], startsWith('2026-01-01T00:00:00.000Z,STOCK_RECEIPT'));
    expect(lines[2], startsWith('2026-01-02T00:00:00.000Z,SALE'));
  });
}
