/// Une entrée du journal d'audit (couche B de traçabilité — Sprint 11).
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.userId,
    required this.action,
    this.entity,
    this.entityId,
    this.before,
    this.after,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String action;
  final String? entity;
  final String? entityId;
  final String? before;
  final String? after;
  final DateTime createdAt;

  factory AuditEntry.fromRow(Map<String, Object?> row) => AuditEntry(
    id: row['id'] as String,
    userId: row['user_id'] as String?,
    action: row['action'] as String,
    entity: row['entity'] as String?,
    entityId: row['entity_id'] as String?,
    before: row['before'] as String?,
    after: row['after'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
