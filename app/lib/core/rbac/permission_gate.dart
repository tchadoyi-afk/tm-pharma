import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rbac_providers.dart';

/// Affiche [child] uniquement si l'utilisateur courant possède la [permission].
/// Sinon affiche [fallback] (rien par défaut).
///
/// L'habilitation reste appliquée côté serveur (RLS) : ce widget gère seulement
/// l'affichage — ne jamais s'y fier comme unique barrière de sécurité.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final String permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return watchCan(ref, permission) ? child : fallback;
  }
}
