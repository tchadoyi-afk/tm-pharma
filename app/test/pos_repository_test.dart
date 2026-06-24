import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/pos/cart_model.dart';
import 'package:tm_pharma/features/pos/pos_repository.dart';
import 'package:uuid/uuid.dart';

import 'support/test_db.dart';

const _uuid = Uuid();
const _tenantId = 't1';

Future<String> _insertLot(
  TestDb testDb, {
  required String productId,
  required int quantity,
  String? expirationDate,
}) async {
  final id = _uuid.v4();
  final now = DateTime.now().toUtc().toIso8601String();
  await testDb.db.execute(
    'INSERT INTO lots '
    '(id, tenant_id, product_id, quantity, expiration_date, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [id, _tenantId, productId, quantity, expirationDate, now, now],
  );
  return id;
}

Future<Map<String, Object?>> _lot(TestDb testDb, String id) async {
  final rows = await testDb.db.getAll('SELECT * FROM lots WHERE id = ?', [id]);
  return rows.single;
}

void main() {
  late TestDb testDb;
  late PosRepository repo;

  setUp(() async {
    testDb = await TestDb.open();
    repo = PosRepository(testDb.db);
  });

  tearDown(() async {
    await testDb.dispose();
  });

  test('checkout puise dans le lot qui périme le plus tôt (FEFO)', () async {
    final farLot = await _insertLot(
      testDb,
      productId: 'p1',
      quantity: 10,
      expirationDate: '2030-01-01',
    );
    final nearLot = await _insertLot(
      testDb,
      productId: 'p1',
      quantity: 10,
      expirationDate: '2026-01-01',
    );

    final sessionId = await repo.openCashSession(tenantId: _tenantId);
    final cart = const Cart().addProduct(
      productId: 'p1',
      productName: 'Paracétamol',
      unitPrice: 500,
    );

    final saleId = await repo.checkout(
      tenantId: _tenantId,
      cashSessionId: sessionId,
      cart: cart,
      userId: 'u1',
    );

    final items = await testDb.db.getAll(
      'SELECT * FROM sale_items WHERE sale_id = ?',
      [saleId],
    );
    expect(items, hasLength(1));
    expect(items.single['lot_id'], nearLot);

    expect((await _lot(testDb, nearLot))['quantity'], 9);
    expect((await _lot(testDb, farLot))['quantity'], 10);
  });

  test('checkout répartit sur plusieurs lots quand un seul ne suffit pas', () async {
    final lotA = await _insertLot(
      testDb,
      productId: 'p1',
      quantity: 3,
      expirationDate: '2026-01-01',
    );
    final lotB = await _insertLot(
      testDb,
      productId: 'p1',
      quantity: 10,
      expirationDate: '2027-01-01',
    );

    final sessionId = await repo.openCashSession(tenantId: _tenantId);
    var cart = const Cart();
    for (var i = 0; i < 5; i++) {
      cart = cart.addProduct(
        productId: 'p1',
        productName: 'Paracétamol',
        unitPrice: 500,
      );
    }

    final saleId = await repo.checkout(
      tenantId: _tenantId,
      cashSessionId: sessionId,
      cart: cart,
    );

    final items = await testDb.db.getAll(
      'SELECT * FROM sale_items WHERE sale_id = ? ORDER BY lot_id',
      [saleId],
    );
    expect(items, hasLength(2));
    expect((await _lot(testDb, lotA))['quantity'], 0);
    expect((await _lot(testDb, lotB))['quantity'], 8);
  });

  test('checkout échoue sans rien écrire si le stock est insuffisant', () async {
    await _insertLot(
      testDb,
      productId: 'p1',
      quantity: 1,
      expirationDate: '2026-01-01',
    );

    final sessionId = await repo.openCashSession(tenantId: _tenantId);
    var cart = const Cart();
    for (var i = 0; i < 5; i++) {
      cart = cart.addProduct(
        productId: 'p1',
        productName: 'Paracétamol',
        unitPrice: 500,
      );
    }

    await expectLater(
      repo.checkout(tenantId: _tenantId, cashSessionId: sessionId, cart: cart),
      throwsA(isA<InsufficientStockException>()),
    );

    final sales = await testDb.db.getAll('SELECT * FROM sales');
    expect(sales, isEmpty);
    final items = await testDb.db.getAll('SELECT * FROM sale_items');
    expect(items, isEmpty);
  });

  test('checkout panier vide ne crée aucune vente', () async {
    final sessionId = await repo.openCashSession(tenantId: _tenantId);
    final saleId = await repo.checkout(
      tenantId: _tenantId,
      cashSessionId: sessionId,
      cart: const Cart(),
    );
    expect(saleId, '');
    final sales = await testDb.db.getAll('SELECT * FROM sales');
    expect(sales, isEmpty);
  });

  test('checkout journalise une entrée SALE dans audit_log', () async {
    await _insertLot(
      testDb,
      productId: 'p1',
      quantity: 5,
      expirationDate: '2026-01-01',
    );
    final sessionId = await repo.openCashSession(tenantId: _tenantId);
    final cart = const Cart().addProduct(
      productId: 'p1',
      productName: 'Paracétamol',
      unitPrice: 500,
    );

    final saleId = await repo.checkout(
      tenantId: _tenantId,
      cashSessionId: sessionId,
      cart: cart,
      userId: 'u1',
    );

    final logs = await testDb.db.getAll(
      "SELECT * FROM audit_log WHERE action = 'SALE' AND entity_id = ?",
      [saleId],
    );
    expect(logs, hasLength(1));
    expect(logs.single['tenant_id'], _tenantId);
    expect(logs.single['user_id'], 'u1');
  });

  test('closeCashSession calcule le total depuis les ventes complétées', () async {
    await _insertLot(
      testDb,
      productId: 'p1',
      quantity: 10,
      expirationDate: '2026-01-01',
    );
    final sessionId = await repo.openCashSession(tenantId: _tenantId, userId: 'u1');
    final cart = const Cart()
        .addProduct(productId: 'p1', productName: 'Paracétamol', unitPrice: 500)
        .addProduct(productId: 'p1', productName: 'Paracétamol', unitPrice: 500);

    await repo.checkout(
      tenantId: _tenantId,
      cashSessionId: sessionId,
      cart: cart,
      userId: 'u1',
    );

    await repo.closeCashSession(sessionId);

    final session = await testDb.db.getAll(
      'SELECT * FROM cash_sessions WHERE id = ?',
      [sessionId],
    );
    expect(session.single['status'], 'CLOSED');
    expect(session.single['closing_amount'], 1000.0);

    final logs = await testDb.db.getAll(
      "SELECT * FROM audit_log WHERE action = 'CASH_CLOSE' AND entity_id = ?",
      [sessionId],
    );
    expect(logs, hasLength(1));
  });
}
