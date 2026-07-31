import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/active_game/presentation/pages/active_game_page.dart';
import '../../features/active_game/presentation/pages/session_lobby_page.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/my_cards/presentation/pages/my_cards_page.dart';
import '../../features/rules/presentation/pages/rules_page.dart';
import '../../features/session_history/presentation/pages/session_history_page.dart';
import '../../features/session_results/presentation/pages/session_results_page.dart';
import '../../features/session_setup/presentation/pages/join_session_page.dart';
import '../../features/session_setup/presentation/pages/session_setup_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier();
  ref.listen(
    authControllerProvider,
    (previous, next) => refreshNotifier.notify(),
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isInitializing = authState.isLoading && !authState.hasValue;
      if (isInitializing) {
        return null;
      }

      final isLoggedIn = authState.value != null;
      final goingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !goingToLogin) {
        return '/login';
      }
      if (isLoggedIn && goingToLogin) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/session-setup',
        name: 'session-setup',
        builder: (context, state) =>
            SessionSetupPage(groupId: state.extra! as String),
      ),
      GoRoute(
        path: '/join-session',
        name: 'join-session',
        builder: (context, state) => const JoinSessionPage(),
      ),
      GoRoute(
        path: '/session/:sessionId/lobby',
        name: 'session-lobby',
        builder: (context, state) =>
            SessionLobbyPage(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/session/:sessionId/play',
        name: 'session-play',
        builder: (context, state) =>
            ActiveGamePage(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/session/:sessionId/results',
        name: 'session-results',
        builder: (context, state) =>
            SessionResultsPage(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) =>
            SessionHistoryPage(groupId: state.extra! as String),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/my-cards',
        name: 'my-cards',
        builder: (context, state) => const MyCardsPage(),
      ),
      GoRoute(
        path: '/rules',
        name: 'rules',
        builder: (context, state) => const RulesPage(),
      ),
    ],
  );
});
