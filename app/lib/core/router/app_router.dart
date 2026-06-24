import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository.dart';
import '../config/env.dart';
import '../../features/admin/pharmacy_settings_screen.dart';
import '../../features/admin/roles_screen.dart';
import '../../features/assistant/assistant_screen.dart';
import '../../features/audit/audit_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/mfa_challenge_screen.dart';
import '../../features/auth/mfa_settings_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/lifecycle/lifecycle_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/pos/pos_demo_screen.dart';
import '../../features/pos/pos_screen.dart';
import '../../features/promotions/promotions_screen.dart';
import '../../features/reorder/purchase_orders_screen.dart';
import '../../features/reorder/reorder_screen.dart';
import '../../features/stock/stock_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';

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
      final atMfaChallenge = state.matchedLocation == '/mfa-challenge';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && auth.needsMfaChallenge && !atMfaChallenge) {
        return '/mfa-challenge';
      }
      if (loggedIn && !auth.needsMfaChallenge && atMfaChallenge) return '/';
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
        path: '/mfa-challenge',
        name: 'mfa-challenge',
        builder: (context, state) => const MfaChallengeScreen(),
      ),
      GoRoute(
        path: '/security/mfa',
        name: 'security-mfa',
        builder: (context, state) => const MfaSettingsScreen(),
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
        path: '/pos',
        name: 'pos',
        builder: (context, state) => const PosScreen(),
      ),
      GoRoute(
        path: '/admin/roles',
        name: 'admin-roles',
        builder: (context, state) => const RolesScreen(),
      ),
      GoRoute(
        path: '/admin/pharmacy-settings',
        name: 'admin-pharmacy-settings',
        builder: (context, state) => const PharmacySettingsScreen(),
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
      GoRoute(
        path: '/lifecycle',
        name: 'lifecycle',
        builder: (context, state) => const LifecycleScreen(),
      ),
      GoRoute(
        path: '/promotions',
        name: 'promotions',
        builder: (context, state) => const PromotionsScreen(),
      ),
      GoRoute(
        path: '/reorder',
        name: 'reorder',
        builder: (context, state) => const ReorderScreen(),
      ),
      GoRoute(
        path: '/purchase-orders',
        name: 'purchase-orders',
        builder: (context, state) => const PurchaseOrdersScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/audit',
        name: 'audit',
        builder: (context, state) => const AuditScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        name: 'suppliers',
        builder: (context, state) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/assistant',
        name: 'assistant',
        builder: (context, state) => const AssistantScreen(
          tenantId: '00000000-0000-0000-0000-000000000001',
        ),
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
