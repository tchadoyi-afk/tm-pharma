import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/core/audit/audit_log_writer.dart';

import 'support/test_db.dart';

const _tenantId = 't1';

Future<List<Map<String, Object?>>> _rows(TestDb testDb) =>
    testDb.db.getAll('SELECT * FROM audit_log ORDER BY created_at');

void main() {
  late TestDb testDb;

  setUp(() async {
    testDb = await TestDb.open();
  });

  tearDown(() async {
    await testDb.dispose();
  });

  test('writeAuditLog insère une ligne avec action, entité et horodatage', () async {
    await writeAuditLog(
      testDb.db,
      tenantId: _tenantId,
      userId: 'u1',
      action: 'product.create',
      entity: 'products',
      entityId: 'p1',
      after: {'name': 'Paracétamol'},
    );

    final rows = await _rows(testDb);
    expect(rows, hasLength(1));
    expect(rows.single['tenant_id'], _tenantId);
    expect(rows.single['user_id'], 'u1');
    expect(rows.single['action'], 'product.create');
    expect(rows.single['entity'], 'products');
    expect(rows.single['entity_id'], 'p1');
    expect(rows.single['after'], '{"name":"Paracétamol"}');
    expect(rows.single['before'], isNull);
    expect(rows.single['device_ts'], isNotNull);
    expect(rows.single['created_at'], rows.single['device_ts']);
  });

  test('writeAuditLog encode before/after en JSON quand fournis', () async {
    await writeAuditLog(
      testDb.db,
      tenantId: _tenantId,
      action: 'price.edit',
      entity: 'products',
      entityId: 'p1',
      before: {'price': 100},
      after: {'price': 120},
    );

    final rows = await _rows(testDb);
    expect(rows.single['before'], '{"price":100}');
    expect(rows.single['after'], '{"price":120}');
  });

  test('writeAuditLog accepte userId/entity/entityId/before/after absents', () async {
    await writeAuditLog(testDb.db, tenantId: _tenantId, action: 'session.open');

    final rows = await _rows(testDb);
    expect(rows.single['user_id'], isNull);
    expect(rows.single['entity'], isNull);
    expect(rows.single['entity_id'], isNull);
    expect(rows.single['before'], isNull);
    expect(rows.single['after'], isNull);
  });

  test('writeAuditLog génère un id distinct par appel et préserve l\'ordre', () async {
    await writeAuditLog(testDb.db, tenantId: _tenantId, action: 'a1');
    await writeAuditLog(testDb.db, tenantId: _tenantId, action: 'a2');

    final rows = await _rows(testDb);
    expect(rows, hasLength(2));
    expect(rows[0]['id'], isNot(equals(rows[1]['id'])));
    expect(rows[0]['action'], 'a1');
    expect(rows[1]['action'], 'a2');
  });
}
