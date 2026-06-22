import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';

import '../../core/sync/sync_service.dart';
import 'audit_models.dart';

/// Lecture du journal d'audit local (Sprint 11). La restriction
/// own/all est appliquée ici côté app (la RLS Postgres reste l'autorité
/// côté cloud — cf. `sync_rules.yaml`).
class AuditRepository {
  AuditRepository(this._db);
  final PowerSyncDatabase _db;

  Stream<List<AuditEntry>> watchEntries({String? userId}) {
    if (userId == null) {
      return _db
          .watch('SELECT * FROM audit_log ORDER BY created_at DESC')
          .map((rs) => rs.map(AuditEntry.fromRow).toList());
    }
    return _db
        .watch(
          'SELECT * FROM audit_log WHERE user_id = ? ORDER BY created_at DESC',
          parameters: [userId],
        )
        .map((rs) => rs.map(AuditEntry.fromRow).toList());
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return AuditRepository(sync.db);
});
