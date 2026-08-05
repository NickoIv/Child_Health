import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The day the observation was waved away on, kept on her own phone.
///
/// Nothing goes to Firestore: closing a card is about her afternoon, not
/// about the child.
const _key = 'pattern_dismissed_day';

class PatternStore extends Notifier<DateTime?> {
  @override
  DateTime? build() {
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

    final raw = prefs?.getString(_key);
    if (raw == null) return;
    state = DateTime.tryParse(raw);
  }

  Future<void> dismiss({DateTime? now}) async {
    final day = now ?? DateTime.now();
    // Applied before the write, so the card closes under her finger.
    state = day;

    final prefs = await _prefs();
    await prefs?.setString(_key, day.toIso8601String());
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No preferences plugin here, or storage refused. The dismissal holds
      // for this run; it simply does not persist.
      return null;
    }
  }
}

final patternStoreProvider =
    NotifierProvider<PatternStore, DateTime?>(PatternStore.new);
