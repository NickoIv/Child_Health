import '../../models/development_log.dart';
import '../../models/json.dart';

/// Milk expressed, counted for the day.
///
/// The only thing in this diary that is about the mother rather than the
/// child, and the only number she is keeping for her own sake: whether today
/// covered tomorrow's bottles. It is deliberately a total and not a target —
/// there is no norm here to fall short of, and a mother pumping at four in the
/// morning does not need an app with an opinion about her output.

/// What was expressed on the calendar day containing [day].
int pumpedOnDay(List<DevelopmentLog> logs, DateTime day) {
  final target = dateOnly(day);
  var total = 0;
  for (final log in logs) {
    if (!log.isPumping) continue;
    if (dateOnly(log.date) != target) continue;
    total += log.milkMl ?? 0;
  }
  return total;
}

/// Every pumping session on record, in the order the repository hands them
/// over — newest first.
List<DevelopmentLog> pumpingIn(List<DevelopmentLog> logs) =>
    logs.where((l) => l.isPumping).toList();

/// The step the volume moves in, and the range the buttons cover.
///
/// Ten millilitres, because a pump is graduated in tens and nobody has ever
/// expressed 137. The ceiling is generous rather than accurate: it exists so a
/// slider has an end, not to say anything about how much is normal.
const pumpStepMl = 10;
const pumpMaxMl = 400;

/// Where the entry opens.
///
/// A hundred is the middle of what a single session usually gives, so the
/// common correction is two taps in either direction rather than a slider
/// dragged across the screen.
const pumpDefaultMl = 100;
