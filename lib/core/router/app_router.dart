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
import '../../features/family/family_screen.dart';
import '../../features/family/join_screen.dart';
import '../../features/growth/growth_screen.dart';
import '../../features/illness/illness_screen.dart';
import '../../features/medical/medical_screen.dart';
import '../../features/medical/visit_prep_screen.dart';
import '../../features/photos/photos_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// The shelf a destination sits on once it is behind «Ещё».
///
/// Six destinations in one flat list is six labels to read, and a parent
/// looking for the vaccination calendar had to read all six to find out that
/// it is called «Напоминания». Sorted onto three shelves she reads one word —
/// the one that says which kind of thing she is after — and then two options
/// instead of six.
enum NavGroup { health, memory, profile }

/// One destination of the primary navigation.
class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
    this.hint,
    this.group,
  });

  final String path;

  /// Resolved against the chosen language rather than stored, so switching
  /// language relabels the navigation without rebuilding this list.
  final String Function(AppLocalizations) label;

  /// The line under the name in the «Ещё» sheet, saying what is on the screen
  /// rather than what it is called. Null for the four that live in the bar,
  /// where there is no room for it and no list to scan.
  final String Function(AppLocalizations)? hint;

  /// Null for the primary four, which are not in the sheet at all.
  final NavGroup? group;

  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}

/// The assistant, as a window of its own.
///
/// Outside the shell on purpose. «ИИ должен открываться в новом окне, так
/// диалог удобнее» — and a conversation is the one thing in this app that is
/// not a tab: it opens over whatever you were doing, keeps the thread, and
/// closes back onto it. Inside the shell it also had a tab bar under it,
/// which is a row of ways to lose the conversation.
const chatPath = '/chat';

/// Preparation for an appointment. A destination like any other, but linked
/// to from the medical card as well, because that is where a parent goes
/// looking the evening before.
const visitPath = '/visit';

final appDestinations = <AppDestination>[
  AppDestination(
    path: '/',
    label: (l) => l.navDashboard,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    builder: DashboardScreen.new,
  ),
  AppDestination(
    path: '/diary',
    label: (l) => l.navDiary,
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
    builder: DiaryScreen.new,
  ),
  AppDestination(
    path: '/assistant',
    label: (l) => l.navAssistant,
    icon: Icons.lightbulb_outline,
    selectedIcon: Icons.lightbulb,
    builder: AssistantScreen.new,
  ),
  AppDestination(
    path: '/family',
    label: (l) => l.navFamily,
    icon: Icons.diversity_1_outlined,
    selectedIcon: Icons.diversity_1,
    builder: FamilyScreen.new,
  ),
  AppDestination(
    path: '/growth',
    label: (l) => l.navGrowth,
    hint: (l) => l.navGrowthHint,
    group: NavGroup.health,
    icon: Icons.show_chart_outlined,
    selectedIcon: Icons.show_chart,
    builder: GrowthScreen.new,
  ),
  AppDestination(
    path: '/illness',
    label: (l) => l.navIllness,
    hint: (l) => l.navIllnessHint,
    group: NavGroup.health,
    icon: Icons.thermostat_outlined,
    selectedIcon: Icons.thermostat,
    builder: IllnessScreen.new,
  ),
  AppDestination(
    path: '/medical',
    label: (l) => l.navMedical,
    hint: (l) => l.navMedicalHint,
    group: NavGroup.health,
    icon: Icons.medical_information_outlined,
    selectedIcon: Icons.medical_information,
    builder: MedicalScreen.new,
  ),
  AppDestination(
    path: visitPath,
    label: (l) => l.navVisit,
    hint: (l) => l.navVisitHint,
    group: NavGroup.health,
    icon: Icons.event_available_outlined,
    selectedIcon: Icons.event_available,
    builder: VisitPrepScreen.new,
  ),
  AppDestination(
    path: '/reminders',
    label: (l) => l.navReminders,
    hint: (l) => l.navRemindersHint,
    group: NavGroup.health,
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    builder: RemindersScreen.new,
  ),
  AppDestination(
    path: '/photos',
    label: (l) => l.navPhotos,
    hint: (l) => l.navPhotosHint,
    group: NavGroup.memory,
    icon: Icons.photo_library_outlined,
    selectedIcon: Icons.photo_library,
    builder: PhotosScreen.new,
  ),
  AppDestination(
    path: '/children',
    label: (l) => l.navChildren,
    hint: (l) => l.navChildrenHint,
    group: NavGroup.profile,
    icon: Icons.family_restroom_outlined,
    selectedIcon: Icons.family_restroom,
    builder: ChildrenScreen.new,
  ),
];

const loginPath = '/login';
const settingsPath = '/settings';

/// Where an invitation link lands: `/join/{code}`.
///
/// Outside the shell, like the chat, because whoever opens it has no tabs to
/// go to yet — they are not in the family until they press the button.
const joinPath = '/join';

final _assistantRoutes = <RouteBase>[
  GoRoute(
    path: 'chat',
    // The chat moved out of the shell and into a window of its own — see
    // [chatPath]. This is the old address, kept working: it is in his browser
    // history, and it is what the search field used to link to.
    redirect: (context, state) {
      final q = state.uri.queryParameters['q'];
      return q == null
          ? chatPath
          : '$chatPath?q=${Uri.encodeQueryComponent(q)}';
    },
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
      if (!signedIn) {
        if (atLogin) return null;
        // Where he was going, carried through the sign-in. Without this an
        // invitation link sent to somebody who has never opened the app puts
        // him on the home screen of an empty account, with the code gone from
        // the address bar and nothing to say what he was invited to.
        final wanted = state.uri.toString();
        return wanted == '/'
            ? loginPath
            : '$loginPath?next=${Uri.encodeQueryComponent(wanted)}';
      }
      if (atLogin) return _safeNext(state.uri.queryParameters['next']);
      return null;
    },
    routes: [
      GoRoute(
        path: loginPath,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '$joinPath/:code',
        pageBuilder: (context, state) => MaterialPage(
          child: JoinScreen(code: state.pathParameters['code'] ?? ''),
        ),
      ),
      // Above the shell, not inside it: no tab bar under a conversation.
      GoRoute(
        path: chatPath,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: ChatScreen(initialQuestion: state.uri.queryParameters['q']),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          // Not a navigation destination: reached from the account menu, and
          // adding an eighth tab for something opened twice a year would cost
          // more than it gives.
          GoRoute(
            path: settingsPath,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
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

/// An address inside this app, or the home screen.
///
/// `next` comes off the URL, which is to say from whoever sent the link. A
/// bare `startsWith('/')` is not enough: `//example.com` also starts with a
/// slash and is a perfectly good address for somewhere else entirely, which
/// would turn the sign-in screen into an open redirect.
String _safeNext(String? next) {
  if (next == null || !next.startsWith('/') || next.startsWith('//')) {
    return '/';
  }
  return next;
}

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
