import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';
import '../catalog/products_repository.dart';
import '../stock/stock_repository.dart';
import 'csv_import.dart';

/// Reprise de données / onboarding (Sprint 6) : import du catalogue depuis
/// un CSV et inventaire initial assisté (quantités de départ par produit).
class OnboardingRepository {
  OnboardingRepository(this._db, this._products, this._stock);
  final PowerSyncDatabase _db;
  final ProductsRepository _products;
  final StockRepository _stock;
  static const _uuid = Uuid();

  /// Codes-barres déjà présents dans le catalogue de la pharmacie, pour la
  /// détection de doublons à la prévisualisation de l'import.
  Future<Set<String>> existingBarcodes() async {
    final rows = await _db.getAll(
      "SELECT barcode FROM products WHERE deleted_at IS NULL AND barcode IS NOT NULL AND barcode != ''",
    );
    return rows.map((r) => r['barcode'] as String).toSet();
  }

  /// Importe les lignes non marquées comme doublons ; renvoie les produits
  /// effectivement créés (id, nom) pour préparer l'inventaire initial.
  /// Journalise l'opération dans `import_jobs`/`import_rows` (une ligne par
  /// produit importé ou doublon ignoré) pour garder une trace rejouable de
  /// chaque reprise de données — absente jusqu'ici.
  Future<List<({String id, String name})>> importProducts({
    required String tenantId,
    required List<ImportedProductRow> rows,
    String? sourceFilename,
    String? createdBy,
  }) async {
    final created = <({String id, String name})>[];
    final jobId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    var importedCount = 0;
    var duplicateCount = 0;

    await _db.execute(
      'INSERT INTO import_jobs (id, tenant_id, source_filename, total_rows, '
      'imported_rows, duplicate_rows, status, created_by, created_at, updated_at) '
      "VALUES (?, ?, ?, ?, 0, 0, 'COMPLETED', ?, ?, ?)",
      [jobId, tenantId, sourceFilename, rows.length, createdBy, now, now],
    );

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      String? productId;
      if (row.isDuplicate) {
        duplicateCount++;
      } else {
        productId = await _products.createProduct(
          tenantId: tenantId,
          name: row.name,
          sellingPrice: row.sellingPrice,
          barcode: row.barcode,
          dciName: row.dciName,
          category: row.category,
        );
        created.add((id: productId, name: row.name));
        importedCount++;
      }
      await _db.execute(
        'INSERT INTO import_rows (id, tenant_id, import_job_id, row_number, '
        'raw_data, status, product_id, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          _uuid.v4(),
          tenantId,
          jobId,
          i + 1,
          jsonEncode({
            'name': row.name,
            'sellingPrice': row.sellingPrice,
            'barcode': row.barcode,
            'dciName': row.dciName,
            'category': row.category,
          }),
          row.isDuplicate ? 'DUPLICATE_SKIPPED' : 'IMPORTED',
          productId,
          now,
          now,
        ],
      );
    }

    await _db.execute(
      'UPDATE import_jobs SET imported_rows = ?, duplicate_rows = ? WHERE id = ?',
      [importedCount, duplicateCount, jobId],
    );

    return created;
  }

  /// Inventaire initial : crée un lot de départ par produit avec la
  /// quantité saisie (0 ignoré — pas de mouvement sans stock réel).
  Future<void> recordInitialInventory({
    required String tenantId,
    required Map<String, int> quantityByProductId,
  }) async {
    for (final entry in quantityByProductId.entries) {
      if (entry.value <= 0) continue;
      await _stock.receiveStock(
        tenantId: tenantId,
        productId: entry.key,
        quantity: entry.value,
      );
    }
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return OnboardingRepository(
    sync.db,
    ref.watch(productsRepositoryProvider),
    ref.watch(stockRepositoryProvider),
  );
});
