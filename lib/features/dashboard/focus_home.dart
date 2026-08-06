import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../family/invite_banner.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';
import 'night_sleep_sheet.dart';
import 'quick_log_sheet.dart';

/// Who this is, and how the day is going. Four lines, no numbers to read.
///
/// The header the old dashboard had carried six facts, a phrase of the day and
/// a status chip. This carries the child, the hour and one line — everything
/// else it used to say is either on the four cards below it or a tab away, and
/// a screen opened forty times a day is worth more empty than full.
class WarmHeader extends ConsumerWidget {
  const WarmHeader({required this.child, this.now, super.key});

  final Child child;
  final DateTime? now;

  /// Big enough to be a photograph of a person rather than an avatar beside a
  /// name. It is the first thing on the screen and the only thing on it that
  /// is nobody else's.
  ///
  /// Down from 96: the age moved onto a chip of its own, and at 96 the photo
  /// pushed the name and the chip into a narrower column than either wanted.
  static const photoSize = 78.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final moment = now ?? DateTime.now();
    final care = ref.watch(dailyCareProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: Warm.card(theme.brightness),
        borderRadius: BorderRadius.circular(28),
        boxShadow: Warm.shadow(theme.brightness),
      ),
      child: Row(
        children: [
          ChildAvatar(child: child, size: photoSize),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Warm.onCard(theme.brightness),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                // On a chip rather than in grey under the name. It is the one
                // number on this screen a parent says out loud — to a nurse,
                // to a grandmother — and as a third line of soft grey it read
                // as filler between the name and the line that matters.
                _AgeChip(child: child),
                const SizedBox(height: 7),
                // One line, and it is the only line. Either the fact nobody
                // can answer from memory at four in the morning, or — before
                // there is one — the greeting for the hour.
                Text(
                  warmSubtitle(l, child, moment, care.minutesSinceFeeding(moment)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Warm.onCardSoft(theme.brightness),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How old, on a soft chip.
///
/// The colour is the peach the feeding card uses, at a weight that reads as a
/// label rather than as a button — nothing here is tappable, and a chip that
/// looks pressable in a header is a small lie told forty times a day.
class _AgeChip extends StatelessWidget {
  const _AgeChip({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: SoftTone.peach.fill(theme.brightness),
        borderRadius: BorderRadius.circular(Warm.chipRadius),
      ),
      child: Text(
        localizedAge(l, child),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: SoftTone.peach.ink(theme.brightness),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The subtitle under the age. Kept out of the widget so a test can read it.
String warmSubtitle(
  AppLocalizations l,
  Child child,
  DateTime now,
  int? sinceFeeding,
) => sinceFeeding == null
    ? greetingFor(l, now)
    : '${l.nowLastFeeding}: ${localizedDuration(l, sinceFeeding)}';

/// Morning, day, evening or night, by the clock.
String greetingFor(AppLocalizations l, DateTime now) {
  if (isNightAt(now)) return l.greetingNight;
  if (now.hour < 12) return l.greetingMorning;
  if (now.hour < 18) return l.greetingAfternoon;
  return l.greetingEvening;
}

/// The icon a diary entry carries, so the preview and the timeline agree.
IconData logIcon(DevelopmentLog log) {
  if (log.isNightSleep) return Icons.nightlight_outlined;
  if (log.type == LogType.note && log.title == LogTitles.medicine) {
    return Icons.medication_outlined;
  }
  return switch (log.type) {
    LogType.milestone => Icons.star_outline,
    LogType.measurement => Icons.straighten,
    LogType.illness => Icons.thermostat,
    LogType.feeding => Icons.water_drop_outlined,
    LogType.nappy => Icons.child_care_outlined,
    LogType.sleep => Icons.bedtime_outlined,
    LogType.question => Icons.help_outline,
    LogType.note => Icons.notes,
  };
}

/// The four things a parent records without thinking.
///
/// Four, not six. Night sleep moved inside the sleep sheet, where it was
/// always a variant of the same event, and the assistant is a tab — neither
/// was a thing to lose, and both were things standing between a thumb and the
/// feed she opened the app to write down.
class PrimaryActions extends ConsumerWidget {
  const PrimaryActions({required this.child, super.key});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // A viewer keeps the cards and gets a padlock on each. Hiding them would
    // make a father think the app was broken.
    final readOnly = ref.watch(isReadOnlyProvider);

    void quick(QuickLogAction action) =>
        showQuickLogSheet(context, action: action, childId: child.id);

    final buttons = <ActionCard>[
      ActionCard(
        icon: QuickLogAction.feeding.icon,
        label: l.quickFeed,
        caption: l.quickFeedHint,
        readOnly: readOnly,
        tone: SoftTone.peach,
        onTap: () => quick(QuickLogAction.feeding),
      ),
      ActionCard(
        icon: QuickLogAction.sleep.icon,
        label: l.quickSleep,
        caption: l.quickSleepHint,
        readOnly: readOnly,
        tone: SoftTone.sand,
        onTap: () => quick(QuickLogAction.sleep),
      ),
      ActionCard(
        icon: QuickLogAction.nappy.icon,
        label: l.quickNappy,
        caption: l.quickNappyHint,
        readOnly: readOnly,
        tone: SoftTone.mint,
        onTap: () => quick(QuickLogAction.nappy),
      ),
      ActionCard(
        icon: QuickLogAction.temperature.icon,
        label: l.quickTemperature,
        caption: l.quickTemperatureHint,
        readOnly: readOnly,
        tone: SoftTone.rose,
        onTap: () => quick(QuickLogAction.temperature),
      ),
    ];

    // Two by two, on every width. Four across looked tidy on a tablet and
    // turned the pad into a toolbar: a square of four is a shape a thumb
    // learns, and learning it is the whole value of a fixed layout.
    const gap = Warm.cardGap;
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: gap),
          Row(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: buttons[row * 2 + i]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// One primary action.
///
/// Every measurement here is fixed rather than derived: a grid where the cards
/// differ by a few pixels reads as unfinished even when nobody can say why.
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.tone,
    required this.onTap,
    this.readOnly = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String caption;
  final SoftTone tone;
  final VoidCallback onTap;

  /// Dimmed and padlocked rather than removed.
  final bool readOnly;

  static const height = 104.0;
  static const radius = 24.0;
  static const iconSize = 30.0;
  static const titleSize = 16.0;
  static const captionSize = 11.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = tone.ink(theme.brightness);

    return Pressable(
      borderRadius: radius,
      onTap: readOnly ? null : onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tone.fill(theme.brightness),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: Warm.shadow(theme.brightness),
        ),
        child: Opacity(
          opacity: readOnly ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: iconSize, color: ink),
                  const Spacer(),
                  if (readOnly) const ReadOnlyLock(size: 15),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                caption,
                style: TextStyle(
                  fontSize: captionSize,
                  color: ink.withValues(alpha: 0.75),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last three things that happened, and a way to the rest.
///
/// Three, because the question this answers is "did I already write that
/// down", and the answer to that is always in the last three. A longer list
/// is the diary, and the diary is one tap away.
class RecentPreview extends ConsumerWidget {
  const RecentPreview({super.key});

  static const limit = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final recent = logs.take(limit).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: Warm.card(theme.brightness),
        borderRadius: BorderRadius.circular(28),
        boxShadow: Warm.shadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.homeRecent,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Warm.onCard(theme.brightness),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/diary'),
                child: Text(l.commonAll),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l.homeNothingYet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Warm.onCardSoft(theme.brightness),
                ),
              ),
            )
          else
            for (var i = 0; i < recent.length; i++)
              // Keyed by the entry's own id, so this runs once when something
              // is written down and never again on the rebuilds that follow.
              Arrival(
                key: ValueKey(recent[i].id),
                child: _TimelineRow(
                  entry: recent[i],
                  last: i == recent.length - 1,
                ),
              ),
        ],
      ),
    );
  }
}

/// One event: a badge, the time, what it was, and — where there is a
/// photograph — the photograph.
///
/// The badge is a ring rather than a dot on a thread. A vertical rail made
/// three entries read as one continuing thing, which is exactly wrong: the
/// question this list answers is "did I already write *that* one down", and
/// the answer is easier to find when each entry has an edge of its own.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});

  final DevelopmentLog entry;
  final bool last;

  /// Big enough for the icon to be recognised without being read, small
  /// enough that three of them stacked stay a list and not a grid.
  static const badgeSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final ink = Warm.onCard(theme.brightness);
    final soft = Warm.onCardSoft(theme.brightness);
    final detail = routineSummary(l, entry);

    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: last ? 2 : 6),
      child: Row(
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: Warm.soft(theme.brightness),
              shape: BoxShape.circle,
              border: Border.all(
                color: Warm.accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(logIcon(entry), size: 16, color: Warm.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      timeOfDay.format(entry.date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Warm.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        localizedLogTitle(l, entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: soft),
                    ),
                  ),
              ],
            ),
          ),
          // The photograph, where there is one. It is the reason a parent
          // recognises the entry without reading it.
          if (entry.photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: PhotoThumb(
                photoId: entry.photos.first,
                size: 42,
                album: entry.photos,
              ),
            ),
        ],
      ),
    );
  }
}

/// A shortcut to the night sheet, which used to be a card of its own.
///
/// It sits under the sleep action rather than beside it: a night is entered
/// once a day, and a sixth primary card for it was costing the other five
/// their width.
class NightSleepLink extends ConsumerWidget {
  const NightSleepLink({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => showNightSleepSheet(context, childId: childId),
        icon: const Icon(Icons.nightlight_outlined, size: 18),
        label: Text(l.quickNightSleep),
      ),
    );
  }
}
