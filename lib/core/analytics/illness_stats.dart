import '../../models/development_log.dart';
import '../../models/json.dart';

/// Illness arithmetic, kept as plain functions.
///
/// These decide what the heat map paints and what the statistics claim, and
/// both must agree. Keeping them out of the providers means they can be
/// tested directly, without a container and without waiting on streams.

/// Worst severity recorded on each calendar day.
///
/// A day can hold several entries — a morning reading and an evening one —
/// and the map should show how bad the day got, not whichever entry happened
/// to be written last. An entry with no severity counts as mild: it was still
/// a sick day.
Map<DateTime, Severity> worstSeverityByDay(List<DevelopmentLog> logs) {
  final worst = <DateTime, Severity>{};
  for (final log in logs) {
    if (log.type != LogType.illness) continue;
    final day = dateOnly(log.date);
    final severity = log.severity ?? Severity.mild;
    final existing = worst[day];
    if (existing == null || severity.index > existing.index) {
      worst[day] = severity;
    }
  }
  return worst;
}

/// Consecutive sick days count as one episode; a gap of more than two clear
/// days starts a new one.
int countIllnessEpisodes(Set<DateTime> days) {
  if (days.isEmpty) return 0;
  final sorted = days.toList()..sort();
  var episodes = 1;
  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i].difference(sorted[i - 1]).inDays > 2) episodes++;
  }
  return episodes;
}
