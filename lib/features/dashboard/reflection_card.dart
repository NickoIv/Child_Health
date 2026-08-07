import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/daily_reflection.dart';
import '../../core/care/reflection_store.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// The day added up, once, in the evening.
///
/// It reports and stops. The numbers are hers, the wording says nothing about
/// what they mean, and the second line thanks her for writing them down —
/// which is the only claim this card is entitled to make.
class ReflectionCard extends ConsumerWidget {
  const ReflectionCard({super.key, this.now});

  /// Injectable so the evening and the day boundary can be tested without
  /// waiting for either.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(selectedChildProvider) == null) {
      return const SizedBox.shrink();
    }

    final moment = now ?? DateTime.now();
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final day = reflectionFor(
      logs,
      moment,
      dismissedDay: ref.watch(reflectionStoreProvider),
    );
    if (day == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Padding(
      // The gap belongs to the card: with nothing to reflect on it takes no
      // room at all, not even a blank line.
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(text: l.reflectionTitle),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 18),
            decoration: BoxDecoration(
              // White on the warm page, like every other card in the app. The
              // lavender wash this replaces was a fifth of the page's own
              // colour laid over the page — which is to say it was the page,
              // and the day's figures were floating on nothing.
              color: Warm.card(theme.brightness),
              borderRadius: BorderRadius.circular(Warm.cardRadius),
              boxShadow: Warm.shadow(theme.brightness),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.nights_stay_outlined,
                      size: 19,
                      color: Warm.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        summaryLine(l, day),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l.suggestionDismiss,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => ref
                          .read(reflectionStoreProvider.notifier)
                          .dismiss(now: moment),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // The figures large enough to be taken in without reading:
                // this card is opened at the end of a day, by someone who has
                // no attention left to spend on a paragraph.
                Wrap(
                  spacing: 26,
                  runSpacing: 14,
                  children: [
                    _Figure(
                      value: '${day.feedings}',
                      label: l.countFeedings,
                    ),
                    if (day.sleepMinutes > 0)
                      _Figure(
                        value: localizedDuration(l, day.sleepMinutes),
                        label: l.countSleep,
                      ),
                    _Figure(
                      value: '${day.nappies}',
                      label: l.reflectionNappies,
                    ),
                    // A reading that was taken, with no verdict attached to
                    // the number.
                    if (day.hasTemperature)
                      _Figure(
                        value: Units.formatTemperature(day.temperatureC!),
                        label: l.quickSheetTemperature.toLowerCase(),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 15,
                      color: Warm.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.reflectionSupport,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Warm.onCardSoft(theme.brightness),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The day in one line, and it has to be a line somebody could have said.
///
/// It used to read «Сегодня было 1 кормлений и — сна»: an int dropped into a
/// sentence that only had a plural form, and an empty duration printed as the
/// dash [localizedDuration] returns for nothing. Both halves are now decided
/// here — the count is pluralised, and a day with no sleep recorded gets a
/// sentence that does not mention sleep.
///
/// Kept out of the widget so a test can read it without building anything.
String summaryLine(AppLocalizations l, DailyReflection day) {
  final feedings = l.reflectionFeedingsCount(day.feedings);
  return day.sleepMinutes > 0
      ? l.reflectionSummary(feedings, localizedDuration(l, day.sleepMinutes))
      : l.reflectionSummaryNoSleep(feedings);
}

/// A number over what it counts.
///
/// Stacked rather than side by side, and at the size of a heading: the figure
/// is the thing being read, and beside a caption at the same weight it was
/// simply another word in a row of words.
class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFeatures: AppTheme.tabular,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Warm.onCardSoft(theme.brightness),
          ),
        ),
      ],
    );
  }
}
