import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/voice/voice_commands.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/widgets.dart';
import 'voice_action_button.dart';

/// Speak into the keyboard, or write it.
///
/// The browser's own speech recognition is a maze — it opens a microphone
/// two seconds late, refuses to run twice, discards its own results one
/// layer up, and is simply absent when the app is opened from the home
/// screen. The phone has a recogniser that does none of that, tuned by the
/// people who made the phone, and every text field in the world already
/// reaches it: it is the microphone on the keyboard.
///
/// It cannot be pressed from here — there is no API for that and there
/// should not be — so this asks for the one tap that starts it and gets out
/// of the way. What comes back is read by the same parser the spoken path
/// used, and a sentence it does not recognise becomes a note in her own
/// words, exactly as before.
///
/// The field is also the answer to a question nobody had asked out loud: a
/// mother in a quiet room with a sleeping child cannot dictate at all.
Future<void> showDictationSheet(
  BuildContext context, {
  required String childId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _DictationSheet(childId: childId),
);

class _DictationSheet extends ConsumerStatefulWidget {
  const _DictationSheet({required this.childId});

  final String childId;

  @override
  ConsumerState<_DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends ConsumerState<_DictationSheet> {
  /// How long a silence in the text counts as "she has finished".
  ///
  /// Long enough to think mid-sentence, short enough not to be a wait. It is
  /// measured on the text rather than on the microphone, because the
  /// dictation belongs to the keyboard and this side only sees the words
  /// arriving.
  static const settle = Duration(seconds: 2);

  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _saving = false;
  Timer? _autoSave;

  @override
  void initState() {
    super.initState();
    // Focused immediately, so the keyboard — and the microphone on it — is
    // already up. Anything less is a second tap before the tap that matters.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Saving is the third tap, and the third tap is the one worth removing.
  ///
  /// Two seconds after the words stop arriving it writes the entry itself
  /// and offers to undo it. A confirmation button protects against a wrong
  /// reading; so does an undo, and an undo does not cost a tap on the
  /// hundreds of readings that were right.
  void _armAutoSave() {
    _autoSave?.cancel();
    if (_controller.text.trim().isEmpty) return;
    _autoSave = Timer(settle, () {
      if (mounted && !_saving) unawaited(_save(automatic: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = _controller.text.trim();
    final command = text.isEmpty ? null : parseVoiceCommand(text);

    return Padding(
      // Above the keyboard, which is the whole point of this sheet.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.mic_none, color: Warm.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.voiceSheetTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l.voiceKeyboardHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Warm.onCardSoft(theme.brightness),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 17, height: 1.35),
                decoration: InputDecoration(hintText: l.voiceExample),
                onChanged: (_) {
                  setState(() {});
                  _armAutoSave();
                },
              ),
              const SizedBox(height: 12),

              // What it will become, updating as she speaks. The reading is a
              // guess made by a regular expression, and the person who said
              // the words is the only one who can catch it being wrong.
              Arrival(
                key: ValueKey(command?.intent),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Warm.soft(theme.brightness),
                    borderRadius: BorderRadius.circular(Warm.cardRadius),
                  ),
                  child: Text(
                    command == null
                        ? l.voiceNothingYet
                        : '${l.voiceWillSave}: ${voiceSummary(l, command)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: command == null
                          ? Warm.onCardSoft(theme.brightness)
                          : Warm.onCard(theme.brightness),
                      fontWeight: command == null
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: command == null || _saving ? null : () => _save(),
                icon: const Icon(Icons.check),
                label: Text(command == null ? l.commonSave : l.voiceSavingSoon),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(l.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save({bool automatic = false}) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _autoSave?.cancel();
    final command = parseVoiceCommand(text);
    final entry = voiceLog(
      command,
      childId: widget.childId,
      at: DateTime.now(),
    );
    final logs = ref.read(logRepositoryProvider);
    setState(() => _saving = true);

    try {
      await logs.add(entry);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SuccessCheck(),
              const SizedBox(width: 10),
              Expanded(child: Text(l.quickSaved(voiceSummary(l, command)))),
            ],
          ),
          // Longer when nobody pressed anything: the undo is the only thing
          // standing between a misheard sentence and a medical record.
          duration: Duration(seconds: automatic ? 6 : 2),
          action: SnackBarAction(
            label: l.commonUndo,
            onPressed: () => logs.delete(entry.id),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(l, e))));
    }
  }
}
