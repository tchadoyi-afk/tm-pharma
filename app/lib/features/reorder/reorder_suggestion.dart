/// Ligne de stock courant pour une suggestion de réappro (vue minimale,
/// sans dépendance au modèle PowerSync pour rester testable).
class ReorderStockLine {
  const ReorderStockLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.lowStockThreshold,
    this.dailyVelocity = 0,
    this.leadTimeDays = 0,
    this.supplierId,
    this.supplierName,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int lowStockThreshold;
  /// Vente moyenne par jour sur la fenêtre d'observation (0 si pas
  /// d'historique de ventes — la formule retombe alors sur le seuil bas).
  final double dailyVelocity;
  /// Délai de livraison habituel du fournisseur par défaut (jours, 0 = inconnu).
  final int leadTimeDays;
  final String? supplierId;
  final String? supplierName;
}

/// Suggestion de réapprovisionnement pour un produit.
class ReorderSuggestion {
  const ReorderSuggestion({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.suggestedQuantity,
    this.supplierId,
    this.supplierName,
  });

  final String productId;
  final String productName;
  final int currentQuantity;
  final int suggestedQuantity;
  final String? supplierId;
  final String? supplierName;
}

/// Marge de couverture (jours) visée au-delà du délai de livraison, quand
/// une vélocité de vente est disponible — absorbe les écarts de consommation
/// pendant que la commande est en route (stock de sécurité).
const _safetyCoverageDays = 14;

/// Calcule les suggestions de réapprovisionnement.
///
/// Sans historique de ventes (`dailyVelocity == 0`) et sans délai fournisseur
/// connu (`leadTimeDays == 0`), la formule retombe sur l'heuristique simple
/// d'origine : déclenchement au seuil bas, quantité ramenant à 2x le seuil.
///
/// Avec vélocité + délai connus, le déclenchement avance au point de
/// commande réel (vélocité × délai, si plus élevé que le seuil bas) et la
/// quantité suggérée couvre le délai fournisseur + une marge de sécurité,
/// plutôt qu'un multiple arbitraire du seuil.
List<ReorderSuggestion> computeReorderSuggestions(
  List<ReorderStockLine> lines,
) {
  final suggestions = <ReorderSuggestion>[];
  for (final line in lines) {
    if (line.lowStockThreshold <= 0) continue;

    final velocityReorderPoint = (line.dailyVelocity * line.leadTimeDays).ceil();
    final reorderPoint = velocityReorderPoint > line.lowStockThreshold
        ? velocityReorderPoint
        : line.lowStockThreshold;
    if (line.quantity > reorderPoint) continue;

    final target = line.dailyVelocity > 0
        ? (line.dailyVelocity * (line.leadTimeDays + _safetyCoverageDays)).ceil()
        : line.lowStockThreshold * 2;
    final suggestedQuantity = (target - line.quantity).clamp(1, target < 1 ? 1 : target);
    suggestions.add(
      ReorderSuggestion(
        productId: line.productId,
        productName: line.productName,
        currentQuantity: line.quantity,
        suggestedQuantity: suggestedQuantity,
        supplierId: line.supplierId,
        supplierName: line.supplierName,
      ),
    );
  }
  return suggestions;
}
