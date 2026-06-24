import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/catalog/products_repository.dart';
import 'package:tm_pharma/features/onboarding/csv_import.dart';
import 'package:tm_pharma/features/onboarding/onboarding_repository.dart';
import 'package:tm_pharma/features/stock/stock_repository.dart';

import 'support/test_db.dart';

const _tenantId = 't1';

void main() {
  late TestDb testDb;
  late OnboardingRepository repo;

  setUp(() async {
    testDb = await TestDb.open();
    repo = OnboardingRepository(
      testDb.db,
      ProductsRepository(testDb.db),
      StockRepository(testDb.db),
    );
  });

  tearDown(() async {
    await testDb.dispose();
  });

  group('existingBarcodes', () {
    test('renvoie les codes-barres déjà présents dans le catalogue', () async {
      final products = ProductsRepository(testDb.db);
      await products.createProduct(
        tenantId: _tenantId,
        name: 'Paracétamol',
        sellingPrice: 500,
        barcode: '0123456789012',
      );
      await products.createProduct(
        tenantId: _tenantId,
        name: 'Amoxicilline',
        sellingPrice: 1000,
      );

      final barcodes = await repo.existingBarcodes();
      expect(barcodes, {'0123456789012'});
    });

    test('liste vide quand le catalogue est vide', () async {
      expect(await repo.existingBarcodes(), isEmpty);
    });
  });

  group('importProducts', () {
    test('crée un produit par ligne non marquée doublon', () async {
      const rows = [
        ImportedProductRow(name: 'Paracétamol', sellingPrice: 500),
        ImportedProductRow(name: 'Amoxicilline', sellingPrice: 1000),
      ];
      final created = await repo.importProducts(tenantId: _tenantId, rows: rows);

      expect(created.map((c) => c.name), ['Paracétamol', 'Amoxicilline']);
      final inDb = await testDb.db.getAll('SELECT * FROM products');
      expect(inDb, hasLength(2));
    });

    test('ignore les lignes marquées comme doublons', () async {
      const rows = [
        ImportedProductRow(name: 'Paracétamol', sellingPrice: 500),
        ImportedProductRow(
          name: 'Déjà présent',
          sellingPrice: 200,
          isDuplicate: true,
        ),
      ];
      final created = await repo.importProducts(tenantId: _tenantId, rows: rows);

      expect(created, hasLength(1));
      expect(created.single.name, 'Paracétamol');
      final inDb = await testDb.db.getAll('SELECT * FROM products');
      expect(inDb, hasLength(1));
    });

    test('liste vide en entrée -> aucune création', () async {
      final created = await repo.importProducts(tenantId: _tenantId, rows: const []);
      expect(created, isEmpty);
    });

    test('journalise un import_job avec compteurs corrects', () async {
      const rows = [
        ImportedProductRow(name: 'Paracétamol', sellingPrice: 500),
        ImportedProductRow(
          name: 'Déjà présent',
          sellingPrice: 200,
          isDuplicate: true,
        ),
      ];
      await repo.importProducts(
        tenantId: _tenantId,
        rows: rows,
        sourceFilename: 'catalogue.csv',
        createdBy: 'user-1',
      );

      final jobs = await testDb.db.getAll('SELECT * FROM import_jobs');
      expect(jobs, hasLength(1));
      final job = jobs.single;
      expect(job['tenant_id'], _tenantId);
      expect(job['source_filename'], 'catalogue.csv');
      expect(job['created_by'], 'user-1');
      expect(job['total_rows'], 2);
      expect(job['imported_rows'], 1);
      expect(job['duplicate_rows'], 1);
      expect(job['status'], 'COMPLETED');
    });

    test('journalise une import_row par ligne, avec statut et lien produit', () async {
      const rows = [
        ImportedProductRow(name: 'Paracétamol', sellingPrice: 500, barcode: '123'),
        ImportedProductRow(
          name: 'Déjà présent',
          sellingPrice: 200,
          isDuplicate: true,
        ),
      ];
      final created = await repo.importProducts(tenantId: _tenantId, rows: rows);

      final importRows = await testDb.db.getAll(
        'SELECT * FROM import_rows ORDER BY row_number',
      );
      expect(importRows, hasLength(2));

      final first = importRows[0];
      expect(first['row_number'], 1);
      expect(first['status'], 'IMPORTED');
      expect(first['product_id'], created.single.id);
      final firstRaw = jsonDecode(first['raw_data'] as String) as Map;
      expect(firstRaw['name'], 'Paracétamol');
      expect(firstRaw['barcode'], '123');

      final second = importRows[1];
      expect(second['row_number'], 2);
      expect(second['status'], 'DUPLICATE_SKIPPED');
      expect(second['product_id'], isNull);
    });
  });

  group('recordInitialInventory', () {
    test('crée un lot de réception par produit avec quantité positive', () async {
      final products = ProductsRepository(testDb.db);
      final p1 = await products.createProduct(
        tenantId: _tenantId,
        name: 'Paracétamol',
        sellingPrice: 500,
      );
      final p2 = await products.createProduct(
        tenantId: _tenantId,
        name: 'Amoxicilline',
        sellingPrice: 1000,
      );

      await repo.recordInitialInventory(
        tenantId: _tenantId,
        quantityByProductId: {p1: 50, p2: 20},
      );

      final lots = await testDb.db.getAll('SELECT * FROM lots ORDER BY product_id');
      expect(lots, hasLength(2));
      final quantities = lots.map((l) => l['quantity']).toSet();
      expect(quantities, {50, 20});

      final movements = await testDb.db.getAll(
        "SELECT * FROM stock_movements WHERE type = 'RECEIPT'",
      );
      expect(movements, hasLength(2));
    });

    test('ignore les quantités nulles ou négatives', () async {
      final products = ProductsRepository(testDb.db);
      final p1 = await products.createProduct(
        tenantId: _tenantId,
        name: 'Paracétamol',
        sellingPrice: 500,
      );

      await repo.recordInitialInventory(
        tenantId: _tenantId,
        quantityByProductId: {p1: 0},
      );

      final lots = await testDb.db.getAll('SELECT * FROM lots');
      expect(lots, isEmpty);
    });

    test('map vide -> aucune écriture', () async {
      await repo.recordInitialInventory(
        tenantId: _tenantId,
        quantityByProductId: const {},
      );
      final lots = await testDb.db.getAll('SELECT * FROM lots');
      expect(lots, isEmpty);
    });
  });
}
