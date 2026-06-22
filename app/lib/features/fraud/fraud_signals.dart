/// Vente minimale (vue, sans dépendance au modèle PowerSync) utilisée par
/// l'heuristique anti-fraude.
class FraudSaleSample {
  const FraudSaleSample({
    required this.totalAmount,
    required this.soldAt,
    this.discountPercent = 0,
  });

  final double totalAmount;
  final DateTime soldAt;
  final double discountPercent;
}

enum FraudSignalType { discountJustUnderThreshold, offHours, amountOutlier }

class FraudSignal {
  const FraudSignal(this.type, this.message);
  final FraudSignalType type;
  final String message;
}

/// Heuristique locale (étage 1, sans backend ni historique long) qui
/// repère des motifs suspects sur les ventes d'une session de caisse :
/// - remises répétées juste sous le seuil d'approbation (contournement) ;
/// - ventes hors plage horaire d'ouverture habituelle ;
/// - montant largement supérieur à la moyenne des autres ventes de la
///   session (`> 3x` la moyenne, hors valeurs aberrantes triviales).
///
/// Pure : aucune dépendance à l'heure système, paramètres fournis par
/// l'appelant. Retourne la liste des signaux détectés (vide si rien
/// d'anormal).
List<FraudSignal> detectFraudSignals(
  List<FraudSaleSample> sales, {
  double approvalThresholdPercent = 10,
  int openingHour = 7,
  int closingHour = 21,
}) {
  final signals = <FraudSignal>[];
  if (sales.isEmpty) return signals;

  final justUnderThreshold = sales
      .where(
        (s) =>
            s.discountPercent > 0 &&
            s.discountPercent <= approvalThresholdPercent &&
            s.discountPercent >= approvalThresholdPercent - 1,
      )
      .length;
  if (justUnderThreshold >= 3) {
    signals.add(
      FraudSignal(
        FraudSignalType.discountJustUnderThreshold,
        '$justUnderThreshold remises juste sous le seuil d\'approbation '
        '($approvalThresholdPercent %) : contournement possible.',
      ),
    );
  }

  final offHoursCount = sales
      .where((s) => s.soldAt.hour < openingHour || s.soldAt.hour >= closingHour)
      .length;
  if (offHoursCount > 0) {
    signals.add(
      FraudSignal(
        FraudSignalType.offHours,
        '$offHoursCount vente(s) hors plage horaire habituelle '
        '($openingHour h - $closingHour h).',
      ),
    );
  }

  if (sales.length >= 3) {
    final average =
        sales.map((s) => s.totalAmount).reduce((a, b) => a + b) /
        sales.length;
    if (average > 0) {
      final outliers = sales.where((s) => s.totalAmount > average * 3).length;
      if (outliers > 0) {
        signals.add(
          FraudSignal(
            FraudSignalType.amountOutlier,
            '$outliers vente(s) avec un montant largement supérieur à la '
            'moyenne de la session.',
          ),
        );
      }
    }
  }

  return signals;
}
