import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/invoicing/invoice_repository.dart';
import 'package:uuid/uuid.dart';

import 'support/test_db.dart';

const _uuid = Uuid();
const _tenantId = 't1';

Future<void> _insertSaleWithItem(
  TestDb testDb, {
  required String saleId,
  required String productName,
  required int quantity,
  required double unitPrice,
}) async {
  final now = DateTime.now().toUtc().toIso8601String();
  final productId = _uuid.v4();
  final lotId = _uuid.v4();
  await testDb.db.execute(
    'INSERT INTO products (id, tenant_id, name, selling_price, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [productId, _tenantId, productName, unitPrice, now, now],
  );
  await testDb.db.execute(
    'INSERT INTO lots (id, tenant_id, product_id, quantity, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [lotId, _tenantId, productId, 100, now, now],
  );
  await testDb.db.execute(
    'INSERT INTO sales (id, tenant_id, total_amount, status, sold_at, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [saleId, _tenantId, unitPrice * quantity, 'COMPLETED', now, now, now],
  );
  await testDb.db.execute(
    'INSERT INTO sale_items (id, tenant_id, sale_id, lot_id, quantity, unit_price, '
    'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [_uuid.v4(), _tenantId, saleId, lotId, quantity, unitPrice, now, now],
  );
}

void main() {
  late TestDb testDb;
  late InvoiceRepository repo;

  setUp(() async {
    testDb = await TestDb.open();
    repo = InvoiceRepository(testDb.db);
  });

  tearDown(() async {
    await testDb.dispose();
  });

  test('createInvoice initialise pharmacy_settings au premier appel (INV-000001)', () async {
    final saleId = _uuid.v4();
    await _insertSaleWithItem(
      testDb,
      saleId: saleId,
      productName: 'Paracétamol',
      quantity: 2,
      unitPrice: 500,
    );

    final invoice = await repo.createInvoice(tenantId: _tenantId, saleId: saleId);

    expect(invoice.invoiceNumber, 'INV-000001');
    expect(invoice.pharmacy.legalName, 'TM Pharma');
    expect(invoice.pharmacy.currency, 'XOF');
    expect(invoice.lines, hasLength(1));
    expect(invoice.lines.single.productName, 'Paracétamol');
    expect(invoice.lines.single.quantity, 2);
    expect(invoice.lines.single.unitPrice, 500);
  });

  test('createInvoice incrémente le compteur séquentiel à chaque appel', () async {
    final saleId1 = _uuid.v4();
    final saleId2 = _uuid.v4();
    await _insertSaleWithItem(
      testDb,
      saleId: saleId1,
      productName: 'Paracétamol',
      quantity: 1,
      unitPrice: 500,
    );
    await _insertSaleWithItem(
      testDb,
      saleId: saleId2,
      productName: 'Amoxicilline',
      quantity: 1,
      unitPrice: 1000,
    );

    final first = await repo.createInvoice(tenantId: _tenantId, saleId: saleId1);
    final second = await repo.createInvoice(tenantId: _tenantId, saleId: saleId2);

    expect(first.invoiceNumber, 'INV-000001');
    expect(second.invoiceNumber, 'INV-000002');

    final settings = await testDb.db.getAll(
      'SELECT invoice_next_number FROM pharmacy_settings WHERE tenant_id = ?',
      [_tenantId],
    );
    expect(settings.single['invoice_next_number'], 3);
  });

  test('createInvoice respecte le préfixe et le numéro courant existants', () async {
    final now = DateTime.now().toUtc().toIso8601String();
    await testDb.db.execute(
      'INSERT INTO pharmacy_settings '
      '(id, tenant_id, legal_name, currency, invoice_prefix, invoice_next_number) '
      "VALUES (?, ?, 'Pharmacie du Centre', 'XAF', 'PDC', 42)",
      [_uuid.v4(), _tenantId],
    );
    final saleId = _uuid.v4();
    await _insertSaleWithItem(
      testDb,
      saleId: saleId,
      productName: 'Ibuprofène',
      quantity: 3,
      unitPrice: 250,
    );

    final invoice = await repo.createInvoice(tenantId: _tenantId, saleId: saleId);

    expect(invoice.invoiceNumber, 'PDC-000042');
    expect(invoice.pharmacy.legalName, 'Pharmacie du Centre');
    expect(invoice.pharmacy.currency, 'XAF');
  });

  test('createInvoice insère une ligne dans la table invoices', () async {
    final saleId = _uuid.v4();
    await _insertSaleWithItem(
      testDb,
      saleId: saleId,
      productName: 'Paracétamol',
      quantity: 1,
      unitPrice: 500,
    );

    await repo.createInvoice(tenantId: _tenantId, saleId: saleId);

    final invoices = await testDb.db.getAll(
      'SELECT * FROM invoices WHERE sale_id = ?',
      [saleId],
    );
    expect(invoices, hasLength(1));
    expect(invoices.single['invoice_number'], 'INV-000001');
  });

  test('createInvoice agrège plusieurs lignes de vente', () async {
    final now = DateTime.now().toUtc().toIso8601String();
    final saleId = _uuid.v4();
    final p1 = _uuid.v4();
    final p2 = _uuid.v4();
    final lot1 = _uuid.v4();
    final lot2 = _uuid.v4();
    await testDb.db.execute(
      'INSERT INTO products (id, tenant_id, name, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [p1, _tenantId, 'Paracétamol', now, now],
    );
    await testDb.db.execute(
      'INSERT INTO products (id, tenant_id, name, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [p2, _tenantId, 'Amoxicilline', now, now],
    );
    await testDb.db.execute(
      'INSERT INTO lots (id, tenant_id, product_id, quantity, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [lot1, _tenantId, p1, 100, now, now],
    );
    await testDb.db.execute(
      'INSERT INTO lots (id, tenant_id, product_id, quantity, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [lot2, _tenantId, p2, 100, now, now],
    );
    await testDb.db.execute(
      'INSERT INTO sales (id, tenant_id, total_amount, status, sold_at, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [saleId, _tenantId, 1500, 'COMPLETED', now, now, now],
    );
    await testDb.db.execute(
      'INSERT INTO sale_items (id, tenant_id, sale_id, lot_id, quantity, unit_price, '
      'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [_uuid.v4(), _tenantId, saleId, lot1, 2, 500, now, now],
    );
    await testDb.db.execute(
      'INSERT INTO sale_items (id, tenant_id, sale_id, lot_id, quantity, unit_price, '
      'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [_uuid.v4(), _tenantId, saleId, lot2, 1, 500, now, now],
    );

    final invoice = await repo.createInvoice(tenantId: _tenantId, saleId: saleId);
    expect(invoice.lines, hasLength(2));
    expect(invoice.lines.map((l) => l.productName), containsAll(['Paracétamol', 'Amoxicilline']));
  });
}
