import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_providers.dart';
import '../../core/i18n/strings.dart';

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
                  OutlinedButton.icon(
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Démo vente offline'),
                    onPressed: () => context.go('/pos-demo'),
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
