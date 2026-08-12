import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/development_log.dart';

/// What is being timed. Only two things are: the two a parent is in the middle
/// of when she cannot type, and the two she is asked about by everyone.
enum TimerKind {
  feeding,
  sleep;

  static TimerKind? fromCode(String? code) => switch (code) {
    'feeding' => TimerKind.feeding,
    'sleep' => TimerKind.sleep,
    _ => null,
  };

  String get code => name;
}

/// A stretch that started and has not finished.
///
/// It lives on the phone and nowhere else. A feed in progress is not a fact
/// about the child yet — it becomes one when it ends and a length is known,
/// and until then writing it to a record everyone in the family can read would
/// be publishing a guess.
class ActiveTimer {
  const ActiveTimer({
    required this.kind,
    required this.childId,
    required this.startedAt,
    this.side,
  });

  final TimerKind kind;
  final String childId;
  final DateTime startedAt;

  /// Feeding only, and chosen before the clock starts: which breast this is,
  /// which is the thing she will be trying to remember in three hours.
  final FeedingSide? side;

  Duration elapsed(DateTime now) {
    final d = now.difference(startedAt);
    // A clock moved back — by a timezone, by an NTP correction, by a parent
    // fixing the date — must not print a negative feed.
    return d.isNegative ? Duration.zero : d;
  }

  /// What gets written down. Rounded to the nearest minute and never zero:
  /// «0 мин» is not something that happened, and a forty-second latch is.
  int minutesAt(DateTime now) {
    final seconds = elapsed(now).inSeconds;
    final minutes = (seconds + 30) ~/ 60;
    return minutes < 1 ? 1 : minutes;
  }

  /// Long enough that it was probably left running rather than lived through.
  ///
  /// Two hours at the breast and sixteen in a cot are both possible and
  /// neither is likely; what is likely is that the phone went in a pocket. The
  /// card says so rather than deciding for her — a timer that stopped itself
  /// would be a number nobody measured, which is the one thing a medical
  /// record must not contain.
  bool looksForgotten(DateTime now) {
    final hours = elapsed(now).inMinutes / 60;
    return kind == TimerKind.feeding ? hours >= 2 : hours >= 16;
  }
}

const _kindKey = 'active_timer_kind';
const _startedKey = 'active_timer_started';
const _sideKey = 'active_timer_side';
const _childKey = 'active_timer_child';

/// The one running timer, restored across a reload.
///
/// One, not one per kind: a parent is doing one of these at a time, and two
/// clocks running at once is a screen that has to be read before it can be
/// used. Restoring it matters more here than anywhere else in the app — this
/// is installed as a web app, a reload happens whenever the phone decides to
/// reclaim memory, and a feed whose start time was lost cannot be recovered by
/// remembering harder.
/// The entry a stopped timer becomes.
///
/// Here rather than in the card that stops it, because two things stop a timer
/// now — the card on the home screen and «останови таймер» said to the
/// assistant — and two copies of this would be two shapes of the same evening
/// on one timeline.
///
/// Dated to when the timer *started*, not to when it was stopped: the feed
/// began at the moment she pressed the button, and a record dated to the end
/// of it puts an hour's nap in the wrong hour of the day.
DevelopmentLog timerDraft(ActiveTimer timer, {required DateTime at}) {
  final type = timer.kind == TimerKind.feeding
      ? LogType.feeding
      : LogType.sleep;

  return DevelopmentLog(
    id: '',
    childId: timer.childId,
    date: timer.startedAt,
    type: type,
    // The model's own wording, because it is what sits in Firestore.
    title: type.label,
    feedingSide: timer.side,
    durationMinutes: timer.minutesAt(at),
  );
}

class ActiveTimerStore extends Notifier<ActiveTimer?> {
  @override
  ActiveTimer? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    // Anything already in memory was started by the parent just now and is
    // newer than the disk: a slow read must not overwrite it.
    if (state != null) return;

    final kind = TimerKind.fromCode(prefs?.getString(_kindKey));
    final started = DateTime.tryParse(prefs?.getString(_startedKey) ?? '');
    final childId = prefs?.getString(_childKey);
    if (kind == null || started == null || childId == null) return;

    state = ActiveTimer(
      kind: kind,
      childId: childId,
      startedAt: started,
      side: FeedingSide.fromCode(prefs?.getString(_sideKey)),
    );
  }

  /// Starts one, replacing whatever was running.
  ///
  /// Replacing rather than refusing: a mother who taps «сон» while a forgotten
  /// feed is still counting means the sleep, and an error message explaining
  /// the conflict would be the app arguing with her about her own evening.
  Future<ActiveTimer> start({
    required TimerKind kind,
    required String childId,
    FeedingSide? side,
    DateTime? now,
  }) async {
    final timer = ActiveTimer(
      kind: kind,
      childId: childId,
      startedAt: now ?? DateTime.now(),
      side: side,
    );
    state = timer;

    final prefs = await _prefs();
    await prefs?.setString(_kindKey, kind.code);
    await prefs?.setString(_startedKey, timer.startedAt.toIso8601String());
    await prefs?.setString(_childKey, childId);
    if (side == null) {
      await prefs?.remove(_sideKey);
    } else {
      await prefs?.setString(_sideKey, side.code);
    }
    return timer;
  }

  /// Ends it and hands it back, so the caller can write it down.
  ///
  /// The writing stays with the widget that has the repository and the place
  /// to say so; this only owns the clock.
  Future<ActiveTimer?> stop() async {
    final timer = state;
    await clear();
    return timer;
  }

  /// Thrown away rather than recorded — the timer she started for the wrong
  /// child, or the one she now knows was left running in a coat pocket.
  Future<void> clear() async {
    state = null;
    final prefs = await _prefs();
    await prefs?.remove(_kindKey);
    await prefs?.remove(_startedKey);
    await prefs?.remove(_sideKey);
    await prefs?.remove(_childKey);
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No preferences plugin here, or storage refused. The timer holds for
      // this run; it simply does not survive a reload.
      return null;
    }
  }
}

final activeTimerProvider =
    NotifierProvider<ActiveTimerStore, ActiveTimer?>(ActiveTimerStore.new);
