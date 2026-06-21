import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_providers.dart';
import 'core/i18n/strings.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Base locale offline-first : toujours ouverte. La synchro réseau s'active
  // si l'environnement est configuré (sinon mode local pur, sans crash).
  final sync = SyncService();
  try {
    await sync.initialize();
  } catch (e) {
    debugPrint('Initialisation sync ignorée (mode dégradé) : $e');
  }

  runApp(
    ProviderScope(
      overrides: [syncServiceProvider.overrideWithValue(sync)],
      child: const TmPharmaApp(),
    ),
  );
}

class TmPharmaApp extends ConsumerWidget {
  const TmPharmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TM Pharma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: Strings.supportedLocales,
      localizationsDelegates: const [
        StringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
