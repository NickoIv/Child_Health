import '../../models/development_log.dart';

/// The twenty milk teeth, and which of them have come through.
///
/// Built out of ordinary milestone entries rather than a store of its own: a
/// tooth is a thing that happened on a day, which is exactly what the diary
/// already records. Each entry carries a tag naming the slot, so the chart is
/// derived and there is no second list that can drift away from the timeline.
///
/// It never says a tooth is late. The ranges below are wide because teething
/// is: a first tooth at four months and a first tooth at twelve are both
/// ordinary, and a child with none at fifteen months is a conversation with a
/// dentist rather than a red mark from an app. What the card does is put the
/// published range next to the child's own dates and stop there.

/// Which jaw a slot belongs to.
enum Jaw { upper, lower }

/// Which side, looking at the child.
enum Side { left, right }

/// The shape of a milk tooth, and the order they arrive in.
enum ToothType { centralIncisor, lateralIncisor, canine, firstMolar, secondMolar }

/// One of the twenty places a tooth can appear.
class ToothSlot {
  const ToothSlot({
    required this.code,
    required this.type,
    required this.jaw,
    required this.side,
    required this.fromMonths,
    required this.toMonths,
  });

  /// Stored in the entry's tags, so it must never change. Latin, like every
  /// other code this app writes to Firestore.
  final String code;

  final ToothType type;
  final Jaw jaw;
  final Side side;

  /// The published window for this slot, in months of age.
  final int fromMonths;
  final int toMonths;

  /// Position along the jaw, centre outwards — what the chart draws.
  int get order => switch (type) {
    ToothType.centralIncisor => 0,
    ToothType.lateralIncisor => 1,
    ToothType.canine => 2,
    ToothType.firstMolar => 3,
    ToothType.secondMolar => 4,
  };
}

/// Typical eruption of the primary dentition.
///
/// Months are the ranges the American Academy of Pediatric Dentistry and the
/// ADA print on their eruption chart, which is also what the NHS and the
/// Kazakh paediatric guides reproduce. Lower teeth come first in each pair,
/// which is the one piece of order a parent actually notices.
const primaryTeeth = <ToothSlot>[
  // Lower central incisors — 6-10 months, and almost always the first two.
  ToothSlot(code: 'lc-l', type: ToothType.centralIncisor, jaw: Jaw.lower, side: Side.left, fromMonths: 6, toMonths: 10),
  ToothSlot(code: 'lc-r', type: ToothType.centralIncisor, jaw: Jaw.lower, side: Side.right, fromMonths: 6, toMonths: 10),
  // Upper central incisors — 8-12.
  ToothSlot(code: 'uc-l', type: ToothType.centralIncisor, jaw: Jaw.upper, side: Side.left, fromMonths: 8, toMonths: 12),
  ToothSlot(code: 'uc-r', type: ToothType.centralIncisor, jaw: Jaw.upper, side: Side.right, fromMonths: 8, toMonths: 12),
  // Upper lateral incisors — 9-13.
  ToothSlot(code: 'ul-l', type: ToothType.lateralIncisor, jaw: Jaw.upper, side: Side.left, fromMonths: 9, toMonths: 13),
  ToothSlot(code: 'ul-r', type: ToothType.lateralIncisor, jaw: Jaw.upper, side: Side.right, fromMonths: 9, toMonths: 13),
  // Lower lateral incisors — 10-16.
  ToothSlot(code: 'll-l', type: ToothType.lateralIncisor, jaw: Jaw.lower, side: Side.left, fromMonths: 10, toMonths: 16),
  ToothSlot(code: 'll-r', type: ToothType.lateralIncisor, jaw: Jaw.lower, side: Side.right, fromMonths: 10, toMonths: 16),
  // Upper first molars — 13-19.
  ToothSlot(code: 'um1-l', type: ToothType.firstMolar, jaw: Jaw.upper, side: Side.left, fromMonths: 13, toMonths: 19),
  ToothSlot(code: 'um1-r', type: ToothType.firstMolar, jaw: Jaw.upper, side: Side.right, fromMonths: 13, toMonths: 19),
  // Lower first molars — 14-18.
  ToothSlot(code: 'lm1-l', type: ToothType.firstMolar, jaw: Jaw.lower, side: Side.left, fromMonths: 14, toMonths: 18),
  ToothSlot(code: 'lm1-r', type: ToothType.firstMolar, jaw: Jaw.lower, side: Side.right, fromMonths: 14, toMonths: 18),
  // Upper canines — 16-22.
  ToothSlot(code: 'uk-l', type: ToothType.canine, jaw: Jaw.upper, side: Side.left, fromMonths: 16, toMonths: 22),
  ToothSlot(code: 'uk-r', type: ToothType.canine, jaw: Jaw.upper, side: Side.right, fromMonths: 16, toMonths: 22),
  // Lower canines — 17-23.
  ToothSlot(code: 'lk-l', type: ToothType.canine, jaw: Jaw.lower, side: Side.left, fromMonths: 17, toMonths: 23),
  ToothSlot(code: 'lk-r', type: ToothType.canine, jaw: Jaw.lower, side: Side.right, fromMonths: 17, toMonths: 23),
  // Lower second molars — 23-31.
  ToothSlot(code: 'lm2-l', type: ToothType.secondMolar, jaw: Jaw.lower, side: Side.left, fromMonths: 23, toMonths: 31),
  ToothSlot(code: 'lm2-r', type: ToothType.secondMolar, jaw: Jaw.lower, side: Side.right, fromMonths: 23, toMonths: 31),
  // Upper second molars — 25-33, and the last of them.
  ToothSlot(code: 'um2-l', type: ToothType.secondMolar, jaw: Jaw.upper, side: Side.left, fromMonths: 25, toMonths: 33),
  ToothSlot(code: 'um2-r', type: ToothType.secondMolar, jaw: Jaw.upper, side: Side.right, fromMonths: 25, toMonths: 33),
];

/// The tag prefix a tooth entry carries, e.g. `tooth:lc-l`.
///
/// A tag rather than a field: nothing in the schema had to change, a client
/// built before teeth existed shows the entry as an ordinary milestone, and
/// the diary needs no special case to display it.
const toothTagPrefix = 'tooth:';

String toothTag(ToothSlot slot) => '$toothTagPrefix${slot.code}';

ToothSlot? slotForCode(String code) {
  for (final slot in primaryTeeth) {
    if (slot.code == code) return slot;
  }
  return null;
}

/// The slot a diary entry is about, or null if it is not about a tooth.
ToothSlot? toothOf(DevelopmentLog log) {
  for (final tag in log.tags) {
    if (!tag.startsWith(toothTagPrefix)) continue;
    final slot = slotForCode(tag.substring(toothTagPrefix.length));
    if (slot != null) return slot;
  }
  return null;
}

/// When each slot came through, by code. Absent means not yet.
///
/// The earliest entry wins if a slot was written twice: a tooth appears once,
/// and a duplicate is a correction typed on top of a mistake rather than a
/// second tooth.
Map<String, DateTime> teethIn(List<DevelopmentLog> logs) {
  final erupted = <String, DateTime>{};
  for (final log in logs) {
    final slot = toothOf(log);
    if (slot == null) continue;
    final at = erupted[slot.code];
    if (at == null || log.date.isBefore(at)) erupted[slot.code] = log.date;
  }
  return erupted;
}

/// How many teeth a child this age usually has.
///
/// Counted straight off the table above rather than from a second rule of
/// thumb: the number of slots whose window has closed by this age, and the
/// number whose window has opened. Two figures, because «сколько уже должно
/// быть» has no single honest answer — between them is the ordinary range.
({int fewest, int most}) expectedTeethAt(int ageMonths) {
  var fewest = 0;
  var most = 0;
  for (final slot in primaryTeeth) {
    if (ageMonths >= slot.toMonths) fewest++;
    if (ageMonths >= slot.fromMonths) most++;
  }
  return (fewest: fewest, most: most);
}

/// The slots whose window has opened and which are not down yet — what to
/// expect next, in the order the table expects them.
List<ToothSlot> nextExpected(
  Map<String, DateTime> erupted,
  int ageMonths, {
  int limit = 2,
}) {
  final pending = primaryTeeth
      .where((s) => !erupted.containsKey(s.code))
      .toList()
    ..sort((a, b) {
      final byStart = a.fromMonths.compareTo(b.fromMonths);
      return byStart != 0 ? byStart : a.order.compareTo(b.order);
    });
  return pending.take(limit).toList();
}

/// Age in months at which this tooth arrived, for the child born on [birth].
int monthsAt(DateTime birth, DateTime when) {
  var months = (when.year - birth.year) * 12 + (when.month - birth.month);
  if (when.day < birth.day) months--;
  return months < 0 ? 0 : months;
}
