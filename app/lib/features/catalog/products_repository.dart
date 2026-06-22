import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';
import 'product_model.dart';

/// Catalogue produits via la base locale PowerSync (offline-first).
/// Recherche par nom/DCI (début de frappe) ou code-barres — toujours
/// disponible en secours quand le scan échoue (réalité terrain).
class ProductsRepository {
  ProductsRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Product>> watchProducts({String search = ''}) {
    final term = search.trim();
    if (term.isEmpty) {
      return _db
          .watch(
            'SELECT * FROM products WHERE deleted_at IS NULL ORDER BY name',
          )
          .map((rs) => rs.map(Product.fromRow).toList());
    }
    final like = '%$term%';
    return _db
        .watch(
          'SELECT * FROM products '
          'WHERE deleted_at IS NULL '
          "AND (name LIKE ? OR dci_name LIKE ? OR barcode = ?) "
          'ORDER BY name',
          parameters: [like, like, term],
        )
        .map((rs) => rs.map(Product.fromRow).toList());
  }

  Future<List<ReferenceProduct>> searchReferenceCatalog(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return const [];
    final like = '%$trimmed%';
    final rows = await _db.getAll(
      'SELECT * FROM reference_products '
      'WHERE dci_name LIKE ? OR barcode = ? '
      'ORDER BY dci_name LIMIT 20',
      [like, trimmed],
    );
    return rows.map(ReferenceProduct.fromRow).toList();
  }

  /// Crée un produit du catalogue de la pharmacie, optionnellement à partir
  /// d'une entrée du référentiel (DCI pré-remplie).
  Future<String> createProduct({
    required String tenantId,
    required String name,
    required double sellingPrice,
    String? barcode,
    String? dciName,
    String unit = 'unité',
    String? category,
    String? referenceId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'INSERT INTO products '
      '(id, tenant_id, barcode, name, dci_name, unit, category, reference_id, '
      'selling_price, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        tenantId,
        normalizeBarcode(barcode),
        name,
        dciName,
        unit,
        category,
        referenceId,
        sellingPrice,
        now,
        now,
      ],
    );
    return id;
  }

  /// Associe (ou remplace) le code-barres d'un produit existant — « au vol »,
  /// quand une boîte sans code lisible est finalement scannée plus tard.
  Future<void> attachBarcode(String productId, String barcode) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'UPDATE products SET barcode = ?, updated_at = ? WHERE id = ?',
      [normalizeBarcode(barcode), now, productId],
    );
  }

  Future<void> updatePrice(String productId, double sellingPrice) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'UPDATE products SET selling_price = ?, updated_at = ? WHERE id = ?',
      [sellingPrice, now, productId],
    );
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return ProductsRepository(sync.db);
});
