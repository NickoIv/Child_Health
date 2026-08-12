import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ai/actions.dart';
import '../../ai/assistant_service.dart';
import '../../ai/conversation.dart';
import '../../ai/topics.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/voice/voice_commands.dart';
import '../dashboard/voice_note_button.dart';
import '../../knowledge/article.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../../core/care/conversation_memory.dart';
import '../shared/voice_summary.dart';
import '../shared/widgets.dart';
import 'action_card.dart';
import 'chat_record.dart';

/// One line of the thread: a question, an answer, or an entry that was written.
class _Turn {
  const _Turn.question(this.text) : reply = null, written = null;
  const _Turn.answer(this.reply) : text = '', written = null;
  const _Turn.written(this.written) : text = '', reply = null;

  final String text;
  final AssistantReply? reply;

  /// What the diary now holds, for a message that turned out to be a record.
  final _Written? written;

  bool get isQuestion => reply == null && written == null;
}

/// An entry written from the thread, and the words it was read from.
class _Written {
  const _Written({required this.entry, required this.command});

  final DevelopmentLog entry;
  final VoiceCommand command;
}

/// The assistant, in conversation.
///
/// It answers anything; the knowledge base is preferred where it has something
/// and named as the source when it does — see lib/ai/assistant_service.dart.
/// The one thing it never sees is a question the red-flag gate stopped.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialQuestion});

  /// A question carried in from somewhere else — the article search, so far.
  /// It is sent on arrival: whoever typed it has already pressed enter once.
  final String? initialQuestion;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final carried = widget.initialQuestion?.trim() ?? '';
    if (carried.isEmpty) {
      _raiseKeyboard();
      return;
    }
    // After the first frame: `_send` reads providers and shows a snackbar on
    // failure, neither of which is available while the tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _send(carried));
  }

  /// The keyboard, up with the window.
  ///
  /// «Открывается окно, дальше поле ввода снова нажимаем и появляется
  /// клавиатура — это очень долго.» It was two taps to start typing and the
  /// second one bought nothing. `requestFocus` alone is not enough in a
  /// browser: focus and the on-screen keyboard are separate things there, and
  /// the keyboard only comes up when the engine is told to show it.
  void _raiseKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  /// The newest message, in view. A thread that answers below the fold is a
  /// thread that looks like it did not answer.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: Motion.normal,
        curve: Motion.curve,
      );
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// A conversation, and nothing else on the screen.
  ///
  /// «В окне ИИ не должно быть никакой лишней информации.» What was here: five
  /// facts about the child, the previous question, a panel of suggestions, a
  /// setup card and a paragraph of disclaimer — above and below a thread that
  /// had to be scrolled past all of it. None of it was the conversation.
  ///
  /// The child's context still reaches the model; it is in the prompt, where
  /// it belongs, rather than printed at the parent who already knows it.
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);

    // Its own Scaffold, because it is its own window now: inside the shell it
    // borrowed one, and without it a TextField has no Material to sit on.
    return Scaffold(
      appBar: AppBar(
        title: Text(l.chatTitle),
        titleTextStyle: theme.textTheme.titleMedium,
        // A window closes; it does not navigate. Popping puts the parent back
        // on the screen she asked from.
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.close),
          tooltip: l.commonClose,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _turns.isEmpty
                  ? _Empty(childName: child?.name)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: _turns.length + (_busy ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _turns.length) return const _Thinking();
                        final turn = _turns[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: switch (turn) {
                            _Turn(written: final written?) => _RecordCard(
                              written: written,
                            ),
                            _Turn(reply: final reply?) => _ReplyView(
                              reply: reply,
                            ),
                            _ => _QuestionBubble(text: turn.text),
                          },
                        );
                      },
                    ),
            ),
            _Ask(
              controller: _input,
              focus: _focus,
              hint: l.chatAsk,
              busy: _busy,
              onSend: () => _send(_input.text),
            ),
          ],
        ),
      ),
    );
  }

  /// The thread so far, minus the question being sent.
  ///
  /// Only real exchanges travel: an emergency card and an "unavailable"
  /// notice are the app talking, not the assistant, and replaying them as
  /// model turns would teach it to produce them.
  List<ChatTurn> _history() {
    final turns = <ChatTurn>[];
    for (final turn in _turns) {
      if (turn.isQuestion) {
        turns.add(ChatTurn.parent(turn.text));
      } else if (turn.reply case AssistantAnswer(:final text)) {
        turns.add(ChatTurn.assistant(text));
      }
    }
    // The question just appended to _turns is the one being asked.
    if (turns.isNotEmpty && turns.last.isParent) turns.removeLast();
    return turns;
  }

  Future<void> _send(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || _busy) return;

    // A sentence that is a record is written here and now, without the model
    // being called at all — see [recordIn]. This is where the home screen's
    // microphone went.
    if (await _write(question)) return;

    // Only ever the latest one, and only on this phone.
    ref.read(conversationMemoryProvider.notifier).remember(question);

    setState(() {
      _turns.add(_Turn.question(question));
      _input.clear();
      _busy = true;
    });
    _scrollToEnd();

    final child = ref.read(selectedChildProvider);
    final reply = await ref
        .read(assistantServiceProvider)
        .ask(
          question: question,
          ageMonths: child?.ageInMonths,
          childContext: ref.read(assistantChildContextProvider),
          // Everything before the question just added, so a follow-up like
          // «а если не поможет?» is answered instead of misread.
          history: _history(),
        );

    if (!mounted) return;
    setState(() {
      _turns.add(_Turn.answer(reply));
      _busy = false;
    });
    _scrollToEnd();
  }

  /// Writes the message down if it was a record, and says whether it did.
  ///
  /// False sends the same words on to the assistant, which is the ordinary
  /// case: only a sentence the on-device parser recognises, or one that begins
  /// «запиши…», is filed rather than answered.
  ///
  /// It writes without asking, and offers the entry back. A confirmation
  /// button in front of a reading that is right hundreds of times is a tap
  /// paid every time to catch the rare miss; an undo catches the same miss and
  /// costs nothing when the reading was right — the arrangement the dictation
  /// card settled on, kept.
  Future<bool> _write(String message) async {
    final child = ref.read(selectedChildProvider);
    // A viewer's repository refuses writes anyway, and his questions are still
    // worth answering.
    if (child == null || ref.read(isReadOnlyProvider)) return false;

    final command = recordIn(message, now: DateTime.now());
    if (command == null) return false;

    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final entry = voiceLog(command, childId: child.id, at: DateTime.now());

    setState(() {
      _turns.add(_Turn.question(message));
      _input.clear();
      _busy = true;
    });
    _scrollToEnd();

    try {
      final saved = await ref.read(logRepositoryProvider).add(entry);
      if (!mounted) return true;
      setState(() {
        _turns.add(
          _Turn.written(_Written(entry: saved, command: command)),
        );
        _busy = false;
      });
    } on Exception catch (e) {
      if (!mounted) return true;
      setState(() => _busy = false);
      messenger.showApp(friendlyError(l, e), kind: SnackKind.problem);
    }

    _scrollToEnd();
    return true;
  }
}

/// Before the first question.
///
/// One line and a glyph. Every other chat in the world opens like this, and
/// the panel of suggested questions that used to be here was both clutter and
/// the thing that made the assistant look like a menu of canned answers.
class _Empty extends StatelessWidget {
  const _Empty({this.childName});

  final String? childName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 40,
              color: Warm.accent.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 14),
            Text(
              childName == null ? l.chatEmpty : l.chatOpening(childName!),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Warm.onCardSoft(theme.brightness),
              ),
            ),
            const SizedBox(height: 10),
            // The one thing about this field nobody would guess: it also
            // writes the diary. The microphone that used to say so was on the
            // home screen, and it is gone — so the sentence it was captioned
            // with is here, where the field is.
            Text(
              l.chatOrRecord,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Warm.onCardSoft(theme.brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What was written down, and the way back out of it.
///
/// The undo lives in the thread rather than in a snackbar. A snackbar has four
/// seconds and then the record is somebody's problem in the diary; this stays
/// for as long as the conversation is open, which is how long a parent might
/// take to look up from the child and read what she just said.
class _RecordCard extends ConsumerStatefulWidget {
  const _RecordCard({required this.written});

  final _Written written;

  @override
  ConsumerState<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends ConsumerState<_RecordCard> {
  bool _undone = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final written = widget.written;

    return AppCard(
      color: Warm.soft(theme.brightness),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Row(
          children: [
            Icon(
              _undone ? Icons.undo : Icons.check_circle_outline,
              size: 20,
              color: _undone
                  ? theme.colorScheme.onSurfaceVariant
                  : StatusColors.normal,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _undone
                    ? l.chatRecordUndone
                    // The same sentence the diary will show, built from the
                    // same reading — so what she is told was written and what
                    // she finds when she goes to look cannot drift apart.
                    : l.quickSaved(voiceSummary(l, written.command)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!_undone) ...[
              const SizedBox(width: 6),
              TextButton(
                onPressed: _busy ? null : _undo,
                child: Text(l.commonUndo),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _undo() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      await ref.read(logRepositoryProvider).delete(widget.written.entry.id);
      if (!mounted) return;
      setState(() {
        _undone = true;
        _busy = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showApp(friendlyError(l, e), kind: SnackKind.problem);
    }
  }
}

/// The gap between asking and being answered, said out loud.
class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// The field, and the button that sends it. Nothing else.
///
/// There was a microphone here for one deploy, sitting next to the keyboard's
/// own: «возле клавиатуры значок микрофона, он не нужен там». It was not —
/// the keyboard already carries the recogniser worth using, it is the one
/// Apple and Google tuned for these languages, and it is where a thumb already
/// goes. The app's job is to open the keyboard, which it now does on arrival.
class _Ask extends ConsumerStatefulWidget {
  const _Ask({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final bool busy;
  final VoidCallback onSend;

  @override
  ConsumerState<_Ask> createState() => _AskState();
}

class _AskState extends ConsumerState<_Ask> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Warm.card(theme.brightness),
        border: Border(top: BorderSide(color: Warm.hairline(theme.brightness))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            // The microphone belongs here more than anywhere else in the app,
            // and until now this was the one field that did not have one.
            //
            // Everything else was already in place: this field both writes a
            // feed down and answers a question — see [recordIn] — and the
            // assistant can open a screen or create a reminder from what it
            // reads. All of it needed a keyboard, which is the one thing a
            // mother holding a baby at four in the morning does not have a
            // hand for. Dictation existed and reached exactly one note field
            // in a sheet.
            //
            // The same [VoiceNoteButton] as that note field, deliberately: it
            // appends rather than replaces, it opens the microphone inside
            // the tap — which is the only way iOS Safari allows it at all —
            // and it says so quietly and gets out of the way when refused.
            // Nothing is sent by speaking; the words land in the field and
            // she still presses send.
            child: VoiceNoteButton(
              controller: widget.controller,
              field: TextField(
                controller: widget.controller,
                focusNode: widget.focus,
                autofocus: true,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: widget.busy ? null : widget.onSend,
            icon: const Icon(Icons.arrow_upward),
            tooltip: l.chatSend,
          ),
        ],
      ),
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _ReplyView extends StatelessWidget {
  const _ReplyView({required this.reply});

  final AssistantReply reply;

  @override
  Widget build(BuildContext context) {
    return switch (reply) {
      AssistantEmergency(:final matched) => _EmergencyCard(matched: matched),
      AssistantAnswer(:final text, :final sources, :final action, :final mode) =>
        _AnswerCard(
          text: text,
          sources: sources,
          action: action,
          mode: mode,
        ),
      AssistantUnavailable(:final reason, :final isConfigurationIssue) =>
        _UnavailableCard(
          reason: reason,
          isConfigurationIssue: isConfigurationIssue,
        ),
    };
  }
}

/// Shown when the deterministic gate fires. The model was not called.
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.matched});

  final List<String> matched;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      color: StatusColors.alert.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: StatusColors.alert,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l.chatEmergency,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: StatusColors.alert,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l.chatEmergencyBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final m in matched)
                  Chip(
                    label: Text(m),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: StatusColors.alert.withValues(alpha: 0.16),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.go('/assistant/article/red-flags'),
              icon: const Icon(Icons.list_alt),
              label: Text(l.chatWhatToDo),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.text,
    required this.sources,
    required this.mode,
    this.action,
  });

  final String text;
  final List<KbArticle> sources;
  final AssistantAction? action;

  /// Where the answer came from.
  final AnswerMode mode;

  /// What to say under the answer, or null when the base is already listed
  /// beneath it as the source.
  String? _notice(AppLocalizations l) => switch (mode) {
    AnswerMode.fromBase => null,
    AnswerMode.general => l.chatGeneralAnswer,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text, style: theme.textTheme.bodyMedium),
            if (_notice(l) case final notice?) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Under the answer, not instead of it: the parent decides with
            // the reasoning in front of her, and declining costs nothing.
            if (action != null) AssistantActionCard(action: action!),
            if (sources.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l.chatSources,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final s in sources)
                    ActionChip(
                      label: Text(s.title),
                      onPressed: () =>
                          context.go('/assistant/article/${s.id}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({
    required this.reason,
    required this.isConfigurationIssue,
  });

  final String reason;
  final bool isConfigurationIssue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      color: Warm.soft(theme.brightness),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isConfigurationIssue
                  ? Icons.settings_outlined
                  : Icons.cloud_off_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reason, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () => context.go('/assistant'),
                    child: Text(l.chatOpenKb),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
