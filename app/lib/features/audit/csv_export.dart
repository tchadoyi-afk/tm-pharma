import 'audit_models.dart';

/// Échappe une cellule CSV (RFC 4180 minimal — guillemets doublés).
String _csvCell(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Construit un export CSV du journal d'audit (fonction pure, testable).
/// Utilisé sous l'habilitation `trace.export`.
String buildAuditCsv(List<AuditEntry> entries) {
  final lines = <String>[
    'created_at,action,entity,entity_id,user_id,before,after',
  ];
  for (final e in entries) {
    lines.add(
      [
        e.createdAt.toIso8601String(),
        e.action,
        e.entity ?? '',
        e.entityId ?? '',
        e.userId ?? '',
        e.before ?? '',
        e.after ?? '',
      ].map(_csvCell).join(','),
    );
  }
  return lines.join('\n');
}
