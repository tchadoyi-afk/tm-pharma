/// Formate un numéro de facture séquentiel : préfixe pharmacie + compteur
/// remis à plat sur 6 chiffres (ex. `INV-000123`).
String formatInvoiceNumber({required String prefix, required int number}) {
  return '$prefix-${number.toString().padLeft(6, '0')}';
}
