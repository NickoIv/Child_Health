import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

/// The widgets a parent can place on the home screen, per requirement 2.7.
///
/// Three of the original eight are gone, and all three for the same reason —
/// «хватит повторять одну и ту же информацию на каждой вкладке». None of them
/// held a figure that was not already on screen somewhere one tap away:
///
/// - `summary` printed the name, the age and the birth date that the home
///   screen's header and the app bar both carry, plus two counts that the
///   milestones block and the diary's own «N записей» already state.
/// - `vaccinations` listed scheduled reminders filtered to vaccinations —
///   a strict subset of `upcoming`, which lists all of them, from the same
///   provider, linking to the same screen.
/// - `recentEntries` was the last four diary entries, under the home screen's
///   last three.
enum DashboardWidgetKind {
  now(Icons.bolt_outlined),
  growth(Icons.show_chart_outlined),
  illness(Icons.thermostat_outlined),
  milestones(Icons.star_outline),
  upcoming(Icons.event_outlined);

  const DashboardWidgetKind(this.icon);

  final IconData icon;

  String label(AppLocalizations l) => switch (this) {
    DashboardWidgetKind.now => l.widgetNow,
    DashboardWidgetKind.growth => l.widgetGrowth,
    DashboardWidgetKind.illness => l.widgetIllness,
    DashboardWidgetKind.milestones => l.widgetMilestones,
    DashboardWidgetKind.upcoming => l.widgetUpcoming,
  };
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
