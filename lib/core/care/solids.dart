import '../../models/development_log.dart';

/// What this child has eaten, and what happened afterwards.
///
/// The whole feature is one table a paediatrician asks for out loud: which
/// foods have been introduced, when each was first given, and whether anything
/// followed. It is built entirely out of ordinary feed entries — a feed with
/// [FeedingSide.solid] and a name — and ordinary notes, so nothing here is a
/// second diary that can drift out of step with the first.

/// How long a new food is worth watching.
///
/// Three days is the interval every introduction guide prints: one food at a
/// time, three days before the next, because a reaction that takes two days to
/// appear cannot be pinned on anything if four foods were started meanwhile.
const newFoodWatchDays = 3;

/// One food, and its history.
class FoodRecord {
  const FoodRecord({
    required this.name,
    required this.firstAt,
    required this.lastAt,
    required this.times,
    required this.reactions,
  });

  /// As she first spelled it. Grouping is case- and space-insensitive, but
  /// what is shown back to her is her own word.
  final String name;

  final DateTime firstAt;
  final DateTime lastAt;

  /// How many spoons of it are on record.
  final int times;

  /// Notes she wrote about it afterwards, newest first.
  final List<DevelopmentLog> reactions;

  bool get hadReaction => reactions.isNotEmpty;

  /// Still inside the three days a new food is watched for.
  bool isUnderWatchAt(DateTime now) =>
      !hadReaction &&
      now.difference(firstAt).inDays < newFoodWatchDays &&
      !firstAt.isAfter(now);

  /// When the watch is over.
  DateTime get watchUntil =>
      firstAt.add(const Duration(days: newFoodWatchDays));
}

/// The key two spellings of the same food agree on.
String foodKey(String name) => name.trim().toLowerCase();

/// Every food on record, newest introduction first.
///
/// Newest first because the question being asked is almost always about the
/// last thing tried: a rash this afternoon is about the courgette on Tuesday,
/// not about the porridge in March.
List<FoodRecord> foodsIn(List<DevelopmentLog> logs) {
  final firstAt = <String, DateTime>{};
  final lastAt = <String, DateTime>{};
  final names = <String, String>{};
  final times = <String, int>{};
  final reactions = <String, List<DevelopmentLog>>{};

  for (final log in logs) {
    final raw = log.food?.trim();
    if (raw == null || raw.isEmpty) continue;
    final key = foodKey(raw);

    if (log.isSolid) {
      names.putIfAbsent(key, () => raw);
      times.update(key, (n) => n + 1, ifAbsent: () => 1);
      final first = firstAt[key];
      if (first == null || log.date.isBefore(first)) firstAt[key] = log.date;
      final last = lastAt[key];
      if (last == null || log.date.isAfter(last)) lastAt[key] = log.date;
    } else if (log.title.trim() == LogTitles.reaction) {
      // A reaction to a food never given — she wrote it after the fact, or the
      // spoon was somebody else's kitchen — still belongs in the table. It is
      // the reaction that matters, not the bookkeeping.
      names.putIfAbsent(key, () => raw);
      reactions.putIfAbsent(key, () => []).add(log);
      final first = firstAt[key];
      if (first == null || log.date.isBefore(first)) firstAt[key] = log.date;
      final last = lastAt[key];
      if (last == null || log.date.isAfter(last)) lastAt[key] = log.date;
    }
  }

  final records = [
    for (final key in names.keys)
      FoodRecord(
        name: names[key]!,
        firstAt: firstAt[key]!,
        lastAt: lastAt[key]!,
        times: times[key] ?? 0,
        reactions: (reactions[key] ?? [])
          ..sort((a, b) => b.date.compareTo(a.date)),
      ),
  ]..sort((a, b) => b.firstAt.compareTo(a.firstAt));

  return records;
}

/// The names she has used before, newest first — what the entry sheet offers
/// as chips so a food already introduced is one tap rather than typed again.
List<String> recentFoods(List<DevelopmentLog> logs, {int limit = 6}) {
  final seen = <String>{};
  final names = <String>[];
  for (final log in logs) {
    if (!log.isSolid) continue;
    final raw = log.food?.trim();
    if (raw == null || raw.isEmpty) continue;
    if (!seen.add(foodKey(raw))) continue;
    names.add(raw);
    if (names.length >= limit) break;
  }
  return names;
}
