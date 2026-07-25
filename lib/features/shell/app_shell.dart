import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../models/child.dart';
import '../../providers.dart';

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

  int get _index {
    final i = appDestinations.indexWhere((d) => d.path == location);
    return i == -1 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Text(appDestinations[_index].label),
        actions: const [
          _ChildSwitcher(),
          SizedBox(width: 4),
          _AccountMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                _Rail(index: _index),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: isWide ? null : _BottomBar(index: _index),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: index,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (i) => context.go(appDestinations[i].path),
      destinations: [
        for (final d in appDestinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const primary = AppShell._primaryCount;
    // Anything past the first four lives in the overflow sheet; keep the
    // "more" tab highlighted while one of those screens is open.
    final selected = index < primary ? index : primary;
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) {
        if (i < primary) {
          context.go(appDestinations[i].path);
        } else {
          _showMore(context);
        }
      },
      destinations: [
        for (final d in appDestinations.take(primary))
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
        const NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'Ещё',
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
                title: Text(d.label),
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
      tooltip: 'Учётная запись',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) {
        if (value == 'signOut') ref.read(authRepositoryProvider).signOut();
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
        const PopupMenuItem(
          value: 'signOut',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
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
        child: Text(
          selected.name,
          style: Theme.of(context).textTheme.labelLarge,
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
            DropdownMenuItem(value: c.id, child: Text(c.name)),
        ],
      ),
    );
  }
}
