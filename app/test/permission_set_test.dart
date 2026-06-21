import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/core/rbac/permissions.dart';

void main() {
  group('PermissionSet', () {
    test('can() reflète les permissions accordées', () {
      final perms = PermissionSet({Permissions.posSell, Permissions.stockView});
      expect(perms.can(Permissions.posSell), isTrue);
      expect(perms.can(Permissions.posRefund), isFalse);
    });

    test('canAny / canAll', () {
      final perms = PermissionSet({Permissions.posSell});
      expect(
        perms.canAny([Permissions.posSell, Permissions.posRefund]),
        isTrue,
      );
      expect(
        perms.canAll([Permissions.posSell, Permissions.posRefund]),
        isFalse,
      );
    });

    test('empty ne donne aucun droit', () {
      const perms = PermissionSet.empty();
      expect(perms.isEmpty, isTrue);
      expect(perms.can(Permissions.posSell), isFalse);
    });
  });
}
