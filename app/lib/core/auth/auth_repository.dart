import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Accès à l'authentification Supabase (email/mot de passe + MFA TOTP via
/// l'API `auth.mfa` de GoTrue). Tolérant quand l'environnement n'est pas
/// configuré (mode local/dev : aucune session).
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

  /// Vrai si la session courante a un facteur MFA vérifié sur le compte
  /// mais n'a pas encore atteint le niveau d'assurance aal2 (l'utilisateur
  /// doit saisir son code TOTP avant d'accéder à l'app).
  bool get needsMfaChallenge {
    if (!Env.isConfigured) return false;
    final levels = _client.auth.mfa.getAuthenticatorAssuranceLevel();
    return levels.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
        levels.nextLevel == AuthenticatorAssuranceLevels.aal2;
  }

  Future<AuthMFAListFactorsResponse> mfaListFactors() =>
      _client.auth.mfa.listFactors();

  Future<AuthMFAEnrollResponse> mfaEnrollTotp({String? friendlyName}) =>
      _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'TM Pharma',
        friendlyName: friendlyName,
      );

  Future<void> mfaChallengeAndVerify({
    required String factorId,
    required String code,
  }) => _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code);

  Future<void> mfaUnenroll(String factorId) =>
      _client.auth.mfa.unenroll(factorId);
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// État d'auth observable (déclenche les rebuilds : garde de route, RBAC…).
final authStateProvider = StreamProvider<AuthState?>((ref) {
  if (!Env.isConfigured) return Stream.value(null);
  return ref.watch(authRepositoryProvider).authStateChanges();
});
