import '../stock/stock_models.dart';

/// Niveau d'alerte de péremption d'un lot, du moins au plus urgent.
enum ExpiryAlertLevel { none, j90, j30, j7, expired }

/// Calcule le niveau d'alerte d'un lot à une date donnée (`today`), selon
/// les seuils J-90/J-30/J-7 avant péremption. Pas de date = pas d'alerte
/// (lots sans suivi de péremption, ex. matériel non périssable).
ExpiryAlertLevel expiryAlertLevel(DateTime? expirationDate, DateTime today) {
  if (expirationDate == null) return ExpiryAlertLevel.none;
  final daysLeft = expirationDate.difference(today).inDays;
  if (daysLeft < 0) return ExpiryAlertLevel.expired;
  if (daysLeft <= 7) return ExpiryAlertLevel.j7;
  if (daysLeft <= 30) return ExpiryAlertLevel.j30;
  if (daysLeft <= 90) return ExpiryAlertLevel.j90;
  return ExpiryAlertLevel.none;
}

/// Filtre et trie les lots ayant une alerte active (hors `none`), du plus
/// urgent (expiré) au moins urgent (J-90), pour affichage prioritaire.
List<Lot> lotsWithActiveAlerts(List<Lot> lots, DateTime today) {
  final withAlert = lots
      .where((l) => expiryAlertLevel(l.expirationDate, today) != ExpiryAlertLevel.none)
      .toList();
  withAlert.sort((a, b) {
    final da = a.expirationDate;
    final db = b.expirationDate;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return withAlert;
}
