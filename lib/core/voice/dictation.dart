import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

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

  /// Whether the microphone is actually open, as opposed to asked for.
  ///
  /// The second or so between the two is long enough to be seen, so it is
  /// shown rather than pretended away.
  bool get live;

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
  // No pauseFor, and this one is not a preference either. The wrapper's
  // pause timer measures silence from the last *speech event*, and the web
  // plugin never reports sound levels — so the timer never sees anything at
  // all and fires on schedule every time, cancelling the recognition with
  // `aborted` and discarding whatever it had. On a phone it fired at five
  // seconds, twice, before a sentence was finished.
  //
  // The recording ends when she says it does, or at [maxDuration].
  localeId: localeId,
  // The words are wanted, not a command: dictation mode rather than the
  // confirmation mode tuned for "yes" and "cancel".
  listenMode: ListenMode.dictation,
  // False, and the browser path does not go through the layer that made
  // this a dilemma. `speech_to_text_web` sets both `interimResults` and
  // `continuous` from this one flag: with it on, Safari on iOS holds an
  // open microphone for nine seconds and returns nothing at all. With it
  // off Safari behaves, and the wrapper that would have discarded the
  // result is bypassed — see [PlatformDictation._direct].
  partialResults: false,
  cancelOnError: true,
);

/// Session limits, kept where both the controller and its tests can see them.
abstract final class DictationSession {
  /// Half a minute is longer than any note in this app has ever been, and
  /// short enough that a phone left face-down on a bed stops listening on its
  /// own.
  static const maxDuration = Duration(seconds: 30);

  /// How long a silence the *native* recognisers treat as the end.
  ///
  /// Not passed on the web: see the note in [dictationOptions]. Five rather
  /// than three, because "покормила левой... минут пятнадцать" has a gap in
  /// the middle of it and three seconds kept only the first half.
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

  /// Whether to talk to the platform plugin underneath `SpeechToText`.
  ///
  /// On the web, yes, and not by preference. `speech_to_text_web` builds
  /// every result with `resultType` hardcoded to partial, and
  /// `SpeechToText._notifyResults` drops non-final results unless partial
  /// results are asked for — but asking for them sets
  /// `SpeechRecognition.continuous`, which Safari on iOS answers with an
  /// open microphone and silence. The two settings that have to disagree are
  /// the same field, so the browser path uses the interface the wrapper
  /// itself sits on and does its own assembling.
  ///
  /// Phones keep the wrapper: it handles permissions, locales and the
  /// platform's own idea of when a sentence has ended, none of which is
  /// worth reimplementing where it already works.
  bool get _direct => kIsWeb;
  SpeechToTextPlatform get _plugin => SpeechToTextPlatform.instance;

  /// Set by the recogniser's own error callback, which is where the browser
  /// says *why* — `not-allowed`, `service-not-allowed`, `language-not-
  /// supported`. Swallowing it left a parent holding a button that did
  /// nothing and no way for anyone to find out what.
  String? _lastError;

  /// Recognitions that have already ended, in order.
  ///
  /// A browser recogniser stops the moment it decides a sentence is over,
  /// and it decides that in the middle of "покормила левой... минут
  /// пятнадцать". One recording is therefore not one recognition but
  /// several, restarted as each ends.
  final _segments = <String>[];

  /// The best reading of the recognition currently running.
  ///
  /// Every result the web layer sends is labelled partial, so there is no
  /// final one to wait for — the longest is the one to keep. A later result
  /// is usually longer, but a recogniser that has changed its mind about the
  /// opening words can come back shorter, and half a sentence is worse than
  /// the whole one it already had.
  String _current = '';

  String get _heard =>
      [..._segments, _current].where((p) => p.isNotEmpty).join(' ').trim();
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

  /// Whether the browser has confirmed it is actually listening.
  ///
  /// Asking is not starting. Safari takes one to two seconds between
  /// `start()` and the microphone being live, and a stop that lands inside
  /// that gap used to do nothing at all — `isListening` was still false, so
  /// there was nothing to stop, and the session then opened behind us and
  /// ran on with no one waiting for it.
  bool _live = false;
  bool _stopWanted = false;

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
  bool get busy => _sessionActive || _listening;

  bool get _listening => _direct ? _live : _speech.isListening;

  @override
  bool get live => _live;

  @override
  String? get unavailableReason => _ready ? null : _lastError;

  @override
  Future<bool> prepare() async {
    if (_ready) return true;
    if (_direct) return _prepareDirect();
    // initialize() is what raises the permission dialog, and it is safe to
    // call more than once — the plugin remembers.
    try {
      _ready = await _speech.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          _note('error ${error.errorMsg}'
              '${error.permanent ? ' (permanent)' : ''}');
        },
        onStatus: _onStatus,
      );
      _note('initialize $_ready');
    } catch (_) {
      // A device with no recogniser at all throws rather than returning
      // false. Same outcome for the parent either way.
      _ready = false;
    }
    return _ready && await _speech.hasPermission;
  }

  Future<bool> _prepareDirect() async {
    _plugin.onStatus = _onStatus;
    _plugin.onError = (raw) {
      final message = _fieldOf(raw, 'errorMsg') ?? raw;
      _lastError = message;
      _note('error $message');
    };
    _plugin.onTextRecognition = (raw) {
      final text = _firstAlternate(raw);
      _note('result "$text"');
      if (text.length > _current.length) _current = text;
    };

    try {
      _ready = await _plugin.initialize();
    } catch (_) {
      _ready = false;
    }
    _note('initialize $_ready');
    return _ready && await _plugin.hasPermission();
  }

  /// One field out of the JSON the plugin sends across, without building a
  /// model for two strings.
  String? _fieldOf(String raw, String key) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[key] as String?;
    } catch (_) {
      return null;
    }
  }

  /// The recogniser's best guess out of `{"alternates":[{"recognizedWords"…`.
  String _firstAlternate(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final alternates = map['alternates'] as List<dynamic>;
      if (alternates.isEmpty) return '';
      final first = alternates.first as Map<String, dynamic>;
      return (first['recognizedWords'] as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  void _onStatus(String status) {
    _note('status $status');
    if (status == 'listening') {
      _live = true;
      // The stop that arrived while it was still opening.
      if (_stopWanted) unawaited(_stopPlugin());
      return;
    }
    final wasLive = _live;
    _live = false;
    // The web layer never sends a final result, so the end of a recognition
    // is only ever announced as a change of status.
    if (wasLive) _endOfClause();
  }

  Future<void> _stopPlugin() async {
    if (_direct) {
      await _plugin.stop();
    } else if (_speech.isListening) {
      await _speech.stop();
    }
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
    _current = '';
    _trace.clear();
    _sessionStart = DateTime.now();
    _live = false;
    _stopWanted = false;
    _note('start requested, locale $localeId');
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
    if (_direct) {
      // Results arrive through the callback set in [_prepareDirect]; there
      // is no per-session listener to hand over here.
      await _plugin.listen(
        localeId: localeId,
        options: dictationOptions(localeId),
      );
      return;
    }

    await _speech.listen(
      // The plugin reports roughly -2..10 on iOS and 0..10 on Android;
      // normalised here so the waveform does not have to know either.
      onSoundLevelChange: onLevel == null
          ? null
          : (level) => onLevel((level / 10).clamp(0.0, 1.0)),
      onResult: (result) {
        final text = result.recognizedWords.trim();
        _note('result final=${result.finalResult} "$text"');
        if (text.length > _current.length) _current = text;
        // Native recognisers do mark a result final, and when one does the
        // clause is over even though the sentence may not be.
        if (result.finalResult) _endOfClause();
      },
      listenOptions: dictationOptions(localeId),
    );
  }

  /// One recognition has finished. Whether the recording has is a separate
  /// question, and only the person speaking answers it.
  void _endOfClause() {
    if (_current.isNotEmpty) {
      _segments.add(_current);
      _current = '';
    }
    if (_delivered) return;
    if (_holding) {
      unawaited(_resume());
    } else {
      _deliver();
    }
  }

  /// Listen again, because she has not stopped talking.
  ///
  /// The recogniser has to be given a moment to let go before it will start
  /// again — asking too early throws, which is the same refusal that used to
  /// break the second recording of the day. A restart that fails is not an
  /// error worth showing: it means this hold is over, and what was heard up
  /// to here is what gets written down.
  Future<void> _resume() async {
    for (var i = 0; i < 10 && _listening; i++) {
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
    _stopWanted = true;
    _note('stop requested, live=$_live');
    try {
      if (_listening) {
        await _stopPlugin();
      } else if (!_live) {
        // Still opening. Wait for it rather than walking away — a session
        // nobody stopped keeps the microphone and refuses the next one.
        for (var i = 0; i < 40 && !_live; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        if (_listening) await _stopPlugin();
      }
    } catch (_) {
      // Stopping something that has already stopped is not a problem worth
      // propagating.
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
    for (var i = 0; i < 20 && _listening; i++) {
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
  bool get live => false;

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
