import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';

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
  Future<List<({String id, String name})>> importProducts({
    required String tenantId,
    required List<ImportedProductRow> rows,
  }) async {
    final created = <({String id, String name})>[];
    for (final row in rows) {
      if (row.isDuplicate) continue;
      final id = await _products.createProduct(
        tenantId: tenantId,
        name: row.name,
        sellingPrice: row.sellingPrice,
        barcode: row.barcode,
        dciName: row.dciName,
        category: row.category,
      );
      created.add((id: id, name: row.name));
    }
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
