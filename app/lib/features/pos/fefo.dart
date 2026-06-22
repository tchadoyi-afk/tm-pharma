import '../stock/stock_models.dart';

/// Compare deux lots par date de péremption croissante ; les lots sans date
/// connue sont priorisés en dernier (on préfère écouler ceux dont on est
/// sûr de la péremption).
int _byExpiration(Lot a, Lot b) {
  final ea = a.expirationDate;
  final eb = b.expirationDate;
  if (ea == null && eb == null) return 0;
  if (ea == null) return 1;
  if (eb == null) return -1;
  return ea.compareTo(eb);
}

/// Sélection FEFO (First-Expired-First-Out) : à la vente, on prélève dans
/// le lot qui périme le plus tôt — pas dans le plus récent — pour limiter
/// les pertes par péremption.
///
/// `lots` n'a pas besoin d'être pré-trié : le tri FEFO est fait ici.
/// Retourne `null` si aucun lot ne couvre seul la quantité demandée
/// (pas de prélèvement partiel multi-lots — voir [pickFefoAllocation]).
Lot? pickFefoLot(List<Lot> lots, int quantity) {
  final eligible = lots.where((l) => l.quantity >= quantity).toList()
    ..sort(_byExpiration);
  return eligible.isEmpty ? null : eligible.first;
}

/// FEFO intelligent : répartit la quantité demandée sur plusieurs lots
/// (du plus proche de la péremption au plus lointain) quand aucun lot seul
/// ne suffit. Retourne `null` si le stock total disponible est insuffisant.
List<({Lot lot, int quantity})>? pickFefoAllocation(
  List<Lot> lots,
  int quantity,
) {
  if (quantity <= 0) return null;
  final sorted = lots.where((l) => l.quantity > 0).toList()
    ..sort(_byExpiration);
  final totalAvailable = sorted.fold<int>(0, (sum, l) => sum + l.quantity);
  if (totalAvailable < quantity) return null;

  final allocation = <({Lot lot, int quantity})>[];
  var remaining = quantity;
  for (final lot in sorted) {
    if (remaining <= 0) break;
    final take = lot.quantity < remaining ? lot.quantity : remaining;
    allocation.add((lot: lot, quantity: take));
    remaining -= take;
  }
  return allocation;
}
