import '../stock/stock_models.dart';

/// Sélection FEFO (First-Expired-First-Out) : à la vente, on prélève dans
/// le lot qui périme le plus tôt — pas dans le plus récent — pour limiter
/// les pertes par péremption. Lots sans date connue priorisés en dernier
/// (on préfère écouler ceux dont on est sûr de la péremption).
///
/// `lots` n'a pas besoin d'être pré-trié : le tri FEFO est fait ici.
/// Retourne `null` si aucun lot ne couvre seul la quantité demandée
/// (pas de prélèvement partiel multi-lots dans cette version).
Lot? pickFefoLot(List<Lot> lots, int quantity) {
  final eligible = lots.where((l) => l.quantity >= quantity).toList()
    ..sort((a, b) {
      final ea = a.expirationDate;
      final eb = b.expirationDate;
      if (ea == null && eb == null) return 0;
      if (ea == null) return 1;
      if (eb == null) return -1;
      return ea.compareTo(eb);
    });
  return eligible.isEmpty ? null : eligible.first;
}
