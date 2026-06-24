import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/i18n/strings.dart';
import '../../core/rbac/permissions.dart';
import '../../core/rbac/rbac_providers.dart';
import '../../core/sync/sync_service.dart';
import 'audit_models.dart';
import 'audit_repository.dart';
import 'csv_export.dart';

/// Journal d'audit consultable (Sprint 11) : `audit.view.all` voit tout le
/// tenant, `audit.view.own` se limite à ses propres actions. Export CSV
/// (presse-papier) sous `trace.export`.
class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(syncServiceProvider).isReady;
    final canViewAll = watchCan(ref, Permissions.auditViewAll);
    final canExport = watchCan(ref, Permissions.traceExport);
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;
    final scopeUserId = canViewAll ? null : currentUserId;
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.auditTitle),
        actions: [
          if (canExport)
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: s.exportCsv,
              onPressed: () => _export(context, ref, scopeUserId),
            ),
        ],
      ),
      body: !ready
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.localDbNotInitialized,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<AuditEntry>>(
              stream: ref
                  .read(auditRepositoryProvider)
                  .watchEntries(userId: scopeUserId),
              builder: (context, snap) {
                final entries = snap.data ?? const [];
                if (entries.isEmpty) {
                  return Center(child: Text(s.noActionLogged));
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: Text(e.action),
                      subtitle: Text(
                        [
                          if (e.entity != null) '${e.entity} ${e.entityId ?? ''}',
                          e.createdAt
                              .toIso8601String()
                              .substring(0, 16)
                              .replaceFirst('T', ' '),
                        ].join(' · '),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String? scopeUserId,
  ) async {
    final entries = await ref
        .read(auditRepositoryProvider)
        .watchEntries(userId: scopeUserId)
        .first;
    final csv = buildAuditCsv(entries);
    await Clipboard.setData(ClipboardData(text: csv));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).csvExportCopied)),
      );
    }
  }
}
