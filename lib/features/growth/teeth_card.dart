import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/teeth.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Twenty places, and which of them have something in them.
///
/// The thing a parent actually wants here is not a count — it is «этот уже
/// вылез или мне кажется». So the card is a picture of a mouth: two arches in
/// the order the teeth sit in, filled in as they arrive. Tapping one marks it,
/// which writes an ordinary milestone into the diary on the day it happened.
///
/// The published range sits under the count and nothing compares the child to
/// it. A first tooth at four months and a first at twelve are both ordinary,
/// and an app that drew a red mark on the second would be inventing a problem
/// out of a table of averages.
class TeethCard extends ConsumerWidget {
  const TeethCard({required this.child, super.key});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final erupted = teethIn(logs);
    final ageMonths = child.ageInMonths;
    final usual = expectedTeethAt(ageMonths);
    final next = nextExpected(erupted, ageMonths, limit: 1);

    return SectionCard(
      title: l.teethTitle,
      icon: Icons.sentiment_satisfied_alt_outlined,
      accentColor: VizPalette.slot(3, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            erupted.isEmpty ? l.teethNone : l.teethCount(erupted.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabular,
            ),
          ),
          const SizedBox(height: 2),
          // Two figures rather than one: «сколько должно быть» has no single
          // honest answer, and the space between them is the ordinary range.
          Text(
            l.teethUsual(usual.fewest, usual.most),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _Arch(
            jaw: Jaw.upper,
            erupted: erupted,
            birthDate: child.birthDate,
            onTap: (slot) => _mark(context, ref, slot, erupted[slot.code]),
          ),
          const SizedBox(height: 10),
          _Arch(
            jaw: Jaw.lower,
            erupted: erupted,
            birthDate: child.birthDate,
            onTap: (slot) => _mark(context, ref, slot, erupted[slot.code]),
          ),
          const SizedBox(height: 12),
          const _Legend(),
          const SizedBox(height: 12),
          // Both lines, not one or the other. The instruction used to appear
          // only once every tooth was marked — which is to say, only to
          // someone who had already worked out what to do. It is the person
          // looking at an empty mouth who needs it.
          if (next.isNotEmpty)
            Text(
              l.teethNext(toothName(l, next.first).toLowerCase()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (erupted.length < primaryTeeth.length) ...[
            const SizedBox(height: 2),
            Text(
              l.teethHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Warm.accentOn(theme.brightness),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // The same line every other screen carrying a figure has. The one
          // on this screen belongs to the WHO percentiles above and says
          // nothing about teething, and a published month range read without
          // it is a number that can pass for a verdict.
          Text(
            l.teethDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Mark it, move it, or take the mark off again.
  Future<void> _mark(
    BuildContext context,
    WidgetRef ref,
    ToothSlot slot,
    DateTime? already,
  ) async {
    if (ref.read(isReadOnlyProvider)) return;

    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showAppSheet<_ToothChoice>(
      context,
      builder: (_) => _ToothSheet(slot: slot, marked: already),
    );
    if (result == null) return;

    final repository = ref.read(logRepositoryProvider);

    // Whatever was there goes first, so a corrected date replaces the entry
    // rather than leaving two teeth in one socket.
    for (final log in ref.read(logsProvider).value ?? const <DevelopmentLog>[]) {
      if (toothOf(log)?.code == slot.code) await repository.delete(log.id);
    }

    /// Puts the slot back the way it was found. Both directions need it: a
    /// tooth marked by a mis-tap and a mark taken off by one are the same
    /// mistake, and undoing either by hand means finding the right square
    /// among twenty and remembering the date that was on it.
    Future<void> restore() async {
      for (final log
          in ref.read(logsProvider).value ?? const <DevelopmentLog>[]) {
        if (toothOf(log)?.code == slot.code) await repository.delete(log.id);
      }
      if (already == null) return;
      await repository.add(
        DevelopmentLog(
          id: '',
          childId: child.id,
          date: already,
          type: LogType.milestone,
          title: LogTitles.tooth,
          tags: [toothTag(slot)],
        ),
      );
    }

    if (result.date == null) {
      messenger.showSnackBar(
        appSnack(
          l.teethUnmarked,
          action: SnackBarAction(label: l.commonUndo, onPressed: restore),
        ),
      );
      return;
    }

    await repository.add(
      DevelopmentLog(
        id: '',
        childId: child.id,
        date: result.date!,
        type: LogType.milestone,
        // Stored in Russian like every other title this app writes; what the
        // timeline shows is looked up from the tag.
        title: LogTitles.tooth,
        tags: [toothTag(slot)],
      ),
    );
    messenger.showSnackBar(
      appSnack(
        l.teethMarked(toothName(l, slot)),
        kind: SnackKind.done,
        action: SnackBarAction(label: l.commonUndo, onPressed: restore),
      ),
    );
  }
}

/// One jaw, in the order the teeth sit in the mouth.
class _Arch extends StatelessWidget {
  const _Arch({
    required this.jaw,
    required this.erupted,
    required this.birthDate,
    required this.onTap,
  });

  final Jaw jaw;
  final Map<String, DateTime> erupted;
  final DateTime birthDate;
  final void Function(ToothSlot) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    // Right side of the mouth first, outermost tooth at the edge — which is
    // how it looks from in front, and this is a picture of a mouth.
    final right = primaryTeeth
        .where((s) => s.jaw == jaw && s.side == Side.right)
        .toList()
      ..sort((a, b) => b.order.compareTo(a.order));
    final left = primaryTeeth
        .where((s) => s.jaw == jaw && s.side == Side.left)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jaw == Jaw.upper ? l.teethUpperJaw : l.teethLowerJaw,
          style: AppTheme.microLabel(theme.brightness),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final slot in [...right, ...left])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: _Tooth(
                    slot: slot,
                    at: erupted[slot.code],
                    birthDate: birthDate,
                    onTap: () => onTap(slot),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One tooth: filled once it is through, an outline until then.
class _Tooth extends StatelessWidget {
  const _Tooth({
    required this.slot,
    required this.at,
    required this.birthDate,
    required this.onTap,
  });

  final ToothSlot slot;
  final DateTime? at;
  final DateTime birthDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final through = at != null;
    // Molars are wider in the mouth, so they are wider here: the row reads as
    // a jaw rather than as twenty identical boxes.
    final tall = slot.type == ToothType.firstMolar ||
        slot.type == ToothType.secondMolar;

    return Semantics(
      button: true,
      label: toothName(AppLocalizations.of(context), slot),
      selected: through,
      child: Pressable(
        onTap: onTap,
        borderRadius: 7,
        child: Container(
          height: tall ? 32 : 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: through
                ? Warm.accent.withValues(alpha: 0.9)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: through
                  ? Warm.accent
                  : Warm.hairline(theme.brightness),
              width: 1,
            ),
          ),
          // The age it arrived at, inside the tooth. Two characters at most,
          // and it turns the picture from a tally into the story a parent
          // actually tells — «нижние в шесть, верхние в восемь» — without
          // tapping anything to find out.
          child: through
              ? Text(
                  '${monthsAt(birthDate, at!)}',
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFeatures: AppTheme.tabular,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// What the two kinds of square mean, and what the number in one is.
///
/// A picture that has to be worked out is a picture that gets skipped. Three
/// short phrases under the arches cost one line and remove the guessing —
/// «не все сразу разберутся» was exactly right.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    // Wrap rather than Row: three phrases and two swatches do not fit one
    // line at 390 px, and this card is read on a phone.
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Swatch(
          filled: true,
          label: l.teethLegendThrough,
          style: style,
        ),
        _Swatch(
          filled: false,
          label: l.teethLegendNotYet,
          style: style,
        ),
        Text(l.teethLegendAge, style: style),
      ],
    );
  }
}

/// One square, drawn exactly as the teeth above are.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.filled,
    required this.label,
    required this.style,
  });

  final bool filled;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled
                ? Warm.accent.withValues(alpha: 0.9)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: filled ? Warm.accent : Warm.hairline(theme.brightness),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

/// What the sheet came back with. A null date means "take the mark off".
class _ToothChoice {
  const _ToothChoice(this.date);

  final DateTime? date;
}

class _ToothSheet extends StatelessWidget {
  const _ToothSheet({required this.slot, required this.marked});

  final ToothSlot slot;
  final DateTime? marked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = DateTime.now();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(toothName(l, slot), style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l.teethExpected(slot.fromMonths, slot.toMonths),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (marked != null) ...[
              const SizedBox(height: 10),
              Text(
                shortDate.format(marked!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(l.teethWhen, style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_ToothChoice(today)),
              child: Text(l.teethToday),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(
                _ToothChoice(today.subtract(const Duration(days: 1))),
              ),
              child: Text(l.teethYesterday),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _pick(context, today),
              child: Text(l.teethPickDate),
            ),
            if (marked != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const _ToothChoice(null)),
                child: Text(l.teethRemove),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, DateTime today) async {
    final navigator = Navigator.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: marked ?? today,
      // A tooth cannot have arrived before the child did, and cannot arrive
      // tomorrow.
      firstDate: today.subtract(const Duration(days: 365 * 6)),
      lastDate: today,
    );
    if (picked != null) navigator.pop(_ToothChoice(picked));
  }
}
