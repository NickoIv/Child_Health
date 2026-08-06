import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/voice/cues.dart';
import '../../core/voice/dictation.dart';
import '../../core/voice/voice_commands.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Hold it, say it, read it back, save it.
///
/// The one place in the app where speech turns into a record, and it takes
/// four deliberate steps: a finger has to stay on the button, the microphone
/// closes when it lifts, what was heard is parsed on the device, and the
/// reading is shown as a card that a parent taps once more before anything is
/// written. Nothing is recorded, nothing is uploaded, nothing is listened for
/// at any other time.
///
/// A sentence it does not recognise becomes a note in her own words. That is
/// the failure mode this feature is designed around: a wrong guess costs a
/// mother a correction in a medical record, and a note costs her nothing.
class VoiceActionButton extends ConsumerStatefulWidget {
  const VoiceActionButton({required this.childId, super.key});

  final String childId;

  /// Held, not tapped.
  ///
  /// A tap that opens a microphone leaves a parent guessing when it closed; a
  /// held button is a walkie-talkie, and everyone already knows how one of
  /// those works. It also makes the accident impossible — a phone in a pocket
  /// cannot hold its own button down.
  static const size = 64.0;

  /// A ceiling rather than a target: releasing ends it sooner, which is the
  /// normal case.
  ///
  /// The same half minute the recogniser itself allows. Ten seconds was a
  /// second ceiling under the first one, and the one that fired — a sentence
  /// with a pause in the middle of it was being cut off by the button rather
  /// than by the person speaking.
  static const listenFor = DictationSession.maxDuration;

  @override
  ConsumerState<VoiceActionButton> createState() => _VoiceActionButtonState();
}

class _VoiceActionButtonState extends ConsumerState<VoiceActionButton> {
  bool _listening = false;
  bool _opening = false;
  DateTime? _startedAt;
  Timer? _cutoff;
  Timer? _ticker;

  /// The last handful of levels, newest last. Short on purpose: a waveform
  /// with a long memory is a chart, and this is a sign of life.
  final _levels = <double>[];

  /// Held rather than read on demand: `dispose` has to close the microphone,
  /// and by then `ref` is no longer safe to touch.
  Dictation? _dictation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dictation = ref.read(dictationProvider);
    if (identical(dictation, _dictation)) return;
    _dictation = dictation;
    // Woken here rather than on the first press. On the web this only
    // constructs the recogniser — it opens no microphone and asks for
    // nothing — but it means the press itself has nothing to wait for, and
    // Safari refuses a microphone that is asked for after the gesture that
    // asked for it has finished.
    if (!dictation.ready) unawaited(dictation.prepare());
  }

  @override
  void dispose() {
    _cutoff?.cancel();
    _ticker?.cancel();
    unawaited(_dictation?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // A viewer has nothing to write, so there is nothing here for him to say.
    if (ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // Listening is a state of the whole card, not a detail on it. A pulsing
    // ring around a 64px circle is invisible to someone holding a phone at
    // arm's length with a baby on the other arm; the card going warm under
    // her thumb is not.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Motion.curve,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        color: _listening
            ? Color.alphaBlend(
                Warm.accent.withValues(alpha: 0.16),
                Warm.card(theme.brightness),
              )
            : Warm.card(theme.brightness),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _listening ? Warm.accent : Colors.transparent,
          width: 2,
        ),
        boxShadow: _listening
            ? [
                BoxShadow(
                  color: Warm.accent.withValues(alpha: 0.30),
                  blurRadius: 26,
                  offset: const Offset(0, 6),
                ),
              ]
            : Warm.shadow(theme.brightness),
      ),
      child: Row(
        children: [
          // The instruction and, once she is speaking, the room's own volume
          // in the same place — so nothing moves under her thumb when the
          // microphone opens.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _listening ? l.voiceListening : l.voiceHoldHint,
                  style: TextStyle(
                    fontSize: _listening ? 17 : 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.25,
                    color: _listening
                        ? Warm.accent
                        : Warm.onCard(theme.brightness),
                  ),
                ),
                const SizedBox(height: 4),
                if (_listening)
                  SizedBox(
                    height: 34,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        levels: _levels,
                        color: Warm.accent,
                      ),
                    ),
                  )
                else
                  Text(
                    l.voiceExample,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: Warm.onCardSoft(theme.brightness),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            voiceTimer(_elapsed),
            style: TextStyle(
              fontSize: _listening ? 15 : 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: _listening
                  ? Warm.accent
                  : Warm.onCardSoft(theme.brightness),
            ),
          ),
          const SizedBox(width: 14),
          // Last in the row, so it lands under a right thumb. Everything to
          // the left of it is text, which is read once and never touched.
          Semantics(
            button: true,
            label: l.voiceQuickHint,
            child: GestureDetector(
              // A long press is what she means to do; a drag off the button is
              // what her thumb does when the baby moves. Either ending closes
              // the microphone.
              onLongPressStart: (_) => _start(),
              onLongPressEnd: (_) => _stop(),
              onLongPressCancel: _stop,
              onTap: () => _hint(l),
              child: MicPulse(
                listening: _listening,
                color: Warm.accent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Motion.curve,
                  width: _listening
                      ? VoiceActionButton.size + 8
                      : VoiceActionButton.size,
                  height: _listening
                      ? VoiceActionButton.size + 8
                      : VoiceActionButton.size,
                  decoration: BoxDecoration(
                    gradient: Warm.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Warm.accent.withValues(
                          alpha: _listening ? 0.45 : 0.28,
                        ),
                        blurRadius: _listening ? 28 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _listening ? Icons.graphic_eq : Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Duration get _elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  /// A tap is not how this works, and saying so once is kinder than doing
  /// nothing and letting her tap again.
  void _hint(AppLocalizations l) {
    if (_listening) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.voiceHoldHint)));
  }

  /// Deliberately not `async`.
  ///
  /// Everything between the finger landing and `dictation.start()` runs in
  /// the same turn of the event loop as the gesture that began it. Safari
  /// will not open a microphone otherwise: an `await` here — even one that
  /// completes immediately — resumes in a later microtask, and by then the
  /// browser no longer considers the request to be something the user asked
  /// for. This is why holding the button did nothing on an iPhone.
  void _start() {
    final dictation = _dictation;
    if (dictation == null || _listening || _opening) return;

    // The previous recording is still closing. Opening a second one on top
    // of it produces nothing and used to be reported as a failure to hear
    // her — so wait, and say so, rather than blaming the room.
    if (dictation.busy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).voiceBusy),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (dictation.ready) {
      _open(dictation);
    } else {
      // First hold on a device that has not woken its recogniser yet. This
      // path does await, and on iOS it may well be refused; the next hold
      // takes the synchronous path above and works.
      unawaited(_prepareThenOpen(dictation));
    }
  }

  Future<void> _prepareThenOpen(Dictation dictation) async {
    _opening = true;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ready = await dictation.prepare();
    _opening = false;
    if (!mounted) return;
    if (!ready) {
      _refused(l, messenger, dictation.unavailableReason);
      return;
    }
    _open(dictation);
  }

  /// Said no, and said why.
  ///
  /// "The microphone is unavailable" on its own is a dead end: it is the same
  /// sentence whether the permission was denied, the language is missing, or
  /// the browser has no recogniser at all. The reason comes from the browser
  /// and is worth more than the phrasing — an iPhone reports `not supported`
  /// when the app was opened from the home screen rather than in a Safari
  /// tab, which is a thing a parent can actually fix.
  void _refused(
    AppLocalizations l,
    ScaffoldMessengerState messenger,
    String? reason,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          reason == null ? l.voiceUnavailable : '${l.voiceUnavailable} ($reason)',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _open(Dictation dictation) {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final locale = dictationLocale(
      Localizations.localeOf(context).languageCode,
    );

    // Two confirmations at the moment the microphone opens, because her eyes
    // are on the child and not on the phone: one she feels, one she hears.
    // Light to start and firmer to stop, so the two ends of a recording are
    // told apart by touch alone.
    VoiceCues.start();

    setState(() {
      _listening = true;
      _startedAt = DateTime.now();
      _levels.clear();
    });

    _cutoff?.cancel();
    _cutoff = Timer(VoiceActionButton.listenFor, _stop);
    // Ten frames a second is enough for a timer counting whole seconds and a
    // waveform that looks alive, and it stops the moment she lets go.
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _listening) setState(() {});
    });

    // Called, not awaited: the microphone has to be asked for inside the
    // gesture, and there is nothing after this line that needs its answer.
    unawaited(
      dictation.start(
        localeId: locale,
        onResult: _heard,
        onLevel: (level) {
          if (!mounted || !_listening) return;
          _levels.add(level);
          if (_levels.length > _WaveformPainter.bars) _levels.removeAt(0);
        },
        onSilence: () {
          if (!mounted) return;
          _close();
          messenger.showSnackBar(SnackBar(content: Text(l.voiceFailed)));
        },
        // The browser's own reason, shown rather than swallowed. On an
        // iPhone this is the difference between "it doesn't work" and
        // "Safari refused the microphone".
        onFailure: (reason) {
          if (!mounted) return;
          _close();
          messenger.showSnackBar(
            SnackBar(content: Text('${l.voiceFailed} ($reason)')),
          );
        },
      ),
    );
  }

  Future<void> _stop() async {
    if (!_listening) return;
    VoiceCues.stop();
    _close();
    await _dictation?.stop();
  }

  void _close() {
    _cutoff?.cancel();
    _ticker?.cancel();
    if (mounted && _listening) {
      setState(() {
        _listening = false;
        _startedAt = null;
      });
    }
  }

  void _heard(String text) {
    if (!mounted) return;
    _close();

    final command = parseVoiceCommand(text);
    if (command.text.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ConfirmSheet(command: command, childId: widget.childId),
    );
  }
}

/// `mm:ss`, because a recording is a length of time and that is how one is
/// written down. Kept out of the widget so a test can read it.
String voiceTimer(Duration elapsed) {
  final minutes = elapsed.inMinutes;
  final seconds = elapsed.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Bars, newest on the right.
///
/// A level of nothing still draws a dot, so a silent room reads as listening
/// rather than as broken.
class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  /// Short on purpose: a waveform with a long memory is a chart, and this is
  /// a sign of life.
  static const bars = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    const count = bars;
    final step = size.width / count;
    for (var i = 0; i < count; i++) {
      // Right-aligned, so the newest level is the rightmost bar and the empty
      // slots at the start of a recording stay flat rather than jumping.
      final index = levels.length - count + i;
      final level = index >= 0 && index < levels.length ? levels[index] : 0.0;
      final height = 3 + level * (size.height - 3);
      final x = step * i + step / 2;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}

/// What was heard, what it will become, and one button.
///
/// It shows the sentence as well as the reading of it, because the reading is
/// a guess made by a regular expression in a noisy room, and the person who
/// said the words is the only one who can catch it being wrong.
class _ConfirmSheet extends ConsumerStatefulWidget {
  const _ConfirmSheet({required this.command, required this.childId});

  final VoiceCommand command;
  final String childId;

  @override
  ConsumerState<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends ConsumerState<_ConfirmSheet> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final command = widget.command;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.mic_none, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.voiceHeard, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Warm.soft(theme.brightness),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Her words, first and largest. The interpretation sits
                  // under them, where a wrong one is easy to spot.
                  Text(
                    command.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Warm.onCard(theme.brightness),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    voiceSummary(l, command),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Warm.onCardSoft(theme.brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(l.commonSave),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(l.commonCancel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    try {
      await ref.read(logRepositoryProvider).add(
        voiceLog(
          widget.command,
          childId: widget.childId,
          at: DateTime.now(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SuccessCheck(),
              const SizedBox(width: 10),
              Expanded(child: Text(l.quickSaved(voiceSummary(l, widget.command)))),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(l, e))));
    }
  }
}

/// One line saying what this will be written down as.
///
/// Kept out of the widget so a test can read it without building anything,
/// and phrased as the record rather than as a confirmation question — the
/// question is the button underneath it.
String voiceSummary(AppLocalizations l, VoiceCommand command) =>
    switch (command.intent) {
      VoiceIntent.temperature =>
        '${l.quickSheetTemperature}: '
            '${command.temperatureC!.toStringAsFixed(1)} °C',
      VoiceIntent.nappy =>
        '${l.quickSheetNappy}: '
            '${command.nappyKind!.localizedLabel(l).toLowerCase()}',
      VoiceIntent.sleep => [
        l.quickSheetSleep,
        if (command.minutes != null) localizedDuration(l, command.minutes!),
      ].join(': '),
      VoiceIntent.bottle => [
        '${l.quickSheetFeeding}: '
            '${FeedingSide.bottle.localizedLabel(l).toLowerCase()}',
        if (command.millilitres != null) '${command.millilitres} ${l.voiceMl}',
      ].join(', '),
      VoiceIntent.feeding => [
        l.quickSheetFeeding,
        if (command.side != null) command.side!.localizedLabel(l).toLowerCase(),
        if (command.minutes != null) localizedDuration(l, command.minutes!),
      ].join(', '),
      VoiceIntent.note => l.voiceAsNote,
    };
