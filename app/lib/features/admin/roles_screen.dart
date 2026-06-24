import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/i18n/strings.dart';
import '../../core/rbac/permissions.dart';
import 'roles_repository.dart';

/// Écran « Permissions & rôles » (Sprint 3).
/// - Catalogue des permissions groupé par module (fonctionne hors-ligne).
/// - Liste des rôles de la pharmacie (quand Supabase est configuré).
/// L'édition complète (créer un rôle, cocher les permissions) sera branchée
/// une fois le backend provisionné.
class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = Strings.of(context);
    final modules = <String>{
      for (final p in permissionCatalog) p.module,
    }.toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.rolesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.roles, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _RolesSection(),
          const Divider(height: 32),
          Text(s.availablePermissions, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final module in modules)
            _ModuleCard(
              module: module,
              permissions: permissionCatalog
                  .where((p) => p.module == module)
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RolesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    if (!Env.isConfigured) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(s.localMode),
          subtitle: Text(s.localModeRolesHint),
        ),
      );
    }
    final roles = ref.watch(rolesProvider);
    return roles.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(s.errorWith(e)),
      data: (list) => list.isEmpty
          ? Text(s.noRoleYet)
          : Column(
              children: [
                for (final r in list)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(r.name),
                      subtitle: r.isSystem ? Text(s.systemRole) : null,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.permissions});
  final String module;
  final List<PermissionInfo> permissions;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Card(
      child: ExpansionTile(
        title: Text(module),
        subtitle: Text(s.permissionCount(permissions.length)),
        children: [
          for (final p in permissions)
            ListTile(
              dense: true,
              leading: const Icon(Icons.key_outlined, size: 18),
              title: Text(p.label),
              subtitle: Text(p.code),
            ),
        ],
      ),
    );
  }
}
