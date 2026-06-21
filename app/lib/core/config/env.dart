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
}
