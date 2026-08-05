import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/family_member.dart';

/// The day the appreciation card was last put away, kept on her own phone.
///
/// Nothing about this goes anywhere. That a mother had a hard Tuesday, and
/// that a sentence about it was shown to her once, is not a fact about the
/// child and has no business in a record a doctor might one day read.
const _key = 'appreciation_seen_day';

class AppreciationStore extends Notifier<String?> {
  @override
  String? build() {
    // Defaults first, disk second: the dashboard builds on the first frame
    // and must not wait on storage to decide whether to draw a card.
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    // Anything already in memory was set just now and is newer than what the
    // disk has: a slow read must not overwrite it.
    if (state != null) return;
    state = prefs?.getString(_key);
  }

  bool seenOn(DateTime day) => state == dayStamp(day);

  Future<void> markSeen(DateTime day) async {
    final stamp = dayStamp(day);
    // Applied before the write, so the card closes under her finger.
    state = stamp;

    final prefs = await _prefs();
    await prefs?.setString(_key, stamp);
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

final appreciationStoreProvider =
    NotifierProvider<AppreciationStore, String?>(AppreciationStore.new);
