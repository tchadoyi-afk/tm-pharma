import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_service.dart';

/// Réglages de la pharmacie (raison sociale, devise, préfixe de facture,
/// logo) — utilisés pour le branding des factures/tickets imprimés.
class PharmacySettings {
  const PharmacySettings({
    required this.legalName,
    required this.currency,
    required this.invoicePrefix,
    this.logoPath,
  });

  final String legalName;
  final String currency;
  final String invoicePrefix;
  final String? logoPath;

  factory PharmacySettings.fromRow(Map<String, Object?> row) =>
      PharmacySettings(
        legalName: (row['legal_name'] as String?) ?? 'TM Pharma',
        currency: (row['currency'] as String?) ?? 'XOF',
        invoicePrefix: (row['invoice_prefix'] as String?) ?? 'INV',
        logoPath: row['logo_path'] as String?,
      );
}

/// CRUD des réglages pharmacie via la base locale PowerSync (offline-first,
/// une seule ligne par tenant).
class PharmacySettingsRepository {
  PharmacySettingsRepository(this._db);
  final PowerSyncDatabase _db;
  static const _uuid = Uuid();

  Stream<PharmacySettings?> watch(String tenantId) => _db
      .watch(
        'SELECT * FROM pharmacy_settings WHERE tenant_id = ?',
        parameters: [tenantId],
      )
      .map((rs) => rs.isEmpty ? null : PharmacySettings.fromRow(rs.first));

  /// Crée ou met à jour les réglages de la pharmacie (un seul enregistrement
  /// par tenant). `invoice_next_number` n'est jamais touché ici : il reste
  /// piloté par `InvoiceRepository` pour ne jamais réinitialiser le compteur.
  Future<void> upsert({
    required String tenantId,
    required String legalName,
    required String currency,
    required String invoicePrefix,
    String? logoPath,
  }) async {
    final existing = await _db.getAll(
      'SELECT id FROM pharmacy_settings WHERE tenant_id = ?',
      [tenantId],
    );
    if (existing.isEmpty) {
      await _db.execute(
        'INSERT INTO pharmacy_settings '
        '(id, tenant_id, legal_name, currency, invoice_prefix, logo_path, '
        'invoice_next_number) '
        'VALUES (?, ?, ?, ?, ?, ?, 1)',
        [_uuid.v4(), tenantId, legalName, currency, invoicePrefix, logoPath],
      );
    } else {
      await _db.execute(
        'UPDATE pharmacy_settings SET legal_name = ?, currency = ?, '
        'invoice_prefix = ?, logo_path = ? WHERE tenant_id = ?',
        [legalName, currency, invoicePrefix, logoPath, tenantId],
      );
    }
  }
}

final pharmacySettingsRepositoryProvider = Provider<PharmacySettingsRepository>(
  (ref) {
    final sync = ref.watch(syncServiceProvider);
    return PharmacySettingsRepository(sync.db);
  },
);

final pharmacySettingsStreamProvider =
    StreamProvider.family<PharmacySettings?, String>(
      (ref, tenantId) =>
          ref.watch(pharmacySettingsRepositoryProvider).watch(tenantId),
    );
