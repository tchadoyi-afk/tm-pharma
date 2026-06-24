import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/stock/stock_repository.dart';
import 'package:uuid/uuid.dart';

import 'support/test_db.dart';

const _uuid = Uuid();
const _tenantId = 't1';

void main() {
  late TestDb testDb;
  late StockRepository repo;

  setUp(() async {
    testDb = await TestDb.open();
    repo = StockRepository(testDb.db);
  });

  tearDown(() async {
    await testDb.dispose();
  });

  group('receiveStock', () {
    test('crée un nouveau lot et un mouvement RECEIPT quand le numéro de lot est inédit', () async {
      await repo.receiveStock(
        tenantId: _tenantId,
        productId: 'p1',
        quantity: 10,
        lotNumber: 'L001',
        createdBy: 'u1',
      );

      final lots = await testDb.db.getAll('SELECT * FROM lots WHERE product_id = ?', ['p1']);
      expect(lots, hasLength(1));
      expect(lots.single['quantity'], 10);
      expect(lots.single['lot_number'], 'L001');

      final movements = await testDb.db.getAll(
        "SELECT * FROM stock_movements WHERE type = 'RECEIPT' AND product_id = ?",
        ['p1'],
      );
      expect(movements, hasLength(1));
      expect(movements.single['quantity_delta'], 10);
    });

    test('complète le lot existant (même numéro) au lieu d\'en créer un nouveau', () async {
      await repo.receiveStock(
        tenantId: _tenantId,
        productId: 'p1',
        quantity: 10,
        lotNumber: 'L001',
      );
      await repo.receiveStock(
        tenantId: _tenantId,
        productId: 'p1',
        quantity: 5,
        lotNumber: 'L001',
      );

      final lots = await testDb.db.getAll('SELECT * FROM lots WHERE product_id = ?', ['p1']);
      expect(lots, hasLength(1));
      expect(lots.single['quantity'], 15);

      final movements = await testDb.db.getAll(
        "SELECT * FROM stock_movements WHERE type = 'RECEIPT' AND product_id = ?",
        ['p1'],
      );
      expect(movements, hasLength(2));
    });

    test('sans numéro de lot, chaque réception crée un nouveau lot', () async {
      await repo.receiveStock(tenantId: _tenantId, productId: 'p1', quantity: 10);
      await repo.receiveStock(tenantId: _tenantId, productId: 'p1', quantity: 5);

      final lots = await testDb.db.getAll('SELECT * FROM lots WHERE product_id = ?', ['p1']);
      expect(lots, hasLength(2));
    });

    test('quantité nulle ou négative est ignorée (aucune écriture)', () async {
      await repo.receiveStock(tenantId: _tenantId, productId: 'p1', quantity: 0);
      await repo.receiveStock(tenantId: _tenantId, productId: 'p1', quantity: -3);

      final lots = await testDb.db.getAll('SELECT * FROM lots WHERE product_id = ?', ['p1']);
      expect(lots, isEmpty);
    });

    test('journalise STOCK_RECEIPT dans audit_log', () async {
      await repo.receiveStock(
        tenantId: _tenantId,
        productId: 'p1',
        quantity: 10,
        lotNumber: 'L001',
        createdBy: 'u1',
      );
      final logs = await testDb.db.getAll(
        "SELECT * FROM audit_log WHERE action = 'STOCK_RECEIPT'",
      );
      expect(logs, hasLength(1));
      expect(logs.single['user_id'], 'u1');
    });
  });

  group('recordStockExit', () {
    Future<String> insertLot(int quantity) async {
      final id = _uuid.v4();
      final now = DateTime.now().toUtc().toIso8601String();
      await testDb.db.execute(
        'INSERT INTO lots (id, tenant_id, product_id, quantity, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [id, _tenantId, 'p1', quantity, now, now],
      );
      return id;
    }

    test('décrémente le lot et journalise un mouvement négatif (DONATION)', () async {
      final lotId = await insertLot(10);
      await repo.recordStockExit(
        tenantId: _tenantId,
        lotId: lotId,
        productId: 'p1',
        quantity: 4,
        type: 'DONATION',
        reason: 'don ONG',
        createdBy: 'u1',
      );

      final lot = await testDb.db.getAll('SELECT * FROM lots WHERE id = ?', [lotId]);
      expect(lot.single['quantity'], 6);

      final movements = await testDb.db.getAll(
        "SELECT * FROM stock_movements WHERE type = 'DONATION' AND lot_id = ?",
        [lotId],
      );
      expect(movements, hasLength(1));
      expect(movements.single['quantity_delta'], -4);
      expect(movements.single['reason'], 'don ONG');
    });

    test('journalise STOCK_EXIT_<type> dans audit_log', () async {
      final lotId = await insertLot(10);
      await repo.recordStockExit(
        tenantId: _tenantId,
        lotId: lotId,
        productId: 'p1',
        quantity: 4,
        type: 'SUPPLIER_RETURN',
      );
      final logs = await testDb.db.getAll(
        "SELECT * FROM audit_log WHERE action = 'STOCK_EXIT_SUPPLIER_RETURN'",
      );
      expect(logs, hasLength(1));
    });

    test('quantité nulle ou négative est ignorée', () async {
      final lotId = await insertLot(10);
      await repo.recordStockExit(
        tenantId: _tenantId,
        lotId: lotId,
        productId: 'p1',
        quantity: 0,
        type: 'SCRAP',
      );
      final lot = await testDb.db.getAll('SELECT * FROM lots WHERE id = ?', [lotId]);
      expect(lot.single['quantity'], 10);
    });

    test('refuse un type de sortie inconnu (assertion)', () async {
      final lotId = await insertLot(10);
      expect(
        () => repo.recordStockExit(
          tenantId: _tenantId,
          lotId: lotId,
          productId: 'p1',
          quantity: 1,
          type: 'BOGUS',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('adjustLot', () {
    Future<String> insertLot(int quantity) async {
      final id = _uuid.v4();
      final now = DateTime.now().toUtc().toIso8601String();
      await testDb.db.execute(
        'INSERT INTO lots (id, tenant_id, product_id, quantity, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [id, _tenantId, 'p1', quantity, now, now],
      );
      return id;
    }

    test('ajustement positif augmente la quantité du lot', () async {
      final lotId = await insertLot(10);
      await repo.adjustLot(
        tenantId: _tenantId,
        lotId: lotId,
        productId: 'p1',
        quantityDelta: 3,
        reason: 'recomptage',
        createdBy: 'u1',
      );
      final lot = await testDb.db.getAll('SELECT * FROM lots WHERE id = ?', [lotId]);
      expect(lot.single['quantity'], 13);
    });

    test('ajustement négatif diminue la quantité du lot', () async {
      final lotId = await insertLot(10);
      await repo.adjustLot(
        tenantId: _tenantId,
        lotId: lotId,
        productId: 'p1',
        quantityDelta: -3,
        reason: 'casse',
      );
      final lot = await testDb.db.getAll('SELECT * FROM lots WHERE id = ?', [lotId]);
      expect(lot.single['quantity'], 7);
    });

    test('delta nul ne fait aucune écriture', () async {
      final lotId = await insertLot(10);
      await repo.adjustLot(
        tenantId: _tenantId,
        lotId: lotId,
        productId: 'p1',
        quantityDelta: 0,
      );
      final movements = await testDb.db.getAll(
        "SELECT * FROM stock_movements WHERE type = 'ADJUSTMENT'",
      );
      expect(movements, isEmpty);
    });

    test('journalise STOCK_ADJUSTMENT dans audit_log', () async {
      final lotId = await insertLot(10);
      await repo.adjustLot(
        tenantId: _tenantId,
        lotId: lotId,
        productId: 'p1',
        quantityDelta: -2,
        reason: 'perte',
        createdBy: 'u1',
      );
      final logs = await testDb.db.getAll(
        "SELECT * FROM audit_log WHERE action = 'STOCK_ADJUSTMENT'",
      );
      expect(logs, hasLength(1));
    });
  });

  group('getDailySalesVelocity', () {
    test('calcule la moyenne journalière sur la fenêtre demandée', () async {
      final now = DateTime.now().toUtc();
      final lotId = _uuid.v4();
      await testDb.db.execute(
        'INSERT INTO lots (id, tenant_id, product_id, quantity, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [lotId, _tenantId, 'p1', 100, now.toIso8601String(), now.toIso8601String()],
      );
      final saleId = _uuid.v4();
      await testDb.db.execute(
        'INSERT INTO sales (id, tenant_id, total_amount, status, sold_at, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          saleId,
          _tenantId,
          500,
          'COMPLETED',
          now.toIso8601String(),
          now.toIso8601String(),
          now.toIso8601String(),
        ],
      );
      await testDb.db.execute(
        'INSERT INTO sale_items (id, tenant_id, sale_id, lot_id, quantity, unit_price, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          _uuid.v4(),
          _tenantId,
          saleId,
          lotId,
          30,
          500,
          now.toIso8601String(),
          now.toIso8601String(),
        ],
      );

      final velocity = await repo.getDailySalesVelocity(windowDays: 30);
      expect(velocity['p1'], closeTo(1.0, 0.001));
    });

    test('ignore les ventes hors fenêtre', () async {
      final old = DateTime.now().toUtc().subtract(const Duration(days: 60));
      final lotId = _uuid.v4();
      await testDb.db.execute(
        'INSERT INTO lots (id, tenant_id, product_id, quantity, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [lotId, _tenantId, 'p1', 100, old.toIso8601String(), old.toIso8601String()],
      );
      final saleId = _uuid.v4();
      await testDb.db.execute(
        'INSERT INTO sales (id, tenant_id, total_amount, status, sold_at, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          saleId,
          _tenantId,
          500,
          'COMPLETED',
          old.toIso8601String(),
          old.toIso8601String(),
          old.toIso8601String(),
        ],
      );
      await testDb.db.execute(
        'INSERT INTO sale_items (id, tenant_id, sale_id, lot_id, quantity, unit_price, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          _uuid.v4(),
          _tenantId,
          saleId,
          lotId,
          30,
          500,
          old.toIso8601String(),
          old.toIso8601String(),
        ],
      );

      final velocity = await repo.getDailySalesVelocity(windowDays: 30);
      expect(velocity['p1'], isNull);
    });
  });
}
