import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'invoice_models.dart';
import 'receipt_text.dart';

/// Génère un PDF étroit (58mm) imitant la mise en page d'un ticket
/// thermique — utilisé quand aucun pilote ESC/POS natif n'est branché
/// (l'imprimante thermique est alors gérée comme une imprimante système
/// classique via la boîte de dialogue d'impression).
Future<Uint8List> buildThermalTicketPdf(InvoiceData invoice) async {
  final doc = pw.Document();
  const width = PdfPageFormat(
    58 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 8,
  );
  doc.addPage(
    pw.Page(
      pageFormat: width,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final line in buildReceiptLines(invoice))
            pw.Text(line, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    ),
  );
  return doc.save();
}

/// Génère le PDF couleur d'une facture (logo pharmacie si fourni).
Future<Uint8List> buildInvoicePdf(InvoiceData invoice) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    invoice.pharmacy.legalName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (invoice.pharmacy.address != null)
                    pw.Text(invoice.pharmacy.address!),
                  if (invoice.pharmacy.phone != null)
                    pw.Text(invoice.pharmacy.phone!),
                ],
              ),
              if (invoice.pharmacy.logoBytes != null)
                pw.Image(
                  pw.MemoryImage(
                    Uint8List.fromList(invoice.pharmacy.logoBytes!),
                  ),
                  width: 80,
                  height: 80,
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Facture ${invoice.invoiceNumber}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(invoice.issuedAt.toIso8601String()),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  _cell('Produit', bold: true),
                  _cell('Qté', bold: true),
                  _cell('Prix unit.', bold: true),
                  _cell('Sous-total', bold: true),
                ],
              ),
              for (final line in invoice.lines)
                pw.TableRow(
                  children: [
                    _cell(line.productName),
                    _cell('${line.quantity}'),
                    _cell(line.unitPrice.toStringAsFixed(0)),
                    _cell(line.subtotal.toStringAsFixed(0)),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL : ${invoice.total.toStringAsFixed(0)} ${invoice.pharmacy.currency}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
  padding: const pw.EdgeInsets.all(4),
  child: pw.Text(
    text,
    style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null),
  ),
);
