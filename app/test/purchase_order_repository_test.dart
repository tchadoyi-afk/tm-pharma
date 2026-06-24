import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/reorder/purchase_order_repository.dart';
import 'package:uuid/uuid.dart';

import 'support/test_db.dart';

const _uuid = Uuid();
const _tenantId = 't1';

Future<String> _insertOrder(
  TestDb testDb, {
  String status = 'DRAFT',
  String? supplierId,
}) async {
  final id = _uuid.v4();
  final now = DateTime.now().toUtc().toIso8601String();
  await testDb.db.execute(
    'INSERT INTO purchase_orders '
    '(id, tenant_id, supplier_id, status, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [id, _tenantId, supplierId, status, now, now],
  );
  return id;
}

Future<void> _insertItem(
  TestDb testDb,
  String orderId,
  String productId,
  int quantity,
) async {
  final now = DateTime.now().toUtc().toIso8601String();
  await testDb.db.execute(
    'INSERT INTO purchase_order_items '
    '(id, tenant_id, purchase_order_id, product_id, quantity, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [_uuid.v4(), _tenantId, orderId, productId, quantity, now, now],
  );
}

Future<String> _statusOf(TestDb testDb, String orderId) async {
  final rows = await testDb.db.getAll(
    'SELECT status FROM purchase_orders WHERE id = ?',
    [orderId],
  );
  return rows.first['status'] as String;
}

void main() {
  late TestDb testDb;
  late PurchaseOrderRepository repo;

  setUp(() async {
    testDb = await TestDb.open();
    repo = PurchaseOrderRepository(testDb.db);
  });

  tearDown(() async {
    await testDb.dispose();
  });

  group('transitions de statut', () {
    test('markSent fait passer une commande DRAFT à SENT', () async {
      final orderId = await _insertOrder(testDb);
      await repo.markSent(orderId);
      expect(await _statusOf(testDb, orderId), 'SENT');
    });

    test('markSent est sans effet sur une commande déjà SENT', () async {
      final orderId = await _insertOrder(testDb, status: 'SENT');
      await repo.markSent(orderId);
      expect(await _statusOf(testDb, orderId), 'SENT');
    });

    test(
      'receiveAllRemaining est sans effet sur une commande DRAFT (transition invalide)',
      () async {
        final orderId = await _insertOrder(testDb);
        await repo.receiveAllRemaining(orderId);
        expect(await _statusOf(testDb, orderId), 'DRAFT');
      },
    );

    test('cancel fait passer une commande SENT à CANCELLED', () async {
      final orderId = await _insertOrder(testDb, status: 'SENT');
      await repo.cancel(orderId);
      expect(await _statusOf(testDb, orderId), 'CANCELLED');
    });

    test('cancel est sans effet sur une commande déjà CANCELLED', () async {
      final orderId = await _insertOrder(testDb, status: 'CANCELLED');
      await repo.cancel(orderId);
      expect(await _statusOf(testDb, orderId), 'CANCELLED');
    });
  });

  group('receiveAllRemaining et le stock', () {
    test(
      'crée un lot et un mouvement de réception pour chaque ligne, '
      'et passe la commande à RECEIVED',
      () async {
        final orderId = await _insertOrder(
          testDb,
          status: 'CONFIRMED',
          supplierId: 'sup1',
        );
        await _insertItem(testDb, orderId, 'prod1', 10);
        await _insertItem(testDb, orderId, 'prod2', 5);

        await repo.receiveAllRemaining(orderId, createdBy: 'user1');

        expect(await _statusOf(testDb, orderId), 'RECEIVED');

        final lots = await testDb.db.getAll(
          'SELECT product_id, quantity FROM lots ORDER BY product_id',
        );
        expect(lots.length, 2);
        expect(lots[0]['product_id'], 'prod1');
        expect(lots[0]['quantity'], 10);
        expect(lots[1]['product_id'], 'prod2');
        expect(lots[1]['quantity'], 5);

        final movements = await testDb.db.getAll(
          "SELECT product_id, type, quantity_delta, supplier_id, created_by "
          "FROM stock_movements WHERE type = 'RECEIPT' ORDER BY product_id",
        );
        expect(movements.length, 2);
        expect(movements[0]['product_id'], 'prod1');
        expect(movements[0]['quantity_delta'], 10);
        expect(movements[0]['supplier_id'], 'sup1');
        expect(movements[0]['created_by'], 'user1');
      },
    );

    test(
      'ne crée aucun lot ni mouvement quand la transition est invalide',
      () async {
        final orderId = await _insertOrder(testDb); // DRAFT
        await _insertItem(testDb, orderId, 'prod1', 10);

        await repo.receiveAllRemaining(orderId);

        expect(await _statusOf(testDb, orderId), 'DRAFT');
        final lots = await testDb.db.getAll('SELECT * FROM lots');
        expect(lots, isEmpty);
        final movements = await testDb.db.getAll('SELECT * FROM stock_movements');
        expect(movements, isEmpty);
      },
    );
  });

  group('receiveItems (réception partielle)', () {
    Future<String> itemIdOf(TestDb testDb, String orderId, String productId) async {
      final rows = await testDb.db.getAll(
        'SELECT id FROM purchase_order_items '
        'WHERE purchase_order_id = ? AND product_id = ?',
        [orderId, productId],
      );
      return rows.first['id'] as String;
    }

    test(
      'une quantité partielle laisse la commande PARTIALLY_RECEIVED et '
      'incrémente received_quantity',
      () async {
        final orderId = await _insertOrder(testDb, status: 'CONFIRMED');
        await _insertItem(testDb, orderId, 'prod1', 10);
        final itemId = await itemIdOf(testDb, orderId, 'prod1');

        await repo.receiveItems(orderId, {itemId: 4});

        expect(await _statusOf(testDb, orderId), 'PARTIALLY_RECEIVED');
        final rows = await testDb.db.getAll(
          'SELECT received_quantity FROM purchase_order_items WHERE id = ?',
          [itemId],
        );
        expect(rows.first['received_quantity'], 4);
        final lots = await testDb.db.getAll('SELECT quantity FROM lots');
        expect(lots.single['quantity'], 4);
      },
    );

    test(
      'compléter le reliquat sur plusieurs appels passe la commande à RECEIVED',
      () async {
        final orderId = await _insertOrder(testDb, status: 'CONFIRMED');
        await _insertItem(testDb, orderId, 'prod1', 10);
        final itemId = await itemIdOf(testDb, orderId, 'prod1');

        await repo.receiveItems(orderId, {itemId: 4});
        expect(await _statusOf(testDb, orderId), 'PARTIALLY_RECEIVED');

        await repo.receiveItems(orderId, {itemId: 6});
        expect(await _statusOf(testDb, orderId), 'RECEIVED');

        final lots = await testDb.db.getAll('SELECT quantity FROM lots');
        expect(lots.length, 2);
        expect(
          lots.fold<int>(0, (sum, r) => sum + (r['quantity'] as int)),
          10,
        );
      },
    );

    test('plafonne la quantité reçue au reliquat (pas de surréception)', () async {
      final orderId = await _insertOrder(testDb, status: 'CONFIRMED');
      await _insertItem(testDb, orderId, 'prod1', 10);
      final itemId = await itemIdOf(testDb, orderId, 'prod1');

      await repo.receiveItems(orderId, {itemId: 999});

      expect(await _statusOf(testDb, orderId), 'RECEIVED');
      final rows = await testDb.db.getAll(
        'SELECT received_quantity FROM purchase_order_items WHERE id = ?',
        [itemId],
      );
      expect(rows.first['received_quantity'], 10);
    });
  });
}
