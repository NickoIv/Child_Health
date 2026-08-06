import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Dictating a note, and nothing more than that.
///
/// The audio never leaves the recogniser the operating system already has:
/// there is no recording, no file, no upload and no model of ours in the
/// path. What comes back is a string, it goes into a text field, and the
/// mother still has to read it and press save. Nothing here parses what she
/// said, and nothing here acts on it — a diary that heard "38 и 5" and
/// silently wrote down a fever would be an app making a medical judgement out
/// of a noisy room.
///
/// Stated as an interface because the real one is a platform channel and the
/// tests are not allowed to need a microphone.
abstract interface class Dictation {
  /// Wakes the recogniser and asks for the microphone if it has to.
  ///
  /// False means refused, missing or unsupported — all of which the caller
  /// treats identically, because from where the parent is sitting they are
  /// the same thing: the keyboard still works.
  Future<bool> prepare();

  /// Why [prepare] said no, in the recogniser's own words.
  ///
  /// Null when it has not been asked yet or when it worked. On the web this
  /// is the browser's reason — `not supported` from an iOS home-screen app,
  /// where Safari withholds the speech API entirely, is a different problem
  /// from a denied permission and needs a different sentence.
  String? get unavailableReason;

  /// Whether the last session is still winding down.
  ///
  /// The browser keeps one recogniser for the life of the page and refuses to
  /// start it again while the previous run is still closing — the refusal is
  /// a synchronous exception nobody was catching, so the second hold of the
  /// day produced no result and was reported as "could not recognise speech".
  bool get busy;

  /// Whether [prepare] has already succeeded.
  ///
  /// Exists so the caller can reach [start] without an `await` in front of
  /// it. Safari only opens a microphone from inside the event handler of a
  /// real gesture, and an awaited future — even one that completes at once —
  /// resumes in a later microtask, by which time the gesture is over and the
  /// request is refused. Every hold after the first takes that path.
  bool get ready;

  /// Listens until [DictationSession.maxDuration], a pause, or [stop].
  ///
  /// [onResult] fires once, with the finished text. Partial results are
  /// deliberately not surfaced: text that rewrites itself under the cursor
  /// while someone is still talking is harder to trust than text that
  /// appears when they stop.
  ///
  /// [onLevel] reports how loud the room is, 0 to 1, for the waveform on the
  /// hold-to-talk button. It is a level, not audio: no samples are kept, and
  /// nothing is recorded anywhere.
  Future<void> start({
    required String localeId,
    required ValueChanged<String> onResult,
    required VoidCallback onSilence,
    ValueChanged<double>? onLevel,
    ValueChanged<String>? onFailure,
  });

  Future<void> stop();

  /// What the recogniser did last time, in order, with timings.
  ///
  /// A microphone that produces nothing produces nothing to look at either:
  /// the browser reports through callbacks that go nowhere a user can see,
  /// and "could not recognise speech" is the same sentence whether the
  /// session never opened, opened and heard silence, or heard a sentence the
  /// plugin then dropped. This is the difference, in a form that can be
  /// screenshotted and sent.
  List<String> get trace;
}

/// What one recognition is asked for.
///
/// Lifted out of the call so a test can read it: one of these fields is load
/// bearing in a way its name does not admit, and turning it back on silently
/// breaks voice input on every iPhone.
SpeechListenOptions dictationOptions(String localeId) => SpeechListenOptions(
  listenFor: DictationSession.maxDuration,
  pauseFor: DictationSession.pause,
  localeId: localeId,
  // The words are wanted, not a command: dictation mode rather than the
  // confirmation mode tuned for "yes" and "cancel".
  listenMode: ListenMode.dictation,
  // False, and it costs more than it looks like it does. The web plugin sets
  // `continuous` from this same flag, and Safari on iOS does not do
  // continuous recognition — with it on the microphone opened, closed and
  // produced nothing at all. A sentence longer than the recogniser's patience
  // is handled by restarting instead, not by asking for a longer one.
  partialResults: false,
  cancelOnError: true,
);

/// Session limits, kept where both the controller and its tests can see them.
abstract final class DictationSession {
  /// Half a minute is longer than any note in this app has ever been, and
  /// short enough that a phone left face-down on a bed stops listening on its
  /// own.
  static const maxDuration = Duration(seconds: 30);

  /// A gap this long means she has finished, not that she is thinking.
  ///
  /// Five, not three. "Покормила левой... минут пятнадцать" has a gap in the
  /// middle of it, and three seconds was cutting the sentence in half and
  /// keeping the first half.
  static const pause = Duration(seconds: 5);

  /// How long to wait after the button is released for a final transcript.
  ///
  /// Recognisers finalise asynchronously. Releasing and immediately reading
  /// what was heard gets whatever had been decided so far, which on a slow
  /// connection is most of the sentence rather than all of it.
  static const settle = Duration(milliseconds: 700);
}

/// The real one: whatever speech recognition the device already ships with.
class PlatformDictation implements Dictation {
  PlatformDictation({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _ready = false;

  /// Set by the recogniser's own error callback, which is where the browser
  /// says *why* — `not-allowed`, `service-not-allowed`, `language-not-
  /// supported`. Swallowing it left a parent holding a button that did
  /// nothing and no way for anyone to find out what.
  String? _lastError;

  /// Everything heard while the button has been held, in order.
  ///
  /// A browser recogniser ends the moment it decides a sentence is over, and
  /// it decides that in the middle of "покормила левой... минут пятнадцать".
  /// One hold is therefore not one recognition but several, restarted as
  /// each ends, and this is where the pieces are kept until she lets go.
  final _segments = <String>[];
  String get _heard => _segments.join(' ').trim();
  bool _delivered = true;

  /// True while her finger is still down.
  ///
  /// The difference between a recogniser that finished and a person who
  /// finished. Only the second one ends the recording.
  bool _holding = false;

  /// Kept so a restart can ask for the same thing the first one did.
  String _localeId = '';
  ValueChanged<double>? _onLevel;

  ValueChanged<String>? _onResult;
  VoidCallback? _onSilence;
  ValueChanged<String>? _onFailure;

  /// True from the moment a session is asked for until the recogniser has
  /// actually let go of the microphone.
  bool _sessionActive = false;

  final _trace = <String>[];
  DateTime? _sessionStart;

  @override
  List<String> get trace => List.unmodifiable(_trace);

  void _note(String event) {
    final started = _sessionStart;
    final ms = started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds;
    _trace.add('$ms ms  $event');
    // Long enough to hold a whole hold, short enough to fit on a screen.
    if (_trace.length > 30) _trace.removeAt(0);
  }

  @override
  bool get ready => _ready;

  @override
  bool get busy => _sessionActive || _speech.isListening;

  @override
  String? get unavailableReason => _ready ? null : _lastError;

  @override
  Future<bool> prepare() async {
    if (_ready) return true;
    // initialize() is what raises the permission dialog, and it is safe to
    // call more than once — the plugin remembers.
    try {
      _ready = await _speech.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          _note('error ${error.errorMsg}'
              '${error.permanent ? ' (permanent)' : ''}');
        },
        onStatus: (status) => _note('status $status'),
      );
      _note('initialize $_ready');
    } catch (_) {
      // A device with no recogniser at all throws rather than returning
      // false. Same outcome for the parent either way.
      _ready = false;
    }
    return _ready && await _speech.hasPermission;
  }

  @override
  Future<void> start({
    required String localeId,
    required ValueChanged<String> onResult,
    required VoidCallback onSilence,
    ValueChanged<double>? onLevel,
    ValueChanged<String>? onFailure,
  }) async {
    if (!_ready || busy) return;
    _lastError = null;
    _segments.clear();
    _trace.clear();
    _sessionStart = DateTime.now();
    _note('hold begins, locale $localeId');
    _delivered = false;
    _sessionActive = true;
    _holding = true;
    _localeId = localeId;
    _onLevel = onLevel;
    _onResult = onResult;
    _onSilence = onSilence;
    _onFailure = onFailure;

    try {
      await _startSession(localeId, onLevel);
    } catch (error) {
      // The recogniser said no, out loud, on the way in. Reported as itself
      // rather than as a silent room — they are not the same failure and
      // only one of them is the parent's fault.
      _sessionActive = false;
      _delivered = true;
      onFailure?.call(_reasonFrom(error));
    }
  }

  /// One line for the reason, out of whatever the platform threw.
  ///
  /// Browsers raise a DOM exception here and phones a PlatformException; both
  /// stringify to something long and neither is meant for a parent, so this
  /// is a label for a bug report rather than an explanation.
  String _reasonFrom(Object error) {
    final text = error.toString();
    return text.length > 60 ? '${text.substring(0, 60)}…' : text;
  }

  Future<void> _startSession(
    String localeId,
    ValueChanged<double>? onLevel,
  ) async {
    await _speech.listen(
      // The plugin reports roughly -2..10 on iOS and 0..10 on Android;
      // normalised here so the waveform does not have to know either.
      onSoundLevelChange: onLevel == null
          ? null
          : (level) => onLevel((level / 10).clamp(0.0, 1.0)),
      onResult: (result) {
        final text = result.recognizedWords.trim();
        _note('result final=${result.finalResult} "$text"');
        if (!result.finalResult) return;
        if (text.isNotEmpty) _segments.add(text);
        // The recogniser is done with this clause. She may not be done with
        // the sentence, and her finger says which.
        if (_holding) {
          unawaited(_resume());
        } else {
          _deliver();
        }
      },
      listenOptions: dictationOptions(localeId),
    );
  }

  /// Listen again, because she has not stopped talking.
  ///
  /// The recogniser has to be given a moment to let go before it will start
  /// again — asking too early throws, which is the same refusal that used to
  /// break the second recording of the day. A restart that fails is not an
  /// error worth showing: it means this hold is over, and what was heard up
  /// to here is what gets written down.
  Future<void> _resume() async {
    for (var i = 0; i < 10 && _speech.isListening; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!_holding || _delivered) return;
    _note('restart');
    try {
      await _startSession(_localeId, _onLevel);
    } catch (_) {
      _deliver();
    }
  }

  @override
  Future<void> stop() async {
    _holding = false;
    _note('released');
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {
      // Stopping something that has already stopped is not a problem worth
      // propagating to a finger that has simply lifted.
    }

    // Give the recogniser its moment to finish the sentence before deciding
    // that what we have is all there is.
    if (!_delivered) {
      await Future<void>.delayed(DictationSession.settle);
      _deliver();
    }

    // And then wait for it to actually let go. Until it has, the next hold
    // would be refused — which is the whole reason a second recording used
    // to fail where the first one worked.
    for (var i = 0; i < 20 && _speech.isListening; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _sessionActive = false;
  }

  /// Hands over whatever was heard, exactly once per session.
  void _deliver() {
    if (_delivered) return;
    _delivered = true;

    final text = _heard;
    _note('delivering "$text"');
    if (text.isNotEmpty) {
      _onResult?.call(text);
      return;
    }
    // A refusal and a silent room both end up here. They are not the same
    // thing to whoever is holding the button.
    final error = _lastError;
    if (error != null && _onFailure != null) {
      _onFailure!(error);
    } else {
      _onSilence?.call();
    }
  }
}

/// Used where the platform has no microphone to offer — the web build served
/// over plain http, a desktop window, a widget test. [prepare] simply says no
/// and the button never appears.
class UnavailableDictation implements Dictation {
  const UnavailableDictation();

  @override
  bool get ready => false;

  @override
  bool get busy => false;

  @override
  List<String> get trace => const [];

  @override
  String? get unavailableReason => null;

  @override
  Future<bool> prepare() async => false;

  @override
  Future<void> start({
    required String localeId,
    required ValueChanged<String> onResult,
    required VoidCallback onSilence,
    ValueChanged<double>? onLevel,
    ValueChanged<String>? onFailure,
  }) async {}

  @override
  Future<void> stop() async {}
}

/// The recogniser locale for an interface language.
///
/// Two spellings of the same thing, and the difference is not cosmetic. The
/// native plugins want `ru_RU`, the way Android and iOS list their locales.
/// A browser wants the BCP-47 tag `ru-RU` and assigns it straight to
/// `SpeechRecognition.lang` — hand it an underscore and it is not a language
/// tag at all, so the recogniser quietly keeps whatever the page defaults to
/// and listens to a Russian sentence in English.
///
/// Kazakh recognition is not on every device; where it is missing the plugin
/// falls back to the system default rather than failing, which is the right
/// outcome — a Kazakh-speaking parent dictating into a phone set to Russian
/// gets Russian text she can correct, not an error.
String dictationLocale(String languageCode, {bool web = kIsWeb}) {
  final id = switch (languageCode) {
    'ru' => 'ru_RU',
    'kk' => 'kk_KZ',
    _ => 'en_US',
  };
  return web ? id.replaceAll('_', '-') : id;
}
