import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/article_screen.dart';
import '../../features/assistant/assistant_screen.dart';
import '../../features/assistant/chat_screen.dart';
import '../../features/assistant/triage_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/children/children_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/diary/diary_screen.dart';
import '../../features/growth/growth_screen.dart';
import '../../features/illness/illness_screen.dart';
import '../../features/medical/medical_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../providers.dart';

/// One destination of the primary navigation.
class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}

const appDestinations = <AppDestination>[
  AppDestination(
    path: '/',
    label: 'Обзор',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    builder: DashboardScreen.new,
  ),
  AppDestination(
    path: '/assistant',
    label: 'Помощник',
    icon: Icons.lightbulb_outline,
    selectedIcon: Icons.lightbulb,
    builder: AssistantScreen.new,
  ),
  AppDestination(
    path: '/diary',
    label: 'Дневник',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
    builder: DiaryScreen.new,
  ),
  AppDestination(
    path: '/growth',
    label: 'Развитие',
    icon: Icons.show_chart_outlined,
    selectedIcon: Icons.show_chart,
    builder: GrowthScreen.new,
  ),
  AppDestination(
    path: '/illness',
    label: 'Болезни',
    icon: Icons.thermostat_outlined,
    selectedIcon: Icons.thermostat,
    builder: IllnessScreen.new,
  ),
  AppDestination(
    path: '/medical',
    label: 'Медкарта',
    icon: Icons.medical_information_outlined,
    selectedIcon: Icons.medical_information,
    builder: MedicalScreen.new,
  ),
  AppDestination(
    path: '/reminders',
    label: 'Напоминания',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    builder: RemindersScreen.new,
  ),
  AppDestination(
    path: '/children',
    label: 'Дети',
    icon: Icons.family_restroom_outlined,
    selectedIcon: Icons.family_restroom,
    builder: ChildrenScreen.new,
  ),
];

const loginPath = '/login';

final _assistantRoutes = <RouteBase>[
  GoRoute(
    path: 'chat',
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: ChatScreen()),
  ),
  GoRoute(
    path: 'triage',
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: TriageScreen()),
  ),
  GoRoute(
    path: 'article/:id',
    pageBuilder: (context, state) => NoTransitionPage(
      child: ArticleScreen(articleId: state.pathParameters['id'] ?? ''),
    ),
  ),
];

/// Router rebuilt against the current auth repository.
///
/// The redirect is the only gate on the app: every destination below is
/// unreachable while signed out, and `/login` is unreachable once signed in.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = _AuthRefresh(auth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final atLogin = state.matchedLocation == loginPath;
      if (!signedIn) return atLogin ? null : loginPath;
      return atLogin ? '/' : null;
    },
    routes: [
      GoRoute(
        path: loginPath,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          for (final d in appDestinations)
            GoRoute(
              path: d.path,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: d.builder()),
              // Detail views live under their section so the browser URL
              // stays meaningful and shareable.
              routes: d.path == '/assistant' ? _assistantRoutes : const [],
            ),
        ],
      ),
    ],
  );
});

/// Bridges the auth stream to the [Listenable] go_router expects, so a sign-in
/// or sign-out re-runs the redirect.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<Object?> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
