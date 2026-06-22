/// Un évènement de la chronologie de traçabilité d'un lot (Sprint 11) :
/// réception, ajustement, sortie hors-vente, ou vente.
class LotTraceEvent {
  const LotTraceEvent({
    required this.at,
    required this.type,
    required this.quantityDelta,
    this.detail,
  });

  final DateTime at;
  final String type;
  final int quantityDelta;
  final String? detail;
}

/// Fusionne les mouvements de stock et les ventes d'un lot en une seule
/// chronologie triée du plus récent au plus ancien (fonction pure, testable).
List<LotTraceEvent> buildLotTraceTimeline({
  required List<Map<String, Object?>> movements,
  required List<Map<String, Object?>> saleItems,
}) {
  final events = <LotTraceEvent>[
    for (final m in movements)
      LotTraceEvent(
        at: DateTime.parse(m['created_at'] as String),
        type: m['type'] as String,
        quantityDelta: m['quantity_delta'] as int,
        detail: m['reason'] as String?,
      ),
    for (final s in saleItems)
      LotTraceEvent(
        at: DateTime.parse(s['created_at'] as String),
        type: 'SALE',
        quantityDelta: -(s['quantity'] as int),
        detail: s['sale_id'] as String?,
      ),
  ];
  events.sort((a, b) => b.at.compareTo(a.at));
  return events;
}
