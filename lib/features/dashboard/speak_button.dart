import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/voice/dictation.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// Speak from the home screen, and land in the assistant with it already said.
///
/// Voice was slower than tapping, which is the opposite of the point. To
/// record a feed by speaking she had to reach the assistant tab, then the
/// chat, then the microphone: six actions against three for the «Покормила»
/// card. This is two — press, speak — and the confirmation.
///
/// It dictates *here* rather than opening the chat and starting there. That is
/// not a detail: iOS Safari only opens a microphone inside the gesture that
/// asked for it, and a recogniser started after a navigation is a recogniser
/// that is refused. The words are carried to the chat as its initial question,
/// which it already knows how to send.
///
/// A single button and no field. The card that used to sit here — a text box,
/// a microphone and a line of instructions on top of every screen — is the
/// thing he asked to be rid of, and this is not that: it is the same size as
/// nothing, and on the days nobody presses it, it costs one row.
class SpeakButton extends ConsumerStatefulWidget {
  const SpeakButton({super.key});

  @override
  ConsumerState<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends ConsumerState<SpeakButton> {
  bool _listening = false;

  /// A belt to the plugin's braces, as in [VoiceNoteButton]: `listenFor` is
  /// the platform's promise, and this makes sure the button stops pulsing
  /// even where it is not kept.
  Timer? _cutoff;

  /// Held rather than read on demand: `dispose` closes the microphone, and by
  /// then `ref` is no longer safe to touch.
  Dictation? _dictation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dictation = ref.read(dictationProvider);
  }

  @override
  void dispose() {
    _cutoff?.cancel();
    unawaited(_dictation?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: PressScale(
        child: Material(
          color: Warm.soft(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.chipRadius),
          child: InkWell(
            onTap: _listening ? _stop : _start,
            borderRadius: BorderRadius.circular(Warm.chipRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_none,
                    size: 20,
                    color: Warm.accentOn(theme.brightness),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _listening ? l.voiceListening : l.homeSpeak,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Warm.onCard(theme.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final dictation = _dictation;
    if (dictation == null) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final locale = dictationLocale(
      Localizations.localeOf(context).languageCode,
    );

    // The call that raises the permission dialog, and it happens inside the
    // tap. Everything after it assumes the answer was yes.
    final ready = await dictation.prepare();
    if (!mounted) return;
    if (!ready) {
      // Once, quietly. The four cards above still work, and a shortcut that
      // nags is worse than no shortcut.
      messenger.showAppSnack(
        appSnack(l.voiceUnavailable, kind: SnackKind.info),
      );
      return;
    }

    setState(() => _listening = true);
    _cutoff?.cancel();
    _cutoff = Timer(DictationSession.maxDuration, _stop);

    await dictation.start(
      localeId: locale,
      onResult: _carry,
      onSilence: () {
        if (!mounted) return;
        _cutoff?.cancel();
        setState(() => _listening = false);
      },
    );
  }

  Future<void> _stop() async {
    _cutoff?.cancel();
    await _dictation?.stop();
    if (!mounted) return;
    setState(() => _listening = false);
  }

  /// Hands what was said to the assistant, which decides whether it is a
  /// record or a question — the same [recordIn] split the typed field uses.
  void _carry(String text) {
    if (!mounted) return;
    _cutoff?.cancel();
    setState(() => _listening = false);

    final said = text.trim();
    if (said.isEmpty) return;
    context.go('$chatPath?q=${Uri.encodeQueryComponent(said)}');
  }
}
