import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/core/rbac/approval_policy.dart';

void main() {
  group('ApprovalPolicy', () {
    const policy = ApprovalPolicy(
      maxDiscountPercent: 10,
      maxStockAdjustment: 50,
    );

    test('remise sous le seuil : pas d\'approbation', () {
      expect(
        policy.requiresApproval(ApprovalAction.discount, value: 5),
        isFalse,
      );
    });

    test('remise au-dessus du seuil : approbation', () {
      expect(
        policy.requiresApproval(ApprovalAction.discount, value: 15),
        isTrue,
      );
    });

    test('ajustement de stock : valeur absolue comparée au seuil', () {
      expect(
        policy.requiresApproval(ApprovalAction.stockAdjustment, value: -80),
        isTrue,
      );
      expect(
        policy.requiresApproval(ApprovalAction.stockAdjustment, value: 30),
        isFalse,
      );
    });

    test('changement de prix et remboursement : toujours approbation', () {
      expect(policy.requiresApproval(ApprovalAction.priceChange), isTrue);
      expect(policy.requiresApproval(ApprovalAction.refund), isTrue);
    });
  });
}
