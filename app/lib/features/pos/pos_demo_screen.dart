import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/sync/sync_service.dart';
import 'pos_repository.dart';

/// Écran de démonstration (Sprint 2) : prouve que l'on peut créer une vente
/// **hors-ligne**, stockée localement et mise en file pour la synchro.
/// Sera remplacé par la vraie caisse au Sprint 7.
class PosDemoScreen extends ConsumerWidget {
  const PosDemoScreen({super.key});

  // Tenant de démo (en réel : fourni par l'onboarding/auth).
  static const _demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ready = ref.watch(syncServiceProvider).isReady;
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.posDemoTitle)),
      body: !ready
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.localDbNotInitializedAndroidWeb,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<int>(
                        stream: ref
                            .read(posRepositoryProvider)
                            .watchLocalSaleCount(),
                        builder: (context, snap) {
                          final count = snap.data ?? 0;
                          return Column(
                            children: [
                              Text(
                                '$count',
                                style: theme.textTheme.displayMedium,
                              ),
                              Text(
                                s.salesInLocalDb,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        icon: const Icon(Icons.point_of_sale),
                        label: Text(s.createTestSale),
                        onPressed: () async {
                          await ref
                              .read(posRepositoryProvider)
                              .createDemoSale(tenantId: _demoTenantId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  s.saleRecordedLocallyQueued,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.offlineWorksHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
