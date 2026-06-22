/// Un message de la conversation avec l'assistant IA en ligne (Sprint 11).
class AssistantMessage {
  const AssistantMessage({required this.role, required this.content});

  /// 'user' ou 'assistant'.
  final String role;
  final String content;

  Map<String, Object?> toJson() => {'role': role, 'content': content};
}

/// Construit le corps de requête envoyé à la fonction Edge (fonction pure,
/// testable) : historique complet + tenant pour le contexte côté serveur.
Map<String, Object?> buildAssistantRequestBody({
  required List<AssistantMessage> history,
  required String tenantId,
}) {
  return {
    'tenant_id': tenantId,
    'messages': history.map((m) => m.toJson()).toList(),
  };
}
