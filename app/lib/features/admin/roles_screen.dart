import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
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
    final modules = <String>{
      for (final p in permissionCatalog) p.module,
    }.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions & rôles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Rôles', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _RolesSection(),
          const Divider(height: 32),
          Text('Permissions disponibles', style: theme.textTheme.titleMedium),
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
    if (!Env.isConfigured) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Mode local'),
          subtitle: Text(
            'La création de rôles et l\'assignation des permissions seront '
            'actives une fois Supabase configuré.',
          ),
        ),
      );
    }
    final roles = ref.watch(rolesProvider);
    return roles.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur : $e'),
      data: (list) => list.isEmpty
          ? const Text('Aucun rôle pour le moment.')
          : Column(
              children: [
                for (final r in list)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(r.name),
                      subtitle: r.isSystem ? const Text('Rôle système') : null,
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
    return Card(
      child: ExpansionTile(
        title: Text(module),
        subtitle: Text('${permissions.length} permission(s)'),
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
