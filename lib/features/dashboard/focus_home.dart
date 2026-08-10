import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/care/greeting.dart';
import '../../core/care/noticing.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../family/invite_banner.dart';
import '../shared/photo_widgets.dart';
import '../reminders/reminder_sheet.dart';
import '../shared/widgets.dart';
import 'day_line.dart';
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
  /// Down from 78: the height it gave back went to the two figures under it,
  /// which are what the screen is opened to read. A face is recognised at 64
  /// as well as at 78; «два часа десять минут» is not read at 13pt as well as
  /// at 24.
  static const photoSize = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final moment = now ?? DateTime.now();
    final care = ref.watch(dailyCareProvider);
    final sinceFeeding = care.minutesSinceFeeding(moment);
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];

    // The line that only exists on the days it is true — an exact age, a night
    // that beat the month. Null on most days and always at night, which is
    // what keeps this header the mostly-empty thing it was built to be.
    final noticed = noticedFor(child, logs, moment);
    final myName = ref.watch(userProfileProvider).value?.displayName ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Warm.card(theme.brightness),
        borderRadius: BorderRadius.circular(Warm.cardRadius),
        boxShadow: Warm.shadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChildAvatar(child: child, size: photoSize),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Warm.onCard(theme.brightness),
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Age and date on one line of grey. The age used to sit on
                    // a peach chip, which made a label look like a button in
                    // the one place on the screen nothing is tappable.
                    Text(
                      '${localizedAge(l, child)} · ${dayMonth.format(moment)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Warm.onCardSoft(theme.brightness),
                        fontWeight: FontWeight.w600,
                        fontFeatures: AppTheme.tabular,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Warm.hairline(theme.brightness), height: 1),
          const SizedBox(height: 12),
          // The two figures. Before this they were a sentence in 13pt grey
          // under the name — the answer to the only question anyone asks at
          // four in the morning, set at the size of a footnote.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeaderFigure(
                  label: l.nowLastFeeding,
                  value: sinceFeeding == null
                      // Nothing to count from yet, so the slot carries the
                      // greeting — and it is the one line on this card
                      // addressed to the person holding the phone, so it uses
                      // her name.
                      ? greetingFor(l, moment, name: myName)
                      : localizedDuration(l, sinceFeeding),
                  // The greeting is a sentence, the duration is a number.
                  // Only one of the two is worth 24 points.
                  large: sinceFeeding != null,
                ),
              ),
              if (care.feedings > 0) ...[
                const SizedBox(width: 12),
                _HeaderFigure(
                  label: l.digestFeedings,
                  value: '${care.feedings}',
                  large: true,
                  alignEnd: true,
                ),
              ],
            ],
          ),
          if (noticed != null) ...[
            const SizedBox(height: 12),
            // Facts only here, never the rotation — see [DayLine
            // .phraseWhenNothing]. This header is deliberately the emptiest
            // thing in the app, and a line it earns on twelve mornings a year
            // is worth more than one it prints every day.
            DayLine(
              now: moment,
              noticed: noticed,
              childName: child.name,
              phraseWhenNothing: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// A caps label with a figure under it.
///
/// The label is the small thing and the number is the big one, which is the
/// reverse of how the header read before. What a parent is looking for is the
/// number; the label only says which number it is.
class _HeaderFigure extends StatelessWidget {
  const _HeaderFigure({
    required this.label,
    required this.value,
    this.large = true,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool large;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.microLabel(theme.brightness),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: large ? 24 : 16,
            fontWeight: large ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: large ? -0.7 : -0.1,
            height: 1.05,
            color: Warm.onCard(theme.brightness),
            fontFeatures: AppTheme.tabular,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// The icon a diary entry carries, so the preview and the timeline agree.
IconData logIcon(DevelopmentLog log) {
  if (log.isNightSleep) return Icons.nightlight_outlined;
  if (log.type == LogType.note && log.title == LogTitles.medicine) {
    return Icons.medication_outlined;
  }
  // A note about the mother rather than the child, and the one place in the
  // timeline where that is worth seeing at a glance.
  if (log.isPumping) return Icons.opacity;
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

/// The colour an entry is marked with, so a list of six can be read by its
/// left edge before any of it is read as words.
///
/// One mapping for the whole app: the dot on the home screen is the same
/// colour as the rail beside the same entry in the diary. The values come from
/// [VizPalette] in its validated order rather than from the pastels — these
/// carry meaning, and the ordering there is a colour-blindness safety
/// mechanism. Illness takes the status colour instead: in a feed of mostly
/// happy entries a sick day should read as a state, not as one more category.
Color logColor(DevelopmentLog log, Brightness brightness) => switch (log.type) {
  LogType.illness => StatusColors.alert,
  LogType.milestone => VizPalette.slot(4, brightness),
  LogType.measurement => VizPalette.slot(0, brightness),
  LogType.feeding => VizPalette.slot(2, brightness),
  LogType.nappy => VizPalette.slot(3, brightness),
  LogType.sleep => VizPalette.slot(5, brightness),
  LogType.question => VizPalette.slot(1, brightness),
  LogType.note => VizPalette.slot(6, brightness),
};

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

  static const height = 112.0;
  static const radius = Warm.cardRadius;
  static const iconSize = 21.0;

  /// The disc the icon sits on. Sized against the 112 the card is fixed at:
  /// disc, gap, title and caption have to add up to less than that.
  static const badgeSize = 40.0;
  static const titleSize = 17.0;
  static const captionSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = tone.ink(theme.brightness);

    return Pressable(
      borderRadius: radius,
      onTap: readOnly ? null : onTap,
      child: Container(
        height: height,
        // Twelve, not fourteen: disc, gap, title and caption come to 85 of
        // the 112 the card is fixed at, and fourteen left them one pixel
        // short — which a phone reports as an overflow, not as a squeeze.
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                  // On a disc of its own. Loose on the card the icon had
                  // nothing holding it and read as a watermark; the disc
                  // gives it an edge and makes the four cards scan as four
                  // buttons rather than four coloured rectangles.
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      // White rather than a darker wash of the tone. On a
                      // pastel a tinted disc is the same colour twice and the
                      // icon floats in it; a white one is a hole in the card
                      // with the glyph standing in it.
                      color: theme.brightness == Brightness.dark
                          ? ink.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: iconSize, color: ink),
                  ),
                  const Spacer(),
                  if (readOnly) const ReadOnlyLock(size: 15),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.1,
                  color: ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // One line, and it has to stay one: the tile is a fixed-height
              // grid cell, and a caption allowed to wrap overflows it by
              // eleven pixels. These four captions are short by design for
              // exactly that reason — «грудь или бутылочка» is the longest
              // there will ever be here.
              Text(
                caption,
                style: TextStyle(
                  fontSize: captionSize,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
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
    final async = ref.watch(logsProvider);
    final logs = async.value ?? const <DevelopmentLog>[];
    final recent = logs.take(limit).toList();
    // Loading and empty are not the same thing, and until now they looked
    // identical: "nothing written down yet" is a hard sentence to read on a
    // day that had eleven feeds in it, and it was showing for as long as the
    // first query took.
    final loading = async.isLoading && !async.hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // On the page, above the card, rather than printed inside it. A
        // heading drawn on the surface it names cannot mark that surface's
        // edge, which is the only thing this heading is for.
        SectionLabel(
          text: l.homeRecent,
          action: TextButton(
            onPressed: () => context.go('/diary'),
            child: Text(l.commonAll),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Warm.card(theme.brightness),
            borderRadius: BorderRadius.circular(Warm.cardRadius),
            boxShadow: Warm.shadow(theme.brightness),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading)
                for (var i = 0; i < limit; i++)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _RowSkeleton(),
                  )
              else if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Text(
                    l.homeNothingYet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Warm.onCardSoft(theme.brightness),
                    ),
                  ),
                )
              else
                for (var i = 0; i < recent.length; i++)
                  // Keyed by the entry's own id, so this runs once when
                  // something is written down and never again on the rebuilds
                  // that follow.
                  Arrival(
                    key: ValueKey(recent[i].id),
                    child: _TimelineRow(
                      entry: recent[i],
                      first: i == 0,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The shape of an entry, while the first query is still running.
///
/// The same badge and the same two lines, at the same sizes, so the list
/// does not jump when the real rows land on top of them.
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Skeleton(width: 38, height: 13, radius: 6),
        SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Skeleton(width: 130, height: 13),
            SizedBox(height: 6),
            Skeleton(width: 80, height: 11),
          ],
        ),
      ],
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
  const _TimelineRow({required this.entry, required this.first});

  final DevelopmentLog entry;

  /// The hairline goes above every row except the first. Drawn per row rather
  /// than between them so a list of three and a list of one look the same.
  final bool first;

  /// The time column. Fixed, because a column of times that starts in a
  /// different place on every row is not a column.
  static const timeWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final ink = Warm.onCard(theme.brightness);
    final soft = Warm.onCardSoft(theme.brightness);
    final detail = routineSummary(l, entry);
    final colour = logColor(entry, theme.brightness);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: Warm.hairline(theme.brightness))),
      ),
      child: Row(
        children: [
          // The time, left, in a column of its own. It used to sit inline in
          // the accent before the title, which made three entries read as
          // three sentences rather than as a list of three times.
          SizedBox(
            width: timeWidth,
            child: Text(
              timeOfDay.format(entry.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: soft,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFeatures: AppTheme.tabular,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // A dot in the type's own colour, where the orange ring
                    // used to be. Every entry had the same ring, so the ring
                    // said only "this is an entry" — which the row already
                    // said by existing.
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colour,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        localizedLogTitle(l, entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 17),
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
                size: 44,
                album: entry.photos,
              ),
            ),
        ],
      ),
    );
  }
}

/// The two things that are done from this screen but are not one of the four.
///
/// A night is entered once a day and a reminder is set when a child is ill;
/// neither earns a card in the square, and both were unreachable from here.
/// The reminder in particular had no way in at all — the planner could show
/// the vaccination calendar and nothing else, so «напомни дать лекарство
/// через четыре часа» was a thing the app could not be told.
class NightSleepLink extends ConsumerWidget {
  const NightSleepLink({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    // Side by side rather than stacked. Two full-width rows read better and
    // cost 64 px, which is exactly what pushed the recent events under the
    // fold on a 390-wide phone — and the events are the reason the screen is
    // opened when nothing is being logged.
    return Padding(
      padding: const EdgeInsets.only(top: Warm.cardGap),
      child: Row(
        children: [
          Expanded(
            child: _LinkRow(
              icon: Icons.nightlight_outlined,
              label: l.quickNightSleep,
              onTap: () => showNightSleepSheet(context, childId: childId),
            ),
          ),
          const SizedBox(width: Warm.cardGap),
          Expanded(
            child: _LinkRow(
              icon: Icons.add_alert_outlined,
              label: l.reminderAdd,
              onTap: () => showReminderSheet(context, childId: childId),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiet tile: an icon and a name.
///
/// A surface of its own rather than a text button hanging under the grid.
/// Both of these open a sheet that writes something down, and a link in
/// accent-coloured type does not look like a thing that does that.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      borderRadius: Warm.cardRadius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: Warm.card(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.cardRadius),
          boxShadow: Warm.shadow(theme.brightness),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Warm.onCardSoft(theme.brightness)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Warm.onCard(theme.brightness),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
