import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'suggestions.dart';

/// What the parent has waved away, kept on her own phone.
///
/// Nothing is written to Firestore: dismissing a hint says something about her
/// afternoon, not about the child, and it has no business in a record a doctor
/// might read.
const _prefix = 'suggestion_dismissed_';

/// Long enough that a dismissed hint does not come back the same afternoon,
/// short enough that tomorrow starts clean.
const dismissDuration = Duration(hours: 6);

class SuggestionStore extends Notifier<Map<SuggestionKind, DateTime>> {
  @override
  Map<SuggestionKind, DateTime> build() {
    // Defaults first, disk second: the dashboard builds on the first frame and
    // must not wait on storage to decide whether to draw a card.
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    if (prefs == null) return;
    // Anything already in memory was set by the parent just now and is
    // newer than what the disk has: a slow read must not overwrite it.
    if (state.isNotEmpty) return;

    final loaded = <SuggestionKind, DateTime>{};
    for (final kind in SuggestionKind.values) {
      final raw = prefs.getString('$_prefix${kind.code}');
      final until = raw == null ? null : DateTime.tryParse(raw);
      if (until != null) loaded[kind] = until;
    }
    state = loaded;
  }

  Future<void> dismiss(SuggestionKind kind, {DateTime? now}) async {
    final until = (now ?? DateTime.now()).add(dismissDuration);
    // Applied before the write, so the card closes under her finger rather
    // than after a round trip to disk.
    state = {...state, kind: until};

    final prefs = await _prefs();
    await prefs?.setString('$_prefix${kind.code}', until.toIso8601String());
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No preferences plugin on this platform, or storage refused. The
      // dismissal still holds for this run; it simply does not persist.
      return null;
    }
  }
}

final suggestionStoreProvider =
    NotifierProvider<SuggestionStore, Map<SuggestionKind, DateTime>>(
      SuggestionStore.new,
    );
