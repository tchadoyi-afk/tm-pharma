/// Configuration d'environnement, injectée via --dart-define
/// (ou --dart-define-from-file=env.json). Aucun secret n'est commité.
///
/// Exemple :
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=POWERSYNC_URL=https://xxxx.powersync.journeyapps.com
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  // Clé publique Supabase (« publishable key », anciennement « anon key »).
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
  static const powerSyncUrl = String.fromEnvironment('POWERSYNC_URL');

  /// Vrai quand les 3 paramètres sont fournis → on peut activer la synchro.
  /// Sans config, l'app tourne en local pur (utile en dev / démo).
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty &&
      powerSyncUrl.isNotEmpty;

  // Assistant IA en ligne (étage 2 — Sprint 11). Pointe en pratique vers une
  // fonction Supabase Edge qui appelle l'API Claude côté serveur (clé jamais
  // embarquée dans l'app). Sans config, l'assistant affiche un message de
  // dégradation gracieuse au lieu d'échouer silencieusement.
  static const assistantApiUrl = String.fromEnvironment('ASSISTANT_API_URL');
  static const assistantApiKey = String.fromEnvironment('ASSISTANT_API_KEY');

  static bool get isAssistantConfigured =>
      assistantApiUrl.isNotEmpty && assistantApiKey.isNotEmpty;
}
