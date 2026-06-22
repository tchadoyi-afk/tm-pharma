import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'invoice_models.dart';
import 'receipt_text.dart';

/// Génère les octets ESC/POS d'un ticket thermique (58mm) prêts à envoyer à
/// une imprimante (Bluetooth/USB — pilote spécifique laissé à l'intégration
/// matérielle, hors scope MVP : ce module ne produit que les octets).
Future<List<int>> buildThermalTicketBytes(InvoiceData invoice) async {
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm58, profile);
  final bytes = <int>[];

  bytes.addAll(
    generator.text(
      invoice.pharmacy.legalName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    ),
  );
  for (final line in buildReceiptLines(invoice).skip(1)) {
    bytes.addAll(generator.text(line));
  }
  bytes.addAll(generator.feed(2));
  bytes.addAll(generator.cut());
  return bytes;
}
