import '../../models/development_log.dart';
import '../../models/json.dart';

/// The week the family had, in four numbers and a photograph.
///
/// Not a report. A report is read once and filed; this is meant to be looked
/// at, sent to a grandmother and opened again in a year — which is why it
/// counts what a family is proud of rather than what a doctor would ask about.
///
/// What it deliberately holds no room for: an average, a percentile, a
/// comparison with last week or with any norm at all. The moment a card that
/// says "a week of care" also implies the week fell short of one, it stops
/// being a keepsake and becomes an assessment nobody asked for.
class WeeklyStory {
  const WeeklyStory({
    required this.from,
    required this.to,
    required this.feedings,
    required this.sleepMinutes,
    required this.nappies,
    required this.bestNightMinutes,
    required this.title,
    this.coverPhotoId,
  });

  /// Midnight seven days back, and the moment the story was built.
  final DateTime from;
  final DateTime to;

  final int feedings;
  final int sleepMinutes;
  final int nappies;

  /// The longest single night of the week, or null if no night was recorded.
  /// The best one rather than the average: an average night is arithmetic, and
  /// the night everybody finally slept is the one worth remembering.
  final int bestNightMinutes;

  /// The newest photograph of the week, which becomes the cover.
  final String? coverPhotoId;

  final StoryTitle title;

  bool get hasCover => coverPhotoId != null;
  bool get hasBestNight => bestNightMinutes > 0;

  /// Nothing was written down all week, so there is no week to show. The card
  /// draws nothing at all rather than a frame full of zeroes.
  bool get isEmpty =>
      feedings == 0 &&
      sleepMinutes == 0 &&
      nappies == 0 &&
      bestNightMinutes == 0 &&
      coverPhotoId == null;
}

/// The three warm titles.
enum StoryTitle { care, growing, moments }

/// How many days back the story looks.
const storyDays = 7;

/// Builds the week from the entries that already exist.
///
/// No story document, no weekly job, nothing to backfill — the same logs the
/// diary draws. A phone that has been offline since Tuesday builds Tuesday's
/// week and then this one, without either being written anywhere.
WeeklyStory buildWeeklyStory(List<DevelopmentLog> logs, DateTime now) {
  // Seven whole days including today: from midnight six days ago, so a story
  // opened at nine in the morning still covers a full week rather than six
  // days and a breakfast.
  final from = dateOnly(now).subtract(const Duration(days: storyDays - 1));

  var feedings = 0;
  var sleep = 0;
  var nappies = 0;
  var bestNight = 0;

  String? cover;
  DateTime? coverAt;

  for (final log in logs) {
    if (log.date.isBefore(from) || log.date.isAfter(now)) continue;

    switch (log.type) {
      case LogType.feeding:
        feedings++;
      case LogType.nappy:
        final kind = log.nappyKind;
        if (kind == null) break;
        if (kind.countsAsWet) nappies++;
        if (kind.countsAsDirty) nappies++;
      case LogType.sleep:
        sleep += log.durationMinutes ?? 0;
        if (log.isNightSleep) {
          final minutes = log.durationMinutes ?? 0;
          if (minutes > bestNight) bestNight = minutes;
        }
      default:
        break;
    }

    // Newest first, and the entry's own time decides — the same clock the
    // rest of the diary is ordered by.
    if (log.photos.isNotEmpty &&
        (coverAt == null || log.date.isAfter(coverAt))) {
      final id = log.photos.firstWhere((p) => p.isNotEmpty, orElse: () => '');
      if (id.isNotEmpty) {
        cover = id;
        coverAt = log.date;
      }
    }
  }

  return WeeklyStory(
    from: from,
    to: now,
    feedings: feedings,
    sleepMinutes: sleep,
    nappies: nappies,
    bestNightMinutes: bestNight,
    coverPhotoId: cover,
    title: titleForWeek(now),
  );
}

/// Which of the three titles this week gets.
///
/// From the week of the year, so it is the same on the mother's phone and the
/// father's, the same all week however often the card is opened, and a
/// different one next week — a card headed "a week of care" fifty-two times
/// running stops being read.
StoryTitle titleForWeek(DateTime now) {
  // Whole days since a fixed Monday, divided into weeks. Not `weekOfYear`,
  // which gives two consecutive weeks the same number across a year boundary.
  //
  // Counted in UTC on both sides: between two local midnights a clock change
  // makes a week 167 hours, which truncates to six days and would move the
  // title a day early in the countries that still shift their clocks.
  final day = DateTime.utc(now.year, now.month, now.day);
  final weeks = day.difference(DateTime.utc(2000, 1, 3)).inDays ~/ 7;
  final count = StoryTitle.values.length;
  return StoryTitle.values[((weeks % count) + count) % count];
}
