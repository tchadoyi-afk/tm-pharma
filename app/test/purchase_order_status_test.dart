import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/reorder/purchase_order_status.dart';

void main() {
  group('allowedNextStatuses', () {
    test('DRAFT peut être envoyé ou annulé', () {
      expect(allowedNextStatuses('DRAFT'), ['SENT', 'CANCELLED']);
    });

    test('SENT peut être confirmé ou annulé', () {
      expect(allowedNextStatuses('SENT'), ['CONFIRMED', 'CANCELLED']);
    });

    test('CONFIRMED peut être reçu partiellement ou intégralement', () {
      expect(allowedNextStatuses('CONFIRMED'), [
        'PARTIALLY_RECEIVED',
        'RECEIVED',
      ]);
    });

    test('PARTIALLY_RECEIVED ne peut plus que finir reçu', () {
      expect(allowedNextStatuses('PARTIALLY_RECEIVED'), ['RECEIVED']);
    });

    test('les statuts terminaux n\'ont aucune transition', () {
      expect(allowedNextStatuses('RECEIVED'), isEmpty);
      expect(allowedNextStatuses('CANCELLED'), isEmpty);
    });

    test('un statut inconnu n\'a aucune transition', () {
      expect(allowedNextStatuses('UNKNOWN'), isEmpty);
    });
  });

  group('canTransition', () {
    test('autorise les transitions valides', () {
      expect(canTransition('DRAFT', 'SENT'), isTrue);
      expect(canTransition('SENT', 'CONFIRMED'), isTrue);
      expect(canTransition('CONFIRMED', 'PARTIALLY_RECEIVED'), isTrue);
      expect(canTransition('CONFIRMED', 'RECEIVED'), isTrue);
      expect(canTransition('PARTIALLY_RECEIVED', 'RECEIVED'), isTrue);
    });

    test('rejette les transitions invalides', () {
      expect(canTransition('DRAFT', 'RECEIVED'), isFalse);
      expect(canTransition('DRAFT', 'CONFIRMED'), isFalse);
      expect(canTransition('RECEIVED', 'SENT'), isFalse);
      expect(canTransition('CANCELLED', 'DRAFT'), isFalse);
      expect(canTransition('PARTIALLY_RECEIVED', 'CONFIRMED'), isFalse);
    });

    test('rejette toute transition depuis un statut terminal', () {
      for (final status in purchaseOrderStatuses) {
        if (isTerminalStatus(status)) {
          for (final other in purchaseOrderStatuses) {
            expect(canTransition(status, other), isFalse);
          }
        }
      }
    });
  });

  group('isTerminalStatus', () {
    test('RECEIVED et CANCELLED sont terminaux', () {
      expect(isTerminalStatus('RECEIVED'), isTrue);
      expect(isTerminalStatus('CANCELLED'), isTrue);
    });

    test('les autres statuts ne sont pas terminaux', () {
      expect(isTerminalStatus('DRAFT'), isFalse);
      expect(isTerminalStatus('SENT'), isFalse);
      expect(isTerminalStatus('CONFIRMED'), isFalse);
      expect(isTerminalStatus('PARTIALLY_RECEIVED'), isFalse);
    });
  });
}
