import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'check_in.dart';

/// The day she was asked, and what she said, on her own phone.
///
/// This never goes to Firebase. "Очень тяжело" at seven in the morning is
/// something she told her phone about her night, not a fact about the child,
/// and it has no business in a record anyone else can read.
class CheckInRecord {
  const CheckInRecord({required this.day, this.answer});

  final DateTime day;

  /// Null when the card was waved away rather than answered.
  final CheckInAnswer? answer;
}

const _dayKey = 'check_in_day';
const _answerKey = 'check_in_answer';

class CheckInStore extends Notifier<CheckInRecord?> {
  @override
  CheckInRecord? build() {
    // Defaults first, disk second: the dashboard builds on the first frame
    // and must not wait on storage to decide whether to draw a card.
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    // Anything already in memory was set by the parent just now and is
    // newer than what the disk has: a slow read must not overwrite it.
    if (state != null) return;

    final day = DateTime.tryParse(prefs?.getString(_dayKey) ?? '');
    if (day == null) return;
    state = CheckInRecord(
      day: day,
      answer: CheckInAnswer.fromCode(prefs?.getString(_answerKey)),
    );
  }

  Future<void> answer(CheckInAnswer answer, {DateTime? now}) =>
      _save(answer, now);

  /// Waved away: the same effect on today, without a reply.
  Future<void> dismiss({DateTime? now}) => _save(null, now);

  Future<void> _save(CheckInAnswer? answer, DateTime? now) async {
    final day = now ?? DateTime.now();
    // Applied before the write, so the card responds under her finger.
    state = CheckInRecord(day: day, answer: answer);

    final prefs = await _prefs();
    await prefs?.setString(_dayKey, day.toIso8601String());
    if (answer == null) {
      await prefs?.remove(_answerKey);
    } else {
      await prefs?.setString(_answerKey, answer.code);
    }
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No preferences plugin here, or storage refused. It holds for this
      // run; it simply does not persist.
      return null;
    }
  }
}

final checkInStoreProvider =
    NotifierProvider<CheckInStore, CheckInRecord?>(CheckInStore.new);
