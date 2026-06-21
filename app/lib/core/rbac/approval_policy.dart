import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Actions sensibles pouvant exiger une validation hiérarchique.
enum ApprovalAction { discount, stockAdjustment, priceChange, refund }

/// Décide si une action sensible nécessite l'approbation d'un supérieur.
/// Logique pure (testable hors-ligne) ; les seuils seront configurables par
/// pharmacie (table `pharmacy_settings`) dans un sprint ultérieur.
class ApprovalPolicy {
  const ApprovalPolicy({
    this.maxDiscountPercent = 10,
    this.maxStockAdjustment = 50,
  });

  /// Remise (en %) au-delà de laquelle une approbation est requise.
  final double maxDiscountPercent;

  /// Ajustement de stock (valeur absolue) au-delà duquel approbation requise.
  final int maxStockAdjustment;

  /// `value` : % pour une remise, nombre d'unités pour un ajustement.
  bool requiresApproval(ApprovalAction action, {num value = 0}) {
    switch (action) {
      case ApprovalAction.discount:
        return value > maxDiscountPercent;
      case ApprovalAction.stockAdjustment:
        return value.abs() > maxStockAdjustment;
      case ApprovalAction.priceChange:
        return true; // tout changement de prix passe par approbation
      case ApprovalAction.refund:
        return true; // tout remboursement passe par approbation
    }
  }
}

final approvalPolicyProvider = Provider<ApprovalPolicy>(
  (ref) => const ApprovalPolicy(),
);
