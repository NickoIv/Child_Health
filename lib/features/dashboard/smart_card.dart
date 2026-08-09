import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/appreciation_store.dart';
import '../../core/care/check_in.dart';
import '../../core/care/check_in_store.dart';
import '../../core/care/active_timer.dart';
import '../../core/care/daily_reflection.dart';
import '../../core/care/forecast_store.dart';
import '../../core/care/sleep_forecast.dart';
import '../../core/care/heavy_day.dart';
import '../../core/care/pattern_store.dart';
import '../../core/care/patterns.dart';
import '../../core/care/reflection_store.dart';
import '../../core/care/suggestion_store.dart';
import '../../core/care/suggestions.dart';
import '../../models/development_log.dart';
import '../../models/family_member.dart';
import '../../providers.dart';
import '../family/appreciation_card.dart';
import 'check_in_card.dart';
import 'pattern_card.dart';
import 'reflection_card.dart';
import 'sleep_forecast_card.dart';
import 'suggestion_card.dart';

/// Which of the smart cards, if any, the home screen shows.
///
/// Ordered rather than stacked, and the order is a claim about the parent
/// rather than about the code. What somebody else said to her outranks a
/// question about her night; both outrank the next hour; the next hour
/// outranks a shortcut to a button already on the screen; and the two that
/// only report — the evening's tally and an observation about the week — come
/// last, because neither is time-critical and both are still in full on the
/// assistant tab.
enum SmartCardKind {
  appreciation,
  checkIn,
  sleepForecast,
  suggestion,
  reflection,
  pattern,
}

/// The one card the home screen is allowed to show.
///
/// One, and only one. Three cards competing for the space under the primary
/// actions was the single largest thing wrong with the old dashboard: each of
/// them was worth showing on its own, and all of them together read as an app
/// with something to say every time it was opened.
///
/// Everything that lost this competition is still reachable — patterns and
/// reflection live in the assistant tab now, and nothing was deleted.
class SmartCard extends ConsumerWidget {
  const SmartCard({super.key, this.now});

  /// Injectable so the windows can be tested without waiting for a morning.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = now ?? DateTime.now();
    return switch (smartCardFor(ref, moment)) {
      SmartCardKind.appreciation => AppreciationCard(now: moment),
      SmartCardKind.checkIn => CheckInCard(now: moment),
      SmartCardKind.sleepForecast => SleepForecastCard(now: moment),
      SmartCardKind.suggestion => SuggestionCard(now: moment),
      SmartCardKind.reflection => ReflectionCard(now: moment),
      SmartCardKind.pattern => PatternCard(now: moment),
      null => const SizedBox.shrink(),
    };
  }
}

/// Picks the winner, using the same pure predicates the cards use themselves.
///
/// Asking the predicates rather than building all three and hiding two is what
/// keeps this to one rebuild: a stack of self-hiding cards costs three
/// subtrees on every log that lands.
SmartCardKind? smartCardFor(WidgetRef ref, DateTime now) {
  final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
  final readOnly = ref.watch(isReadOnlyProvider);

  if (!readOnly && !ref.watch(appreciationStoreProvider.notifier).seenOn(now)) {
    final thanked = (ref.watch(familyMembersProvider).value ?? const [])
        .any((m) => m.role == FamilyRole.viewer && m.thankedOnDay(now));
    if (thanked || wasHeavyDay(logs, now)) return SmartCardKind.appreciation;
  }

  final checkIn = ref.watch(checkInStoreProvider);
  if (checkInDue(logs, now, shownDay: checkIn?.day)) {
    return SmartCardKind.checkIn;
  }

  // The only card here about the next hour rather than the last one, so it
  // outranks everything that is merely useful. It is narrow by construction —
  // an awake child under three, inside three quarters of an hour of the end of
  // his wake window — so it displaces the others rarely.
  final dismissedUntil = ref.watch(forecastStoreProvider);
  if (dismissedUntil == null || !now.isBefore(dismissedUntil)) {
    final child = ref.watch(selectedChildProvider);
    final forecast = child == null
        ? null
        : sleepForecastFor(
            logs,
            now,
            ageMonths: child.ageInMonths,
            asleep: ref.watch(activeTimerProvider)?.kind == TimerKind.sleep,
          );
    if (forecast != null) return SmartCardKind.sleepForecast;
  }

  final suggestion = suggestionFor(
    logs,
    now,
    dismissedUntil: ref.watch(suggestionStoreProvider),
  );
  if (suggestion != null) return SmartCardKind.suggestion;

  final reflection = reflectionFor(
    logs,
    now,
    dismissedDay: ref.watch(reflectionStoreProvider),
  );
  if (reflection != null) return SmartCardKind.reflection;

  final pattern = patternFor(
    logs,
    now,
    dismissedDay: ref.watch(patternStoreProvider),
  );
  return pattern == null ? null : SmartCardKind.pattern;
}
