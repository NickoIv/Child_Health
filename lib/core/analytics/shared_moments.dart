import '../../models/development_log.dart';
import '../../models/json.dart';

/// A photograph added today, and the time it arrived.
///
/// The time is the entry's, not the photograph's: a picture belongs to the
/// moment it was written down beside, and that is the one a father recognises
/// — "the feed at four" rather than whenever the camera roll says the file
/// was created.
class Moment {
  const Moment({required this.photoId, required this.at});

  final String photoId;
  final DateTime at;
}

/// Three photographs and no more.
///
/// A gallery invites scrolling and comparing, and then wondering why there
/// were only two on Tuesday. Three is a glance.
const momentsLimit = 3;

/// Which of the three warm lines sits under the photographs.
///
/// Picked from how many are showing rather than at random, so the same day
/// reads the same way on both phones and does not change under a parent while
/// they are looking at it.
enum MomentLine { one, two, many }

/// Today's photographs, newest first, capped at [momentsLimit].
///
/// Scoped to today for the same reason the digest is: the two cards sit one
/// above the other, and a count of "3 new photos" over yesterday's pictures
/// would be the app contradicting itself.
///
/// Built from the diary's own photo ids — no second collection, nothing to
/// keep in step, and nothing that has to be written when a photograph is
/// uploaded.
List<Moment> recentMoments(List<DevelopmentLog> logs, DateTime day) {
  final target = dateOnly(day);
  final todays = logs.where((l) => dateOnly(l.date) == target).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final moments = <Moment>[];
  final seen = <String>{};

  for (final log in todays) {
    for (final id in log.photos) {
      // The same photograph attached to two entries is one moment.
      if (id.isEmpty || !seen.add(id)) continue;
      moments.add(Moment(photoId: id, at: log.date));
      if (moments.length == momentsLimit) return moments;
    }
  }
  return moments;
}

/// The line for a number of photographs. A pure function so a test can read it
/// without building anything — and so the choice stays visibly deterministic.
MomentLine lineFor(int shown) => switch (shown) {
  2 => MomentLine.two,
  >= 3 => MomentLine.many,
  _ => MomentLine.one,
};
