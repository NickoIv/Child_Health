import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/voice/dictation.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// A microphone beside the note field, and nothing behind it.
///
/// It fills in a text field. That is the entire feature: no command parsing,
/// no intent, no model, nothing saved without the parent pressing save. What
/// it buys is the one thing typing cannot — a note written with a child on
/// one arm, at the hour when the note is worth having and the keyboard is
/// not.
///
/// If the microphone is refused or missing, this says so once, quietly, and
/// gets out of the way. The keyboard was always the primary way in; this is
/// a shortcut, and a shortcut that nags is worse than no shortcut.
class VoiceNoteButton extends ConsumerStatefulWidget {
  const VoiceNoteButton({
    required this.controller,
    required this.field,
    super.key,
  });

  /// The note field this dictates into.
  final TextEditingController controller;

  /// The field itself, passed in rather than built here: the microphone sits
  /// beside it and the status line runs full width underneath, which only
  /// works if one widget owns both rows.
  final Widget field;

  @override
  ConsumerState<VoiceNoteButton> createState() => _VoiceNoteButtonState();
}

enum _VoiceState { idle, listening, refused, failed }

class _VoiceNoteButtonState extends ConsumerState<VoiceNoteButton> {
  _VoiceState _state = _VoiceState.idle;

  /// A belt to the plugin's braces. `listenFor` is honoured by the platform;
  /// this makes sure the interface stops pulsing even if it is not.
  Timer? _cutoff;

  /// Held rather than read on demand: `dispose` has to close the microphone,
  /// and by then the element is deactivated and `ref` is no longer safe to
  /// touch. A sheet that is dismissed mid-sentence must still stop listening.
  Dictation? _dictation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dictation = ref.read(dictationProvider);
  }

  @override
  void dispose() {
    _cutoff?.cancel();
    // Fire and forget: the widget is going away either way, and awaiting a
    // platform channel in dispose is how a sheet ends up unable to close.
    unawaited(_dictation?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final listening = _state == _VoiceState.listening;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: widget.field),
            _MicButton(
              listening: listening,
              tooltip: listening ? l.voiceStop : l.voiceDictate,
              onPressed: listening ? _stop : _start,
            ),
          ],
        ),
        // Under the pair, full width. Squeezed in beside the field it was two
        // words wide in Kazakh.
        switch (_state) {
          // Two lines while listening: the first says the app is holding the
          // door open, the second says whose turn it is.
          _VoiceState.listening => Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Row(
              children: [
                Text(
                  l.voiceListening,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.voiceSpeakNow,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Both failures read the same way on purpose: something did not
          // work, the keyboard still does, nobody is at fault.
          _VoiceState.refused => _Quiet(text: l.voiceUnavailable),
          _VoiceState.failed => _Quiet(text: l.voiceFailed),
          _VoiceState.idle => const SizedBox.shrink(),
        },
      ],
    );
  }

  Future<void> _start() async {
    final dictation = _dictation;
    if (dictation == null) return;
    final locale = dictationLocale(Localizations.localeOf(context).languageCode);

    // This is the call that raises the permission dialog. Everything after it
    // assumes the answer was yes.
    final ready = await dictation.prepare();
    if (!mounted) return;
    if (!ready) {
      setState(() => _state = _VoiceState.refused);
      return;
    }

    setState(() => _state = _VoiceState.idle);
    setState(() => _state = _VoiceState.listening);

    _cutoff?.cancel();
    _cutoff = Timer(DictationSession.maxDuration, _stop);

    await dictation.start(
      localeId: locale,
      onResult: _insert,
      onSilence: () {
        if (!mounted) return;
        _cutoff?.cancel();
        setState(() => _state = _VoiceState.failed);
      },
    );
  }

  Future<void> _stop() async {
    _cutoff?.cancel();
    await _dictation?.stop();
    if (!mounted) return;
    // Back to idle rather than to an error: stopping on purpose is not a
    // failure, and the result may still be on its way.
    if (_state == _VoiceState.listening) {
      setState(() => _state = _VoiceState.idle);
    }
  }

  /// Appends, never replaces.
  ///
  /// Someone who typed half a note and then reached for the microphone meant
  /// to add to it. Overwriting what she had already written would be the
  /// single most expensive bug this button could have.
  void _insert(String text) {
    if (!mounted) return;
    _cutoff?.cancel();

    final existing = widget.controller.text.trimRight();
    final joined = existing.isEmpty ? text : '$existing $text';
    widget.controller.value = TextEditingValue(
      text: joined,
      selection: TextSelection.collapsed(offset: joined.length),
    );

    setState(() => _state = _VoiceState.idle);
  }
}

/// The circle that pulses.
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.listening,
    required this.tooltip,
    required this.onPressed,
  });

  final bool listening;
  final String tooltip;
  final VoidCallback onPressed;

  static const size = 48.0;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening == old.listening) return;
    if (widget.listening) {
      _pulse.repeat(reverse: true);
    } else {
      // Stopped, not reset to zero: a ring that vanishes mid-breath is more
      // noticeable than one that finishes the breath it was on.
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = SoftTone.rose;
    final ink = widget.listening
        ? tone.ink(theme.brightness)
        : theme.colorScheme.primary;

    return Tooltip(
      message: widget.tooltip,
      child: SizedBox(
        width: _MicButton.size + 16,
        height: _MicButton.size + 16,
        child: Center(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              // A halo that grows and fades rather than a button that grows:
              // the tap target has to stay exactly where the finger left it.
              final t = _pulse.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.listening)
                    Container(
                      width: _MicButton.size + 16 * t,
                      height: _MicButton.size + 16 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ink.withValues(alpha: 0.22 * (1 - t)),
                      ),
                    ),
                  child!,
                ],
              );
            },
            child: Material(
              color: widget.listening
                  ? tone.fill(theme.brightness)
                  : Warm.soft(theme.brightness),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onPressed,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: _MicButton.size,
                  height: _MicButton.size,
                  child: Icon(
                    widget.listening ? Icons.stop_rounded : Icons.mic_none,
                    color: ink,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
