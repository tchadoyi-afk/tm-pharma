import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_repository.dart';
import '../config/env.dart';
import 'permissions.dart';

/// Permissions de l'utilisateur courant, chargées via la RPC `my_permissions`.
/// Recalculé à chaque changement d'auth. Vide hors-ligne / non connecté.
final permissionsProvider = FutureProvider<PermissionSet>((ref) async {
  // Dépend de l'état d'auth pour se rafraîchir au login/logout.
  ref.watch(authStateProvider);

  // Mode local/dev : tous les droits, pour explorer l'UI sans backend.
  // En prod c'est la RPC `my_permissions` qui fait foi.
  if (!Env.isConfigured) return PermissionSet(allPermissionCodes);
  final auth = ref.watch(authRepositoryProvider);
  if (!auth.isSignedIn) return const PermissionSet.empty();

  final result = await Supabase.instance.client.rpc('my_permissions');
  final codes = (result as List).map((e) => e as String);
  return PermissionSet(codes);
});

/// Helper synchrone : l'utilisateur a-t-il la permission ? (false si en cours
/// de chargement / non connecté).
bool watchCan(WidgetRef ref, String permission) {
  final perms = ref.watch(permissionsProvider).asData?.value;
  return perms?.can(permission) ?? false;
}
