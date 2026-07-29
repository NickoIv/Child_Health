import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The widgets a parent can place on the home screen, per requirement 2.7.
enum DashboardWidgetKind {
  now('Сейчас', Icons.bolt_outlined),
  summary('Сводка о ребёнке', Icons.child_care_outlined),
  growth('Рост и вес', Icons.show_chart_outlined),
  vaccinations('Ближайшие прививки', Icons.vaccines_outlined),
  illness('Заболеваемость', Icons.thermostat_outlined),
  milestones('Вехи развития', Icons.star_outline),
  recentEntries('Последние записи', Icons.auto_stories_outlined),
  upcoming('Ближайшие события', Icons.event_outlined);

  const DashboardWidgetKind(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Which widgets are shown and in what order.
///
/// Lives in memory for now; once Firestore is connected this belongs in the
/// `users/{uid}.settings` document so the layout follows the parent across
/// devices.
class DashboardLayout extends Notifier<List<DashboardWidgetKind>> {
  @override
  List<DashboardWidgetKind> build() => List.of(DashboardWidgetKind.values);

  void toggle(DashboardWidgetKind kind) {
    state = state.contains(kind)
        ? [
            for (final k in state)
              if (k != kind) k,
          ]
        : [...state, kind];
  }

  /// Wired to [ReorderableListView.onReorderItem], which already accounts for
  /// the item being removed before reinsertion — so [newIndex] is the final
  /// position and needs no adjustment.
  void reorder(int oldIndex, int newIndex) {
    final items = List.of(state);
    items.insert(newIndex, items.removeAt(oldIndex));
    state = items;
  }

  void reset() => state = List.of(DashboardWidgetKind.values);
}

final dashboardLayoutProvider =
    NotifierProvider<DashboardLayout, List<DashboardWidgetKind>>(
      DashboardLayout.new,
    );
