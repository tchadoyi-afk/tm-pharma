import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import 'assistant_message.dart';

/// Assistant Claude en ligne (étage 2 IA — Sprint 11). Appelle une fonction
/// Supabase Edge configurée via `ASSISTANT_API_URL`/`ASSISTANT_API_KEY` ;
/// la clé Anthropic reste côté serveur, jamais dans l'app. Sans config
/// (cloud non provisionné), lève `AssistantNotConfiguredException` pour que
/// l'UI affiche une dégradation gracieuse plutôt qu'une erreur réseau.
class AssistantNotConfiguredException implements Exception {}

class AssistantRepository {
  Future<String> sendMessage({
    required List<AssistantMessage> history,
    required String tenantId,
  }) async {
    if (!Env.isAssistantConfigured) {
      throw AssistantNotConfiguredException();
    }
    final body = buildAssistantRequestBody(history: history, tenantId: tenantId);
    final response = await http.post(
      Uri.parse(Env.assistantApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.assistantApiKey}',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Assistant indisponible (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    return decoded['reply'] as String? ?? '';
  }
}

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepository(),
);
