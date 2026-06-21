import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/pos/pos_demo_screen.dart';

/// Routeur applicatif (go_router). S'étoffera au fil des sprints
/// (auth, caisse, stocks, dashboard…).
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
  ],
);
