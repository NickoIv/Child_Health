import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'sleep_forecast_dismissed_until';

/// One window's worth.
///
/// Not six hours like a suggestion: waving the forecast away means «I know, he
/// is in the pram», and the next window is a different afternoon's question.
/// Two hours is long enough to cover the one she dismissed and short enough
/// that the evening starts clean.
const forecastDismissDuration = Duration(hours: 2);

/// When the parent last waved the sleep forecast away, on her own phone.
///
/// Never in Firestore: it says something about her afternoon, not about the
/// child, and a record a doctor may read has no business knowing it.
class ForecastStore extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    // Defaults first, disk second: the home screen builds on the first frame
    // and must not wait on storage to decide whether to draw a card.
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    // Anything already in memory was set by the parent just now and is newer
    // than what the disk has.
    if (state != null) return;
    state = DateTime.tryParse(prefs?.getString(_key) ?? '');
  }

  Future<void> dismiss({DateTime? now}) async {
    final until = (now ?? DateTime.now()).add(forecastDismissDuration);
    // Applied before the write, so the card closes under her finger.
    state = until;
    final prefs = await _prefs();
    await prefs?.setString(_key, until.toIso8601String());
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

final forecastStoreProvider =
    NotifierProvider<ForecastStore, DateTime?>(ForecastStore.new);
