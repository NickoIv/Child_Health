import 'package:flutter/material.dart';

import '../../core/care/noticing.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode.dart';
import '../../l10n/app_localizations.dart';

/// The one sentence at the top of the day, and the only copy of it.
///
/// It existed twice. The home screen draws [WarmHeader] and the configurable
/// block on the assistant tab draws [NowCard], and both carry the same idea —
/// a line saying something about today — in two implementations that had
/// already gone out of step: the phrase of the day existed only in the block,
/// so the home screen never showed one, and the first version of the noticed
/// line went into the block alone, where the person it was written for would
/// never have seen it.
///
/// So: one widget, both cards, and the only difference between them is the
/// colour it is drawn in.
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

/// A [Noticed] as the sentence it is shown as.
String noticedText(AppLocalizations l, Noticed noticed, String childName) {
  switch (noticed.kind) {
    case NoticedKind.roundAge:
      return l.noticedRoundAge(childName, noticed.months);
    case NoticedKind.longestNight:
      return l.noticedLongestNight(localizedDuration(l, noticed.minutes));
    case NoticedKind.yesterday:
      final feedings = l.reflectionFeedingsCount(noticed.feedings);
      return noticed.minutes == 0
          ? l.noticedYesterdayNoSleep(feedings)
          : l.noticedYesterday(
              feedings,
              localizedDuration(l, noticed.minutes),
            );
  }
}

/// One line: something true about today where there is one, the phrase of the
/// day where there is not, and nothing at all at night.
///
/// Deliberately a line and not a card. A card has to be dismissed, and the
/// last thing this should become is another thing to put away — it is here
/// today because a date arrived or a night went well, and it is gone tomorrow
/// without anybody touching it.
class DayLine extends StatelessWidget {
  const DayLine({
    required this.now,
    required this.noticed,
    required this.childName,
    this.ink,
    this.phraseWhenNothing = true,
    super.key,
  });

  final DateTime now;

  /// Something true about today. It always wins: a fact about this child
  /// beats a sentence written for every child.
  final Noticed? noticed;

  final String childName;

  /// The colour to draw on a gradient. Null on an ordinary white card, where
  /// the card's own ink and the readable accent are the right pair.
  final Color? ink;

  /// Whether the rotation fills the days that have no fact in them.
  ///
  /// False on the home header, and that is a decision with a test on it: the
  /// header was deliberately stripped to the child, the hour and the two
  /// figures, because a screen opened forty times a day is worth more empty
  /// than full. A fact earns a line there on the few days there is one; a
  /// sentence written for every child does not.
  ///
  /// True on the block version, which is read on a tab nobody opens forty
  /// times a day and where the rotation has always lived.
  final bool phraseWhenNothing;

  @override
  Widget build(BuildContext context) {
    // Silent between nine and seven, like everything else here that is only
    // pleasant to read rather than needed.
    if (isNightAt(now)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final fact = noticed;

    if (fact == null && !phraseWhenNothing) return const SizedBox.shrink();

    final text = fact == null
        ? phrasesOfDay(l)[phraseOfDayIndex(now, phrasesOfDay(l).length)]
        : noticedText(l, fact, childName);

    final glyphColor = ink != null
        ? ink!.withValues(alpha: 0.55)
        : (fact == null
              ? Warm.onCardSoft(theme.brightness)
              : Warm.accentOn(theme.brightness));

    final textColor = ink != null
        ? ink!.withValues(alpha: 0.85)
        : (fact == null
              ? Warm.onCardSoft(theme.brightness)
              : Warm.onCard(theme.brightness));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          // A different glyph for a different kind of sentence. The leaf is
          // the phrase of the day being gentle at nobody in particular; a
          // fact about this child gets the mark the app uses for a fact.
          fact == null ? Icons.spa_outlined : Icons.auto_awesome_outlined,
          size: 15,
          color: glyphColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              // Upright when it is a fact. The italic is the voice of the
              // phrase of the day — a fact leaning over reads as a quotation.
              fontStyle: fact == null ? FontStyle.italic : FontStyle.normal,
              fontWeight: fact == null ? null : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
