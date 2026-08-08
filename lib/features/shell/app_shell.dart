import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/labels.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/glass.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme_mode.dart';
import '../../models/child.dart';
import '../../providers.dart';
import '../assistant/assistant_nav_icon.dart';
import '../family/invite_banner.dart';
import '../shared/photo_widgets.dart';

/// Navigation chrome shared by every screen.
///
/// Below 900 px the destinations collapse into a bottom bar with the four
/// most-used entries plus an overflow sheet; above it they become a rail,
/// which is what a browser window usually gets.
class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const _primaryCount = 4;

  /// Index of the destination the current location belongs to.
  ///
  /// Detail routes nest under their section (`/assistant/article/fever`), so
  /// an exact match is not enough — the longest matching prefix wins, and the
  /// root path is compared exactly so it does not swallow everything.
  int get _index {
    final exact = appDestinations.indexWhere((d) => d.path == location);
    if (exact != -1) return exact;

    var best = 0;
    var bestLength = 0;
    for (var i = 0; i < appDestinations.length; i++) {
      final path = appDestinations[i].path;
      if (path == '/') continue;
      if (location.startsWith('$path/') && path.length > bestLength) {
        best = i;
        bestLength = path.length;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      // The page runs to the bottom of the screen and the tab bar is laid over
      // it — which is the only arrangement in which frosting the bar means
      // anything. [PageBody] takes the bar's height back as padding, so
      // nothing ends up permanently underneath it.
      extendBody: !isWide,
      appBar: AppBar(
        title: Text(appDestinations[_index].label(AppLocalizations.of(context))),
        actions: const [
          RoleChip(),
          SizedBox(width: 8),
          _ChildSwitcher(),
          SizedBox(width: 4),
          _AccountMenu(),
          SizedBox(width: 8),
        ],
      ),
      // Tabs are siblings, not a stack: they cross-fade with a few pixels of
      // travel rather than sliding in from the side, which would imitate a
      // navigation that did not happen.
      body: isWide
          ? Row(
              children: [
                _Rail(index: _index, location: location),
                const VerticalDivider(width: 1),
                Expanded(child: TabSwitch(index: _index, child: child)),
              ],
            )
          : TabSwitch(index: _index, child: child),
      // The tab bar, and nothing above it.
      //
      // A dictation card used to be pinned here on the home screen: a field,
      // a microphone and a line of instructions, on top of every other screen
      // the parent might be reading. «Убери микрофон и отдай эти функции ИИ» —
      // it is one field now, and it is the assistant's, which is the input
      // that can both write «покормила левой 15 минут» down and answer
      // «сколько он должен есть». Two inputs meant deciding which one you
      // wanted before you started talking.
      bottomNavigationBar: isWide
          ? null
          : GlassPanel(child: _BottomBar(index: _index, location: location)),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.index, required this.location});

  final int index;
  final String location;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: index,
      labelType: NavigationRailLabelType.all,
      // Narrower than the default 80: on a laptop the rail is a way to move
      // between screens, not a feature of the design, and every pixel it
      // gives back goes to the content.
      minWidth: 68,
      groupAlignment: -0.9,
      selectedLabelTextStyle: Theme.of(context).textTheme.labelSmall,
      unselectedLabelTextStyle: Theme.of(context).textTheme.labelSmall,
      // The assistant is the last entry here too, and it opens rather than
      // navigates — see [_BottomBar]. Not wrapped in an [Expanded] to push it
      // to the floor: `trailing` is not laid out in a flex, and doing so
      // throws a parent-data assertion and then overflows by a hundred
      // thousand pixels.
      trailing: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: IconButton(
          tooltip: AppLocalizations.of(context).navAsk,
          onPressed: () => context.push(chatPath),
          icon: AssistantNavIcon(trigger: location),
        ),
      ),
      onDestinationSelected: (i) => context.go(appDestinations[i].path),
      destinations: [
        for (var i = 0; i < appDestinations.length; i++)
          NavigationRailDestination(
            icon: NavIcon(
              icon: appDestinations[i].icon,
              selected: index == i,
            ),
            selectedIcon: NavIcon(
              icon: appDestinations[i].selectedIcon,
              selected: index == i,
            ),
            label: Text(appDestinations[i].label(AppLocalizations.of(context))),
          ),
      ],
    );
  }
}

/// The tabs, and one thing that is not a tab.
///
/// The assistant sits last, which on a phone held in the right hand is where
/// the thumb already is — «кнопку нужно под правую руку расположить». It is
/// drawn as an accent disc rather than an outline glyph because it does not
/// take you to a place: it opens the conversation over whatever is on screen,
/// and closing it puts you back.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.location});

  final int index;
  final String location;

  @override
  Widget build(BuildContext context) {
    const primary = AppShell._primaryCount;
    // Anything past the first four lives in the overflow sheet; keep the
    // "more" tab highlighted while one of those screens is open.
    final selected = index < primary ? index : primary;
    // Transparent here and only here: the theme paints the bar white, which is
    // exactly right on a rail and exactly wrong inside a pane of glass.
    return NavigationBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      selectedIndex: selected,
      onDestinationSelected: (i) {
        if (i < primary) {
          context.go(appDestinations[i].path);
        } else if (i == primary) {
          _showMore(context);
        } else {
          // Pushed, not gone to: the conversation opens over this screen and
          // closing it comes back here rather than to the home tab.
          context.push(chatPath);
        }
      },
      destinations: [
        for (var i = 0; i < primary; i++)
          NavigationDestination(
            // The same widget on both sides of the cross-fade, so whichever
            // of the two the bar is drawing is the one that moves.
            icon: NavIcon(
              icon: appDestinations[i].icon,
              selected: selected == i,
            ),
            selectedIcon: NavIcon(
              icon: appDestinations[i].selectedIcon,
              selected: selected == i,
            ),
            label: appDestinations[i].label(AppLocalizations.of(context)),
          ),
        NavigationDestination(
          icon: NavIcon(
            icon: Icons.more_horiz,
            selected: selected == primary,
          ),
          label: AppLocalizations.of(context).navMore,
        ),
        NavigationDestination(
          icon: AssistantNavIcon(trigger: location),
          label: AppLocalizations.of(context).navAsk,
        ),
      ],
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in appDestinations.skip(AppShell._primaryCount))
              ListTile(
                leading: Icon(d.icon),
                title: Text(d.label(AppLocalizations.of(context))),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(d.path);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).accountMenu,
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) {
        if (value == 'signOut') {
          ref.read(authRepositoryProvider).signOut();
          return;
        }
        if (value == 'settings') {
          context.go(settingsPath);
          return;
        }
        final theme = ThemePreference.values.firstWhere(
          (t) => t.name == value,
          orElse: () => defaultTheme,
        );
        ref.read(themePreferenceProvider.notifier).set(theme);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            user.email,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_outlined),
            title: Text(AppLocalizations.of(context).settingsTitle),
          ),
        ),
        const PopupMenuDivider(),
        for (final t in ThemePreference.values)
          CheckedPopupMenuItem(
            value: t.name,
            checked: ref.watch(themePreferenceProvider) == t,
            child: Text(t.menuLabel(AppLocalizations.of(context))),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'signOut',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.of(context).settingsSignOut),
          ),
        ),
      ],
    );
  }
}

/// Lets the parent switch between children without leaving the screen.
class _ChildSwitcher extends ConsumerWidget {
  const _ChildSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).value ?? const <Child>[];
    final selected = ref.watch(selectedChildProvider);
    if (children.isEmpty || selected == null) return const SizedBox.shrink();
    if (children.length == 1) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChildAvatar(child: selected, size: 28),
            const SizedBox(width: 8),
            Text(
              selected.name,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      );
    }
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selected.id,
        borderRadius: BorderRadius.circular(12),
        onChanged: (id) =>
            ref.read(selectedChildIdProvider.notifier).select(id),
        items: [
          for (final c in children)
            DropdownMenuItem(
              value: c.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChildAvatar(child: c, size: 28),
                  const SizedBox(width: 8),
                  Text(c.name),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
