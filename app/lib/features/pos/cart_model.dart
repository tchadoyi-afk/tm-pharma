/// Ligne du panier en cours de saisie à la caisse (avant validation vente).
class CartLine {
  const CartLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  CartLine copyWith({int? quantity}) => CartLine(
    productId: productId,
    productName: productName,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
  );
}

/// Panier de la caisse : ajout/retrait par produit, total.
class Cart {
  const Cart({this.lines = const []});

  final List<CartLine> lines;

  double get total => lines.fold(0, (sum, l) => sum + l.subtotal);
  bool get isEmpty => lines.isEmpty;

  /// Ajoute une unité du produit (nouvelle ligne ou quantité incrémentée).
  Cart addProduct({
    required String productId,
    required String productName,
    required double unitPrice,
  }) {
    final idx = lines.indexWhere((l) => l.productId == productId);
    if (idx == -1) {
      return Cart(
        lines: [
          ...lines,
          CartLine(
            productId: productId,
            productName: productName,
            unitPrice: unitPrice,
            quantity: 1,
          ),
        ],
      );
    }
    final updated = [...lines];
    updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
    return Cart(lines: updated);
  }

  /// Retire une unité ; supprime la ligne si la quantité atteint 0.
  Cart removeProduct(String productId) {
    final idx = lines.indexWhere((l) => l.productId == productId);
    if (idx == -1) return this;
    final current = lines[idx];
    if (current.quantity <= 1) {
      return Cart(lines: [...lines]..removeAt(idx));
    }
    final updated = [...lines];
    updated[idx] = current.copyWith(quantity: current.quantity - 1);
    return Cart(lines: updated);
  }

  static const empty = Cart();
}
