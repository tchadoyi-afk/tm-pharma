/// Parsing GS1-128 minimal : extrait GTIN (AI 01), date de péremption
/// (AI 17, format YYMMDD) et numéro de lot (AI 10) d'une chaîne scannée.
/// Couvre les AI utilisés sur les emballages pharma (Togo/Gabon) ; les
/// autres AI rencontrés sont ignorés plutôt que de faire échouer le parsing.
library;

/// Séparateur FNC1 (GS, code ASCII 29) utilisé par les AI à longueur
/// variable (comme le lot, AI 10) quand ils ne sont pas en fin de chaîne.
const _fnc1 = '';

class Gs1Data {
  const Gs1Data({this.gtin, this.expirationDate, this.lotNumber});

  final String? gtin;
  final DateTime? expirationDate;
  final String? lotNumber;

  bool get isEmpty => gtin == null && expirationDate == null && lotNumber == null;
}

/// Longueurs fixes des AI gérés (en chiffres après le code AI).
const _fixedLengthAis = {'01': 14, '17': 6};

/// Parse une chaîne GS1-128 brute (telle que livrée par un scanner laser
/// configuré en mode "transmettre les AI", FNC1 inclus).
Gs1Data parseGs1(String raw) {
  var rest = raw.trim();
  String? gtin;
  DateTime? expiration;
  String? lot;

  while (rest.length >= 2) {
    final ai = rest.substring(0, 2);
    rest = rest.substring(2);
    final fixedLength = _fixedLengthAis[ai];

    String value;
    if (fixedLength != null) {
      if (rest.length < fixedLength) break;
      value = rest.substring(0, fixedLength);
      rest = rest.substring(fixedLength);
    } else {
      final sep = rest.indexOf(_fnc1);
      if (sep == -1) {
        value = rest;
        rest = '';
      } else {
        value = rest.substring(0, sep);
        rest = rest.substring(sep + 1);
      }
    }

    switch (ai) {
      case '01':
        gtin = value;
      case '17':
        expiration = _parseYyMmDd(value);
      case '10':
        lot = value;
    }
  }

  return Gs1Data(gtin: gtin, expirationDate: expiration, lotNumber: lot);
}

DateTime? _parseYyMmDd(String value) {
  if (value.length != 6) return null;
  final yy = int.tryParse(value.substring(0, 2));
  final mm = int.tryParse(value.substring(2, 4));
  final dd = int.tryParse(value.substring(4, 6));
  if (yy == null || mm == null || dd == null) return null;
  // Convention GS1 : pivot sur 50 (00-49 → 2000-2049, 50-99 → 1950-1999).
  final year = yy < 50 ? 2000 + yy : 1900 + yy;
  final day = dd == 0 ? 1 : dd; // jour 00 = fin de mois non géré ; défaut 1.
  try {
    return DateTime(year, mm, day);
  } on Object {
    return null;
  }
}
