import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';
import 'invoice_models.dart';
import 'invoice_numbering.dart';

/// Émission de factures (numérotation séquentielle locale par tenant,
/// assemblage du contenu pour impression ticket/PDF).
class InvoiceRepository {
  InvoiceRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

  /// Crée la ligne `pharmacy_settings` par défaut si elle n'existe pas
  /// encore (mode local/démo, avant tout onboarding cloud).
  Future<void> _ensurePharmacySettings(String tenantId) async {
    final rows = await _db.getAll(
      'SELECT 1 FROM pharmacy_settings WHERE tenant_id = ?',
      [tenantId],
    );
    if (rows.isNotEmpty) return;
    await _db.execute(
      'INSERT INTO pharmacy_settings '
      '(id, tenant_id, legal_name, currency, invoice_prefix, invoice_next_number) '
      "VALUES (?, ?, 'TM Pharma', 'XOF', 'INV', 1)",
      [_uuid.v4(), tenantId],
    );
  }

  /// Émet la facture d'une vente : réserve le prochain numéro séquentiel
  /// (lecture-incrément local de `pharmacy_settings.invoice_next_number`),
  /// enregistre la facture, puis retourne son contenu prêt à imprimer.
  Future<InvoiceData> createInvoice({
    required String tenantId,
    required String saleId,
  }) async {
    await _ensurePharmacySettings(tenantId);

    final settingsRows = await _db.getAll(
      'SELECT legal_name, currency, invoice_prefix, invoice_next_number '
      'FROM pharmacy_settings WHERE tenant_id = ?',
      [tenantId],
    );
    final settings = settingsRows.first;
    final nextNumber = (settings['invoice_next_number'] as num?)?.toInt() ?? 1;
    final invoiceNumber = formatInvoiceNumber(
      prefix: (settings['invoice_prefix'] as String?) ?? 'INV',
      number: nextNumber,
    );

    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();
    final invoiceId = _uuid.v4();

    await _db.execute(
      'INSERT INTO invoices '
      '(id, tenant_id, sale_id, invoice_number, issued_at, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [invoiceId, tenantId, saleId, invoiceNumber, nowIso, nowIso, nowIso],
    );
    await _db.execute(
      'UPDATE pharmacy_settings SET invoice_next_number = invoice_next_number + 1 '
      'WHERE tenant_id = ?',
      [tenantId],
    );

    final lineRows = await _db.getAll(
      'SELECT p.name AS product_name, si.quantity AS quantity, '
      'si.unit_price AS unit_price '
      'FROM sale_items si '
      'JOIN lots l ON l.id = si.lot_id '
      'JOIN products p ON p.id = l.product_id '
      'WHERE si.sale_id = ?',
      [saleId],
    );

    return InvoiceData(
      invoiceNumber: invoiceNumber,
      issuedAt: now,
      lines: lineRows
          .map(
            (r) => InvoiceLine(
              productName: r['product_name'] as String,
              quantity: (r['quantity'] as num).toInt(),
              unitPrice: (r['unit_price'] as num).toDouble(),
            ),
          )
          .toList(),
      pharmacy: PharmacyInfo(
        legalName: (settings['legal_name'] as String?) ?? 'TM Pharma',
        currency: (settings['currency'] as String?) ?? 'XOF',
      ),
    );
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return InvoiceRepository(sync.db);
});
