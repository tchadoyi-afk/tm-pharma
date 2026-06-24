import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/admin/pharmacy_settings_repository.dart';

import 'support/test_db.dart';

const _tenantId = 't1';

void main() {
  late TestDb testDb;
  late PharmacySettingsRepository repo;

  setUp(() async {
    testDb = await TestDb.open();
    repo = PharmacySettingsRepository(testDb.db);
  });

  tearDown(() async {
    await testDb.dispose();
  });

  test('watch renvoie null quand aucun réglage n\'existe pour ce tenant', () async {
    final settings = await repo.watch(_tenantId).first;
    expect(settings, isNull);
  });

  test('upsert crée la ligne au premier appel', () async {
    await repo.upsert(
      tenantId: _tenantId,
      legalName: 'Pharmacie du Centre',
      currency: 'XOF',
      invoicePrefix: 'PDC',
      logoPath: '/tmp/logo.png',
    );

    final rows = await testDb.db.getAll(
      'SELECT * FROM pharmacy_settings WHERE tenant_id = ?',
      [_tenantId],
    );
    expect(rows, hasLength(1));
    expect(rows.single['legal_name'], 'Pharmacie du Centre');
    expect(rows.single['currency'], 'XOF');
    expect(rows.single['invoice_prefix'], 'PDC');
    expect(rows.single['logo_path'], '/tmp/logo.png');
    expect(rows.single['invoice_next_number'], 1);
  });

  test('upsert met à jour la ligne existante sans toucher invoice_next_number', () async {
    await repo.upsert(
      tenantId: _tenantId,
      legalName: 'Pharmacie du Centre',
      currency: 'XOF',
      invoicePrefix: 'PDC',
    );
    await testDb.db.execute(
      'UPDATE pharmacy_settings SET invoice_next_number = 42 WHERE tenant_id = ?',
      [_tenantId],
    );

    await repo.upsert(
      tenantId: _tenantId,
      legalName: 'Nouveau Nom',
      currency: 'XAF',
      invoicePrefix: 'NN',
    );

    final rows = await testDb.db.getAll(
      'SELECT * FROM pharmacy_settings WHERE tenant_id = ?',
      [_tenantId],
    );
    expect(rows, hasLength(1));
    expect(rows.single['legal_name'], 'Nouveau Nom');
    expect(rows.single['currency'], 'XAF');
    expect(rows.single['invoice_prefix'], 'NN');
    expect(rows.single['invoice_next_number'], 42);
  });

  test('watch reflète les valeurs enregistrées via PharmacySettings', () async {
    await repo.upsert(
      tenantId: _tenantId,
      legalName: 'Pharmacie du Centre',
      currency: 'XOF',
      invoicePrefix: 'PDC',
      logoPath: '/tmp/logo.png',
    );

    final settings = await repo.watch(_tenantId).first;
    expect(settings, isNotNull);
    expect(settings!.legalName, 'Pharmacie du Centre');
    expect(settings.currency, 'XOF');
    expect(settings.invoicePrefix, 'PDC');
    expect(settings.logoPath, '/tmp/logo.png');
  });
}
