import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../children/children_screen.dart';

/// Dates and times in the language the parent chose.
///
/// These were pinned to `ru_RU` when Russian was the only language, and every
/// one of them kept speaking Russian after the interface stopped — a Kazakh
/// screen with «15 сентября» on it is the single most obvious way an app
/// admits it was translated rather than built to be translated.
///
/// [Intl.defaultLocale] is set from the chosen locale as the app builds, so
/// these read it at call time rather than at import time.
DateFormat get dayMonth => DateFormat('d MMMM', Intl.defaultLocale);
DateFormat get dayMonthYear => DateFormat('d MMMM y', Intl.defaultLocale);
DateFormat get shortDate => DateFormat('dd.MM.yyyy', Intl.defaultLocale);

/// Twenty-four hour everywhere: this is a medical record, and "3:15" without
/// am/pm is ambiguous in exactly the entries that matter most.
DateFormat get timeOfDay => DateFormat('HH:mm', Intl.defaultLocale);

/// Page padding that keeps content readable on a wide browser window instead
/// of stretching a single column across 2000 px.
class PageBody extends StatelessWidget {
  const PageBody({required this.children, this.maxWidth = 1080, super.key});

  final List<Widget> children;

  /// Screens that read as a single column — the diary timeline — set this
  /// narrower than the dashboard's grid of cards.
  final double maxWidth;

  /// Room under the last card for the floating action button, before the tab
  /// bar is accounted for.
  static const _bottomGap = 96.0;

  @override
  Widget build(BuildContext context) {
    // The shell lets the page run under the frosted tab bar, and hands the
    // bar's height back here as bottom padding. Taking the larger of the two
    // rather than adding them: on the home screen the panel carries the
    // microphone as well and is 140 px tall, and 96 on top of that would be a
    // hand's width of nothing under the last card.
    final chrome = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            chrome > _bottomGap ? chrome + 16 : _bottomGap,
          ),
          children: children,
        ),
      ),
    );
  }
}

/// The name of a block, printed on the page above it.
///
/// The heading inside a card cannot mark the card's edge — it is drawn on the
/// thing it is meant to bound. Small caps outside it can, and that is the only
/// job this has: on a scrolling page it is where one block stops and the next
/// begins.
class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.text, this.action, super.key});

  final String text;

  /// «Все», usually. Sits on the same line, in the accent, because it is the
  /// one tappable thing in a row of type.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppTheme.microLabel(brightness),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.action,
    this.accentColor,
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? action;

  /// Overrides the icon tint. Used where the card carries a status rather
  /// than an identity.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Warm.majorGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // On a phone the trailing element — a segmented control, a long
            // child name — does not fit beside the title, and Flutter
            // overflows rather than wrapping. Below 420px it moves to its own
            // line instead.
            LayoutBuilder(
              builder: (context, constraints) {
                final titleRow = Row(
                  children: [
                    if (icon != null) ...[
                      // A tinted chip rather than a bare glyph: it gives each
                      // card a recognisable identity when scrolling past.
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(
                            Warm.chipRadius,
                          ),
                        ),
                        child: Icon(icon, size: 19, color: accent),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      // The section size, not the body size. A card heading
                      // that matches the text under it makes the reader find
                      // the structure instead of being handed it.
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                  ],
                );

                if (action == null) return titleRow;

                final narrow = constraints.maxWidth < 420;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerLeft, child: action),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: titleRow),
                    const SizedBox(width: 12),
                    action!,
                  ],
                );
              },
            ),
            const SizedBox(height: Warm.cardGap),
            child,
          ],
        ),
      ),
    );
  }
}

/// Date and time of an event, as two fields side by side.
///
/// One control for both, used everywhere something is recorded, because the
/// two are always changed for the same reason: the feed happened at three in
/// the morning and is being written down at nine. Defaults to whatever the
/// caller passes, which is now for a new entry — so the common case needs no
/// taps at all.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    required this.value,
    required this.onChanged,
    this.dateLabel,
    this.timeLabel,
    this.future = false,
    super.key,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  /// Lets the calendar run forwards instead of stopping at today.
  ///
  /// Everything recorded in this app has already happened — except a
  /// reminder, which is the one thing that has not.
  final bool future;

  /// Default to the plain "Date" and "Time" of the interface language; the
  /// night sheet overrides them with "fell asleep" and "woke up".
  final String? dateLabel;
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateLabel = this.dateLabel ?? l.commonDate;
    final timeLabel = this.timeLabel ?? l.commonTime;

    final date = InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: dateLabel,
          prefixIcon: const Icon(Icons.event_outlined, size: 20),
        ),
        child: Text(
          shortDate.format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    final time = InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: timeLabel,
          prefixIcon: const Icon(Icons.schedule_outlined, size: 20),
        ),
        child: Text(
          timeOfDay.format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    // Side by side where there is room, stacked where there is not. Inside a
    // dialog on a phone the pair gets barely 250px, and two labelled fields
    // with prefix icons do not fit in that — they overflowed rather than
    // shrank, which is the one thing a form must never do.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [date, const SizedBox(height: 12), time],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: date),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: time),
          ],
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: future ? now : DateTime(now.year - 18),
      // Nothing recorded here has happened in the future — a reminder aside,
      // which is the only thing in the app that is set rather than logged.
      lastDate: future ? DateTime(now.year + 2) : now,
    );
    if (picked == null) return;
    // Only the calendar day moves; the clock time stays as it was.
    onChanged(
      DateTime(picked.year, picked.month, picked.day, value.hour, value.minute),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (picked == null) return;
    onChanged(
      DateTime(value.year, value.month, value.day, picked.hour, picked.minute),
    );
  }
}

/// Big number with a caption, used across the dashboard and the statistics.
///
/// The caption moved above the figure and into small caps. A number with a
/// grey sentence under it reads as a sentence with a number over it — the
/// order on the page decides which of the two is the thing being looked at,
/// and on every screen this appears on it is the number.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.caption,
    this.color,
    super.key,
  });

  final String value;
  final String caption;
  final Color? color;

  /// Down from headlineSmall, which is now 32 and was never meant to have
  /// four of them side by side on one card.
  static const valueSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left in its own case, unlike the block labels: a caption here can
        // be «прибавка с 2 августа», and a date shouted in capitals is a
        // date that has to be read twice.
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Warm.onCardSoft(theme.brightness),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            height: 1.05,
            color: color ?? Warm.onCard(theme.brightness),
            fontFeatures: AppTheme.tabular,
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.hint,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? hint;

  /// Inside a dashboard card, where the full-page version left a hand's width
  /// of nothing above and below a single line of text.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circle = compact ? 40.0 : 68.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 32),
      child: Column(
        children: [
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              color: Warm.accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 20 : 30,
              color: Warm.accent.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: compact ? 8 : 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Warm.onCard(theme.brightness),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Warm.onCardSoft(theme.brightness),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Turns a backend failure into something a parent can act on.
///
/// Firestore reports problems as English exception dumps with a console URL
/// in them; showing that raw is no help to anyone.
String friendlyError(AppLocalizations l, Object error) {
  final text = error.toString();
  if (text.contains('failed-precondition') && text.contains('index')) {
    return l.errorIndexBuilding;
  }
  if (text.contains('permission-denied')) return l.errorPermission;
  if (text.contains('unavailable') || text.contains('network')) {
    return l.errorOffline;
  }
  if (text.contains('unauthenticated')) return l.errorSession;
  return l.errorGeneric;
}

/// Error panel with the human-readable message up front and the raw text
/// tucked away for when it has to be reported.
class ErrorState extends StatelessWidget {
  const ErrorState({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            friendlyError(l, error),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l.commonRetry),
            ),
          ],
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(l.commonTechnical, style: theme.textTheme.labelSmall),
            shape: const Border(),
            collapsedShape: const Border(),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableText(
                  error.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown by every screen when no child profile exists yet.
///
/// It carries the button rather than directions to it. This is the first
/// screen a new user meets, and sending her to find a section herself is a
/// dead end at the worst possible moment — she has not seen the app yet and
/// has no reason to trust that the trip is worth it.
class NoChildPlaceholder extends ConsumerWidget {
  const NoChildPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warmer than "profile not created". The parent has not failed to
            // do something; the app simply does not know the child yet.
            EmptyState(
              icon: Icons.child_care_outlined,
              message: l.noChildTitle,
              hint: l.noChildHint,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => addChildFlow(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l.addChild),
            ),
          ],
        ),
      ),
    );
  }
}
