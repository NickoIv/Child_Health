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

/// The field itself, on the home screen, above the tabs.
///
/// Two taps and no more: one on this field, which raises the keyboard, and
/// one on the microphone the keyboard already has. A button of ours in front
/// of it made three, because Safari raises the keyboard for a tap that lands
/// on the input and not for a focus() called from somewhere else — so the
/// field had to be tapped anyway, and our button was a toll booth in front of
/// the thing that actually works.
///
/// The dictation is the phone's own, tuned by the people who made the phone.
/// The browser's speech API is not involved: it opened a microphone two
/// seconds late, refused to start twice, discarded its own results one layer
/// up, and is absent altogether when the app is opened from the home screen.
///
/// Typing into it does the same thing, which matters more than it looks: a
/// mother in a dark room next to a sleeping child cannot dictate at all.
class QuickDictationField extends ConsumerStatefulWidget {
  const QuickDictationField({required this.childId, super.key});

  final String childId;

  /// How long a silence in the text counts as "she has finished".
  ///
  /// Long enough to think mid-sentence, short enough not to be a wait. It is
  /// measured on the text rather than on the microphone, because the
  /// dictation belongs to the keyboard and this side only sees the words
  /// arriving.
  static const settle = Duration(seconds: 2);

  @override
  ConsumerState<QuickDictationField> createState() => _QuickDictationState();
}

class _QuickDictationState extends ConsumerState<QuickDictationField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _autoSave;
  bool _saving = false;

  @override
  void dispose() {
    _autoSave?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // A viewer has nothing to write, so there is nothing here for him to say.
    if (ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();

    final text = _controller.text.trim();
    final command = text.isEmpty ? null : parseVoiceCommand(text);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      decoration: BoxDecoration(
        color: Warm.card(theme.brightness),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: command == null ? Colors.transparent : Warm.accent,
          width: 2,
        ),
        boxShadow: Warm.shadow(theme.brightness),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    color: Warm.onCard(theme.brightness),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: l.voiceFieldHint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Warm.onCardSoft(theme.brightness),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _armAutoSave();
                  },
                  onSubmitted: (_) => unawaited(_save()),
                ),
              ),
              const SizedBox(width: 8),
              // Not a recorder. It is a reminder of where the dictation is,
              // and a bigger target than the field for a thumb — tapping it
              // raises the same keyboard.
              Semantics(
                button: true,
                label: l.voiceQuickHint,
                child: GestureDetector(
                  onTap: _focus.requestFocus,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: Warm.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Warm.accent.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),

          // What it will become, once there is anything to read. The reading
          // is a guess made by a regular expression, and the person who said
          // the words is the only one who can catch it being wrong.
          if (command != null) ...[
            const SizedBox(height: 6),
            Text(
              '${l.voiceWillSave}: ${voiceSummary(l, command)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Warm.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Saving is a tap that only ever confirms something already on screen.
  ///
  /// Two seconds after the words stop arriving the entry writes itself and
  /// the snackbar offers to undo it. An undo protects a misheard sentence
  /// exactly as well as a confirmation button does, and costs nothing on the
  /// hundreds of readings that were right.
  void _armAutoSave() {
    _autoSave?.cancel();
    if (_controller.text.trim().isEmpty) return;
    _autoSave = Timer(QuickDictationField.settle, () {
      if (mounted && !_saving) unawaited(_save());
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;

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
      // Cleared and closed: the next thing she writes down is a new one, and
      // a keyboard left up covers half the screen she came back to read.
      _controller.clear();
      _focus.unfocus();
      setState(() => _saving = false);

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SuccessCheck(),
              const SizedBox(width: 10),
              Expanded(child: Text(l.quickSaved(voiceSummary(l, command)))),
            ],
          ),
          // Long, because nobody pressed anything: the undo is the only
          // thing between a misheard sentence and a medical record.
          duration: const Duration(seconds: 6),
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
