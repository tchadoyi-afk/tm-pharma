/// Ligne d'une facture/ticket (produit, quantité, prix unitaire).
class InvoiceLine {
  const InvoiceLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productName;
  final int quantity;
  final double unitPrice;

  double get subtotal => unitPrice * quantity;
}

/// Identité légale minimale de la pharmacie, imprimée sur ticket/facture.
class PharmacyInfo {
  const PharmacyInfo({
    required this.legalName,
    this.currency = 'XOF',
    this.address,
    this.phone,
    this.logoBytes,
  });

  final String legalName;
  final String currency;
  final String? address;
  final String? phone;
  final List<int>? logoBytes;
}

/// Contenu complet d'une facture (numéro, lignes, total, identité).
class InvoiceData {
  const InvoiceData({
    required this.invoiceNumber,
    required this.issuedAt,
    required this.lines,
    required this.pharmacy,
  });

  final String invoiceNumber;
  final DateTime issuedAt;
  final List<InvoiceLine> lines;
  final PharmacyInfo pharmacy;

  double get total => lines.fold(0, (sum, l) => sum + l.subtotal);
}
