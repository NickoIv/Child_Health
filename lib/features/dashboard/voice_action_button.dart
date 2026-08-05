import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
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
  static const size = 72.0;

  /// A ceiling rather than a target: releasing ends it sooner, which is the
  /// normal case. Long enough for "покормила левой пятнадцать минут".
  static const listenFor = Duration(seconds: 10);

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
    _dictation = ref.read(dictationProvider);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_listening) ...[
          _ListeningPanel(levels: _levels, elapsed: _elapsed),
          const SizedBox(height: 12),
        ],
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
              child: Container(
                width: VoiceActionButton.size,
                height: VoiceActionButton.size,
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
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ],
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

  Future<void> _start() async {
    final dictation = _dictation;
    if (dictation == null || _listening || _opening) return;
    _opening = true;

    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final locale = dictationLocale(
      Localizations.localeOf(context).languageCode,
    );

    // The call that raises the permission dialog.
    final ready = await dictation.prepare();
    _opening = false;
    if (!mounted) return;
    if (!ready) {
      messenger.showSnackBar(SnackBar(content: Text(l.voiceUnavailable)));
      return;
    }

    // Two confirmations at the moment the microphone opens, because her eyes
    // are on the child and not on the phone: one she feels, one she hears.
    // Light to start and firmer to stop, so the two ends of a recording are
    // told apart by touch alone.
    unawaited(HapticFeedback.lightImpact());
    unawaited(SystemSound.play(SystemSoundType.click));

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

    await dictation.start(
      localeId: locale,
      onResult: _heard,
      onLevel: (level) {
        if (!mounted || !_listening) return;
        _levels.add(level);
        if (_levels.length > _ListeningPanel.bars) _levels.removeAt(0);
      },
      onSilence: () {
        if (!mounted) return;
        _close();
        messenger.showSnackBar(SnackBar(content: Text(l.voiceFailed)));
      },
    );
  }

  Future<void> _stop() async {
    if (!_listening) return;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(SystemSound.play(SystemSoundType.click));
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

/// The panel above the microphone while it is open: a waveform and a timer.
///
/// It exists to answer one question — is this thing hearing me — and it
/// answers it with the room's own volume rather than with a spinner. It draws
/// only while a finger is down, so nothing here animates at rest.
class _ListeningPanel extends StatelessWidget {
  const _ListeningPanel({required this.levels, required this.elapsed});

  final List<double> levels;
  final Duration elapsed;

  static const bars = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Warm.card(theme.brightness),
        borderRadius: BorderRadius.circular(20),
        boxShadow: Warm.shadow(theme.brightness),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 26,
            width: bars * 6.0,
            child: CustomPaint(
              painter: _WaveformPainter(levels: levels, color: Warm.accent),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            voiceTimer(elapsed),
            style: theme.textTheme.labelMedium?.copyWith(
              color: Warm.onCardSoft(theme.brightness),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    const count = _ListeningPanel.bars;
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
