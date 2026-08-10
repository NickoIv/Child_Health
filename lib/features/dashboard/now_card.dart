import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/daily_care.dart';
import '../../core/care/greeting.dart';
import '../../core/care/noticing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../core/l10n/labels.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../family/invite_banner.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';
import 'focus_home.dart';
import 'night_sleep_sheet.dart';
import 'quick_log_sheet.dart';

/// The at-a-glance card: what is going on with this child right now, and the
/// three things a parent most often needs to do about it.
///
/// Designed for one hand and a short attention span. Everything is a large
/// tap target, nothing needs reading to act on, and the quick actions sit
/// below the summary where a thumb reaches.
class NowCard extends ConsumerWidget {
  const NowCard({required this.child, super.key});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];

    final today = dateOnly(now);
    final sickToday = logs.any(
      (l) => l.type == LogType.illness && dateOnly(l.date) == today,
    );
    final lastTemperature = _lastTemperature(logs);
    final care = ref.watch(dailyCareProvider);
    final sinceFeeding = care.minutesSinceFeeding(now);
    final dueToday = reminders
        .where((r) => !r.isCompleted && dateOnly(r.scheduledTime) == today)
        .toList();

    final onGradient = AppTheme.onWelcome(theme.brightness);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // The one warm surface in the app. It greets rather than reports,
          // which is the whole reason a tired parent opens this at all — and
          // it carries the four facts she opens it to check.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            decoration: BoxDecoration(
              gradient: AppTheme.welcomeGradient(theme.brightness),
              boxShadow: AppTheme.softShadow(theme.brightness),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // The child's own face, not a generic glyph. For a parent
                    // of two this is also how she tells whose day she is
                    // looking at — so it is big enough to recognise at arm's
                    // length, which 44px was not.
                    ChildAvatar(child: child, size: 76),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // By name where she gave one. The rest of this
                            // card is about the child; this is the one line
                            // on it addressed to the person reading it.
                            greetingFor(
                              l,
                              now,
                              name: ref
                                      .watch(userProfileProvider)
                                      .value
                                      ?.displayName ??
                                  '',
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: onGradient.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // The largest thing on the screen, and the only
                          // thing on it that is nobody else's.
                          Text(
                            child.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: onGradient,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          _AgeChip(
                            label: localizedAge(l, child),
                            ink: onGradient,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusChip(
                      sickToday: sickToday,
                      temperature: lastTemperature,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PhraseOfDay(
                  now: now,
                  ink: onGradient,
                  noticed: noticedFor(child, logs, now),
                  childName: child.name,
                ),
                const SizedBox(height: 14),
                // The two questions she is asked all day, by everyone, and
                // the two she cannot answer from memory at four in the
                // morning.
                Row(
                  children: [
                    Expanded(
                      child: _ContextStat(
                        icon: Icons.water_drop_outlined,
                        label: l.nowLastFeeding,
                        value: care.lastFeedingAt == null
                            ? l.nowNothingYet
                            : timeOfDay.format(care.lastFeedingAt!),
                        detail: sinceFeeding == null
                            ? null
                            : l.nowAgo(localizedDuration(l, sinceFeeding)),
                        onGradient: onGradient,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: onGradient.withValues(alpha: 0.22),
                    ),
                    Expanded(
                      child: _ContextStat(
                        icon: Icons.bedtime_outlined,
                        label: l.nowLastSleep,
                        value: care.lastSleepAt == null
                            ? l.nowNothingYet
                            : timeOfDay.format(care.lastSleepAt!),
                        detail: care.lastSleepMinutes == null
                            ? null
                            : localizedDuration(l, care.lastSleepMinutes!),
                        onGradient: onGradient,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dueToday.isNotEmpty) ...[
                  for (final r in dueToday.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            r.type == ReminderType.vaccination
                                ? Icons.vaccines_outlined
                                : Icons.event_available_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.nowTodayReminder(
                                r.type == ReminderType.vaccination
                                    ? localizedVaccinationName(l, r.title)
                                    : r.title,
                              ),
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
                const _TodayCounts(),
                const SizedBox(height: AppTheme.gap),
                _QuickActions(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double? _lastTemperature(List<DevelopmentLog> logs) {
    // Logs arrive newest first, so the first hit is the latest reading.
    for (final l in logs) {
      final t = l.metrics.temperatureC;
      if (t != null) return t;
    }
    return null;
  }

}

/// The age, as a chip rather than a line of text.
///
/// It is the one fact on the greeting that is not about today, and reading it
/// as a caption under the name made it look like a subtitle to the name. In a
/// chip it reads as what it is: a small, changing fact about a person.
class _AgeChip extends StatelessWidget {
  const _AgeChip({required this.label, required this.ink});

  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        // A wash of the surface rather than a colour of its own: the chip has
        // to sit on a gradient that is already two colours.
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// One sentence, and it changes tomorrow.
///
/// Six of them, picked by the date rather than by a random number: a phrase
/// that changed on every rebuild would flicker as the day's entries came in,
/// and one that changed on every scroll would read as a slot machine. Picked
/// by the day, it is the same all day and different in the morning — which is
/// what "phrase of the day" has to mean to be worth having.
///
/// There is no model behind it and there never will be. These say one thing —
/// that whoever is holding the phone is doing all right — and a sentence
/// generated fresh each morning would eventually say something else.
/// The six, in the order they rotate.
List<String> phrasesOfDay(AppLocalizations l) => [
  l.phraseOfDay1,
  l.phraseOfDay2,
  l.phraseOfDay3,
  l.phraseOfDay4,
  l.phraseOfDay5,
  l.phraseOfDay6,
];

/// Which one today gets. Days since a fixed date, so it advances once a
/// night, is the same all day, and never repeats two days running.
int phraseOfDayIndex(DateTime day, int count) =>
    DateTime(day.year, day.month, day.day).difference(DateTime(2020)).inDays %
    count;

class _PhraseOfDay extends StatelessWidget {
  const _PhraseOfDay({
    required this.now,
    required this.ink,
    required this.noticed,
    required this.childName,
  });

  final DateTime now;
  final Color ink;

  /// Something true about today, where there was something. It always wins:
  /// a fact about this child beats a sentence written for every child.
  final Noticed? noticed;

  final String childName;

  @override
  Widget build(BuildContext context) {
    // Silent at night, like everything else that is only pleasant to read.
    // [noticedFor] already refuses after nine; the rotation has to be told.
    if (isNightAt(now)) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final phrases = phrasesOfDay(l);
    final index = phraseOfDayIndex(now, phrases.length);

    final text = noticed == null
        ? phrases[index]
        : noticedText(l, noticed!, childName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          // A different glyph for a different kind of sentence. The leaf is
          // the phrase of the day being gentle at nobody in particular; a
          // fact about this child gets the mark the app uses for a fact.
          noticed == null ? Icons.spa_outlined : Icons.auto_awesome_outlined,
          size: 15,
          color: ink.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ink.withValues(alpha: 0.85),
              // Upright when it is a fact. The italic is the voice of the
              // phrase of the day — a fact leaning over reads as a quotation.
              fontStyle: noticed == null ? FontStyle.italic : FontStyle.normal,
              fontWeight: noticed == null ? null : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A fact on the warm surface: what it is, when it was, how long ago.
class _ContextStat extends StatelessWidget {
  const _ContextStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.onGradient,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color onGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: onGradient.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onGradient.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            detail == null ? value : '$value · $detail',
            style: theme.textTheme.titleSmall?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.sickToday, required this.temperature});

  final bool sickToday;
  final double? temperature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final fever = (temperature ?? 0) >= 38.0;
    final concerning = fever || sickToday;
    final label = temperature != null
        ? '${temperature!.toStringAsFixed(1)} °C'
        : sickToday
        ? l.statusSick
        : l.statusHealthy;

    // Sits on the gradient, so the chip is a white card and the status colour
    // is carried by the icon and the text inside it. A tinted chip on a
    // saturated background would lose the distinction entirely.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            concerning ? Icons.thermostat : Icons.favorite,
            size: 18,
            color: concerning ? StatusColors.alert : StatusColors.normal,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: concerning ? StatusColors.alert : StatusColors.normal,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            temperature != null ? l.statusLatest : l.commonToday,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's tally.
///
/// The numbers are coloured against the thresholds the knowledge base states —
/// six wet nappies, eight feeds — but only once the day is over. Telling a
/// mother at 9am that she is behind on feeds would be both wrong and cruel.
class _TodayCounts extends ConsumerWidget {
  const _TodayCounts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final care = ref.watch(dailyCareProvider);
    final now = DateTime.now();
    // "Complete" only near the end of the day; before that a low count says
    // nothing.
    final dayComplete = now.hour >= 21;

    if (care.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Warm.soft(theme.brightness),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          l.nowNoEntries,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final feedStatus = CareTargets.feedingStatus(
      care.feedings,
      dayComplete: dayComplete,
    );
    final nappyStatus = CareTargets.wetNappyStatus(
      care.wetNappies,
      dayComplete: dayComplete,
    );

    // The time since the last feed moved up into the header, where it sits
    // beside the last sleep. Repeating it here as a banner was the single
    // largest block of empty space on the screen.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A Wrap, not a Row: the fourth tally appears only once sleep has
        // been logged, and "1 ч 30 мин" pushed the row 137px off a phone
        // screen. Wrapping lets the counts reflow instead of clipping.
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            _Count(
              countTo: care.feedings,
              label: l.countFeedings,
              status: feedStatus,
            ),
            _Count(
              countTo: care.wetNappies,
              label: l.countWet,
              status: nappyStatus,
            ),
            _Count(countTo: care.dirtyNappies, label: l.countDirty),
            if (care.sleepMinutes > 0)
              _Count(
                value: localizedDuration(l, care.sleepMinutes),
                label: l.countSleep,
              ),
          ],
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    this.value,
    this.countTo,
    this.status = CareStatus.unknown,
  }) : assert(value != null || countTo != null);

  /// A reading, printed as it is. The hours of sleep come through here: a
  /// duration that counts is a figure moving while it is being read.
  final String? value;

  /// A tally, which runs to itself instead of jumping.
  ///
  /// Deliberately unkeyed. The one this is for is the moment a feed is
  /// written down and the seven on the home screen becomes an eight — it
  /// ticks over from where it was, and only the first draw of the day counts
  /// up from nothing.
  final int? countTo;

  final String label;
  final CareStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      CareStatus.onTrack => StatusColors.normal,
      CareStatus.watch => StatusColors.warning,
      CareStatus.unknown => null,
    };
    final style = theme.textTheme.titleLarge?.copyWith(color: color);

    // Sized by its content, not by a flex factor: it lives in a Wrap now.
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (countTo case final target?)
                CountUp(
                  value: target,
                  builder: (context, shown) => Text('$shown', style: style),
                )
              else
                Text(value!, style: style),
              if (status != CareStatus.unknown) ...[
                const SizedBox(width: 4),
                Icon(
                  status == CareStatus.onTrack
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 14,
                  color: color,
                ),
              ],
            ],
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // A viewer keeps the six cards and gets a padlock on each. Hiding them
    // would make a father think the app was broken; locking them tells him
    // exactly what he is looking at and whose it is to change.
    final readOnly = ref.watch(isReadOnlyProvider);

    void quick(QuickLogAction action) =>
        showQuickLogSheet(context, action: action, childId: child.id);

    // Six actions, and a tone each. Everything a parent does many times a day
    // comes first; the two that happen once come last. Any more than this and
    // the screen stops being a place to act and becomes a place to choose,
    // which at three in the morning is not the same thing.
    final buttons = <_ActionButton>[
      _ActionButton(
        icon: QuickLogAction.feeding.icon,
        label: l.quickFeed,
        caption: l.quickFeedHint,
        readOnly: readOnly,
        tone: SoftTone.peach,
        onTap: () => quick(QuickLogAction.feeding),
      ),
      _ActionButton(
        icon: QuickLogAction.nappy.icon,
        label: l.quickNappy,
        caption: l.quickNappyHint,
        readOnly: readOnly,
        tone: SoftTone.mint,
        onTap: () => quick(QuickLogAction.nappy),
      ),
      _ActionButton(
        icon: QuickLogAction.sleep.icon,
        label: l.quickSleep,
        caption: l.quickSleepHint,
        readOnly: readOnly,
        tone: SoftTone.lavender,
        onTap: () => quick(QuickLogAction.sleep),
      ),
      _ActionButton(
        icon: Icons.nightlight_outlined,
        label: l.quickNightSleep,
        caption: l.quickNightSleepHint,
        readOnly: readOnly,
        tone: SoftTone.sky,
        // A night is a shape, not a moment, so it keeps its own sheet.
        onTap: () => showNightSleepSheet(context, childId: child.id),
      ),
      _ActionButton(
        icon: QuickLogAction.temperature.icon,
        label: l.quickTemperature,
        caption: l.quickTemperatureHint,
        readOnly: readOnly,
        tone: SoftTone.rose,
        onTap: () => quick(QuickLogAction.temperature),
      ),
      _ActionButton(
        icon: Icons.forum_outlined,
        label: l.quickAssistant,
        caption: l.quickAssistantHint,
        readOnly: readOnly,
        tone: SoftTone.sand,
        onTap: () => context.go('/assistant'),
      ),
    ];

    // Three across where each card can carry its caption, two where it
    // cannot. On a phone that is two, and the pair of columns is what lets
    // these read as cards at all rather than as a keypad — a 100px column
    // fits an icon and a cropped word and nothing else.
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppTheme.gap;
        final columns =
            (constraints.maxWidth - 2 * gap) / 3 >= _ActionButton.minCardWidth
            ? 3
            : 2;
        final rows = (buttons.length / columns).ceil();

        return Column(
          children: [
            for (var row = 0; row < rows; row++) ...[
              if (row > 0) const SizedBox(height: gap),
              Row(
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    // The last row of a two-column grid can be short; an
                    // empty Expanded keeps the survivors their own width
                    // instead of stretching one across the page.
                    Expanded(
                      child: row * columns + i < buttons.length
                          ? buttons[row * columns + i]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.caption,
    required this.tone,
    required this.onTap,
    this.readOnly = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final SoftTone tone;
  final VoidCallback onTap;

  /// Dimmed and padlocked rather than removed.
  final bool readOnly;

  /// One height, one radius for all six. A grid where the cards differ by a
  /// few pixels reads as unfinished even when nobody can say why.
  static const height = 88.0;
  static const radius = 22.0;

  /// Below this a card cannot hold its caption without cropping the Kazakh
  /// label above it, and the grid drops to two columns instead.
  static const minCardWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = tone.ink(theme.brightness);

    return Pressable(
      onTap: readOnly ? null : onTap,
      borderRadius: radius,
      child: Opacity(
        // Enough to read as unavailable, not so much that it reads as broken.
        opacity: readOnly ? 0.6 : 1,
        child: Container(
          // Fixed rather than padded: a label that wraps to two lines in Kazakh
          // must not make its neighbour a different size.
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tone.fill(theme.brightness),
            borderRadius: BorderRadius.circular(radius),
          ),
          // Both lines carry their own tight leading. The theme's reading
          // heights are for paragraphs; inside 88 pixels they are what makes a
          // card overflow by exactly one descender.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: ink, size: 28),
                  if (readOnly) ...[
                    const Spacer(),
                    const ReadOnlyLock(size: 15),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11.5,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                  color: ink.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
