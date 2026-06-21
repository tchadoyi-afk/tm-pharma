import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// Résumé d'un rôle (pour la liste).
class RoleSummary {
  const RoleSummary({
    required this.id,
    required this.name,
    required this.isSystem,
  });
  final String id;
  final String name;
  final bool isSystem;
}

/// CRUD des rôles par pharmacie. Cloud-only (no-op gracieux en mode local).
/// L'isolation par tenant + l'habilitation `user.manage` sont garanties par la
/// RLS Postgres.
class RolesRepository {
  bool get enabled => Env.isConfigured;

  Future<List<RoleSummary>> listRoles() async {
    if (!enabled) return const [];
    final rows = await Supabase.instance.client
        .from('roles')
        .select('id, name, is_system')
        .isFilter('deleted_at', null)
        .order('name');
    return (rows as List)
        .map(
          (r) => RoleSummary(
            id: r['id'] as String,
            name: r['name'] as String,
            isSystem: (r['is_system'] as bool?) ?? false,
          ),
        )
        .toList();
  }
}

final rolesRepositoryProvider = Provider<RolesRepository>(
  (ref) => RolesRepository(),
);

final rolesProvider = FutureProvider<List<RoleSummary>>(
  (ref) => ref.watch(rolesRepositoryProvider).listRoles(),
);
