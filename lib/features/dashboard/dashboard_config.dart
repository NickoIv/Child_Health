import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

/// The widgets a parent can place on the home screen, per requirement 2.7.
enum DashboardWidgetKind {
  now(Icons.bolt_outlined),
  summary(Icons.child_care_outlined),
  growth(Icons.show_chart_outlined),
  vaccinations(Icons.vaccines_outlined),
  illness(Icons.thermostat_outlined),
  milestones(Icons.star_outline),
  recentEntries(Icons.auto_stories_outlined),
  upcoming(Icons.event_outlined);

  const DashboardWidgetKind(this.icon);

  final IconData icon;

  String label(AppLocalizations l) => switch (this) {
    DashboardWidgetKind.now => l.widgetNow,
    DashboardWidgetKind.summary => l.widgetSummary,
    DashboardWidgetKind.growth => l.widgetGrowth,
    DashboardWidgetKind.vaccinations => l.widgetVaccinations,
    DashboardWidgetKind.illness => l.widgetIllness,
    DashboardWidgetKind.milestones => l.widgetMilestones,
    DashboardWidgetKind.recentEntries => l.widgetRecent,
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
