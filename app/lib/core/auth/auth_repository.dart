import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Accès à l'authentification Supabase (email/mot de passe + MFA géré par
/// Supabase Auth). Tolérant quand l'environnement n'est pas configuré
/// (mode local/dev : aucune session).
class AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser =>
      Env.isConfigured ? _client.auth.currentSession?.user : null;

  bool get isSignedIn => currentUser != null;

  /// Flux d'évènements d'auth (login/logout/refresh). Vide si non configuré.
  Stream<AuthState> authStateChanges() =>
      Env.isConfigured ? _client.auth.onAuthStateChange : const Stream.empty();

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!Env.isConfigured) {
      throw const AuthException(
        'Configuration Supabase requise (voir app/.env.example).',
      );
    }
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    if (Env.isConfigured) await _client.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// État d'auth observable (déclenche les rebuilds : garde de route, RBAC…).
final authStateProvider = StreamProvider<AuthState?>((ref) {
  if (!Env.isConfigured) return Stream.value(null);
  return ref.watch(authRepositoryProvider).authStateChanges();
});
