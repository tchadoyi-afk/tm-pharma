/// Ligne de stock courant pour une suggestion de réappro (vue minimale,
/// sans dépendance au modèle PowerSync pour rester testable).
class ReorderStockLine {
  const ReorderStockLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.lowStockThreshold,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int lowStockThreshold;
}

/// Suggestion de réapprovisionnement pour un produit.
class ReorderSuggestion {
  const ReorderSuggestion({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.suggestedQuantity,
  });

  final String productId;
  final String productName;
  final int currentQuantity;
  final int suggestedQuantity;
}

/// Calcule les suggestions de réappro : produits dont le stock courant est
/// au ou sous le seuil bas. La quantité suggérée ramène le stock à deux fois
/// le seuil (marge de sécurité), avec un minimum d'1 unité commandée.
///
/// Heuristique simple (étage 1, sans historique de ventes) : pas de
/// dépendance à la vélocité, volontairement — un raffinement ultérieur
/// pourra utiliser `sale_items` pour affiner la quantité.
List<ReorderSuggestion> computeReorderSuggestions(
  List<ReorderStockLine> lines,
) {
  final suggestions = <ReorderSuggestion>[];
  for (final line in lines) {
    if (line.lowStockThreshold <= 0) continue;
    if (line.quantity > line.lowStockThreshold) continue;
    final target = line.lowStockThreshold * 2;
    final suggestedQuantity = (target - line.quantity).clamp(1, target);
    suggestions.add(
      ReorderSuggestion(
        productId: line.productId,
        productName: line.productName,
        currentQuantity: line.quantity,
        suggestedQuantity: suggestedQuantity,
      ),
    );
  }
  return suggestions;
}
