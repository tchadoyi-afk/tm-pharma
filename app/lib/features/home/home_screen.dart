import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_providers.dart';
import '../../core/i18n/strings.dart';
import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';

/// Écran d'accueil temporaire — vérifie que le socle (thème, i18n, état) tourne.
/// Sera remplacé par l'écran d'authentification (Sprint 3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.appName)),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.local_pharmacy_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.welcome,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${s.sprint1} · ${s.tagline}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sélecteur de langue.
                  Text(s.language, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'fr', label: Text('Français')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {locale.languageCode},
                    onSelectionChanged: (sel) => ref
                        .read(localeProvider.notifier)
                        .set(Locale(sel.first)),
                  ),
                  const SizedBox(height: 24),

                  // Sélecteur de thème.
                  Text(s.theme, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (sel) =>
                        ref.read(themeModeProvider.notifier).set(sel.first),
                  ),
                  const SizedBox(height: 32),
                  PermissionGate(
                    permission: Permissions.stockView,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.dashboard_outlined),
                      label: const Text('Tableau de bord'),
                      onPressed: () => context.go('/dashboard'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.posSell,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('Caisse'),
                      onPressed: () => context.go('/pos'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Démo vente offline'),
                    onPressed: () => context.go('/pos-demo'),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.stockView,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.medication_outlined),
                      label: const Text('Catalogue produits'),
                      onPressed: () => context.go('/catalog'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.stockView,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Stocks'),
                      onPressed: () => context.go('/stock'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.stockView,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Fournisseurs'),
                      onPressed: () => context.go('/suppliers'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.settingsManage,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Text('Assistant d\'onboarding'),
                      onPressed: () => context.go('/onboarding'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.userManage,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Permissions & rôles'),
                      onPressed: () => context.go('/admin/roles'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.stockAdjust,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Péremptions & sorties'),
                      onPressed: () => context.go('/lifecycle'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.priceEdit,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.local_offer_outlined),
                      label: const Text('Promotions'),
                      onPressed: () => context.go('/promotions'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.purchaseOrder,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Suggestions de réappro'),
                      onPressed: () => context.go('/reorder'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.auditViewOwn,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.history_outlined),
                      label: const Text('Journal d\'audit'),
                      onPressed: () => context.go('/audit'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PermissionGate(
                    permission: Permissions.aiAssistantUse,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Assistant IA'),
                      onPressed: () => context.go('/assistant'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
