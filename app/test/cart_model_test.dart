import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/pos/cart_model.dart';

void main() {
  group('Cart', () {
    test('addProduct crée une ligne puis incrémente la quantité', () {
      var cart = Cart.empty;
      cart = cart.addProduct(
        productId: 'p1',
        productName: 'Paracétamol',
        unitPrice: 500,
      );
      cart = cart.addProduct(
        productId: 'p1',
        productName: 'Paracétamol',
        unitPrice: 500,
      );
      expect(cart.lines.length, 1);
      expect(cart.lines.first.quantity, 2);
      expect(cart.total, 1000);
    });

    test('removeProduct décrémente puis supprime la ligne à zéro', () {
      var cart = Cart.empty.addProduct(
        productId: 'p1',
        productName: 'Paracétamol',
        unitPrice: 500,
      );
      cart = cart.removeProduct('p1');
      expect(cart.isEmpty, isTrue);
    });

    test('removeProduct sur un produit absent ne fait rien', () {
      final cart = Cart.empty;
      expect(cart.removeProduct('inconnu').isEmpty, isTrue);
    });

    test('total additionne les sous-totaux de plusieurs lignes', () {
      var cart = Cart.empty;
      cart = cart.addProduct(productId: 'p1', productName: 'A', unitPrice: 500);
      cart = cart.addProduct(productId: 'p2', productName: 'B', unitPrice: 300);
      expect(cart.total, 800);
    });
  });
}
