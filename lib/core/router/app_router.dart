import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/children/children_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/diary/diary_screen.dart';
import '../../features/growth/growth_screen.dart';
import '../../features/illness/illness_screen.dart';
import '../../features/medical/medical_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/shell/app_shell.dart';

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

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        for (final d in appDestinations)
          GoRoute(
            path: d.path,
            pageBuilder: (context, state) =>
                NoTransitionPage(child: d.builder()),
          ),
      ],
    ),
  ],
);
