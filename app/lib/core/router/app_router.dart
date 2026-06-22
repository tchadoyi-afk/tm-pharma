import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository.dart';
import '../config/env.dart';
import '../../features/admin/roles_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/pos/pos_demo_screen.dart';
import '../../features/stock/stock_screen.dart';

/// Routeur applicatif (go_router) avec garde d'authentification.
/// En mode local (Supabase non configuré), la garde est désactivée pour
/// permettre le dev/démo sans backend.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      if (!Env.isConfigured) return null; // mode local : pas de garde
      final loggedIn = auth.isSignedIn;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/pos-demo',
        name: 'pos-demo',
        builder: (context, state) => const PosDemoScreen(),
      ),
      GoRoute(
        path: '/admin/roles',
        name: 'admin-roles',
        builder: (context, state) => const RolesScreen(),
      ),
      GoRoute(
        path: '/catalog',
        name: 'catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/stock',
        name: 'stock',
        builder: (context, state) => const StockScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});

/// Rafraîchit le routeur quand l'état d'auth change.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
