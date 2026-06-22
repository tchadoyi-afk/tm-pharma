import 'dart:convert';

import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Journalise une action métier dans `audit_log` (traçabilité couche B).
/// Le chaînage par hash (`prev_hash`/`hash`) est calculé côté serveur par
/// le trigger Postgres au moment de la synchro ; l'écriture locale ne
/// renseigne que ce qui est connu hors-ligne (device_ts notamment).
Future<void> writeAuditLog(
  PowerSyncDatabase db, {
  required String tenantId,
  String? userId,
  required String action,
  String? entity,
  String? entityId,
  Map<String, Object?>? before,
  Map<String, Object?>? after,
}) async {
  final now = DateTime.now().toUtc().toIso8601String();
  await db.execute(
    'INSERT INTO audit_log (id, tenant_id, user_id, action, entity, entity_id, '
    'before, after, device_ts, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      _uuid.v4(),
      tenantId,
      userId,
      action,
      entity,
      entityId,
      before == null ? null : jsonEncode(before),
      after == null ? null : jsonEncode(after),
      now,
      now,
    ],
  );
}
