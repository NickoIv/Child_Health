import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ai/actions.dart';
import '../../ai/assistant_service.dart';
import '../../ai/conversation.dart';
import '../../ai/suggested_questions.dart';
import '../../ai/topics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/voice/dictation.dart';
import '../../knowledge/article.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../../core/care/conversation_memory.dart';
import '../shared/widgets.dart';
import 'action_card.dart';
import 'context_block.dart';
import 'continue_block.dart';

class _Turn {
  const _Turn.question(this.text) : reply = null;
  const _Turn.answer(this.reply) : text = '';

  final String text;
  final AssistantReply? reply;

  bool get isQuestion => reply == null;
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
  final _turns = <_Turn>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final carried = widget.initialQuestion?.trim() ?? '';
    if (carried.isEmpty) {
      // Voice first: on the web the recogniser worth using is the one on the
      // keyboard, and raising the keyboard is what puts its microphone under
      // a thumb. Nothing is recorded and nothing is sent — the field is
      // simply ready for whichever way she prefers to fill it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
      return;
    }
    // After the first frame: `_send` reads providers and shows a snackbar on
    // failure, neither of which is available while the tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _send(carried));
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    final service = ref.watch(assistantServiceProvider);

    // Its own Scaffold, because it is its own window now: inside the shell it
    // borrowed one, and without it a TextField has no Material to sit on and
    // the input row overflows by the width of an unbounded constraint.
    return Scaffold(
      body: SafeArea(child: _body(context, l, theme, child, service)),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    Child? child,
    AssistantService service,
  ) {
    return PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.chatTitle, style: theme.textTheme.titleLarge),
            ),
            // A window closes; it does not navigate. Popping puts the parent
            // back on the screen she asked from, which is the whole reason
            // the conversation lives above the shell rather than in it.
            IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
              icon: const Icon(Icons.close),
              tooltip: l.commonClose,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // The same five facts the assistant screen opens with, then the
        // thread she was in the middle of. Both sit above the conversation
        // and disappear entirely when there is nothing to say.
        const ChildContextBlock(),
        const SizedBox(height: 12),
        ContinueBlock(onResume: _resume),

        if (!service.isConfigured) ...[
          const _SetupCard(),
          const SizedBox(height: 16),
        ],

        if (_turns.isEmpty) _Suggestions(onPick: _send),

        for (final turn in _turns) ...[
          if (turn.isQuestion)
            _QuestionBubble(text: turn.text)
          else
            _ReplyView(reply: turn.reply!),
          const SizedBox(height: 12),
        ],

        if (_busy) ...[
          const SizedBox(height: 8),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 8),
        _Ask(
          controller: _input,
          focus: _focus,
          hint: child == null ? l.chatEmpty : l.chatHint(child.name),
          busy: _busy,
          onSend: () => _send(_input.text),
        ),
        const SizedBox(height: 12),
        Text(
          l.chatDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Puts the question back in the field rather than sending it: she may
  /// want to change a word now that she has a moment.
  void _resume(String question) {
    setState(() {
      _input.text = question;
      _input.selection = TextSelection.collapsed(offset: question.length);
    });
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

    // Only ever the latest one, and only on this phone.
    ref.read(conversationMemoryProvider.notifier).remember(question);

    setState(() {
      _turns.add(_Turn.question(question));
      _input.clear();
      _busy = true;
    });

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
  }
}

/// Asking, with the voice first.
///
/// «Ввод должен производиться текстом, но сначала голосовой ввод в
/// приоритете» — so the microphone is a full-sized accent disc at the left of
/// the row and the field is what it hands its words to. Neither replaces the
/// other: a question asked at three in the morning is spoken, and the same
/// question in a waiting room is typed.
///
/// What the microphone does depends on where the app is running.
/// [keyboardDictationProvider] is true in a browser, and there the recogniser
/// worth using is the keyboard's own — it is the one Apple and Google tuned
/// for these languages, it survives an iPhone home-screen app where the Web
/// Speech API is absent entirely, and it is one tap from a focused field. So
/// on the web the button raises the keyboard and says where its microphone
/// is. On a phone build it holds the recogniser open directly.
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

  /// Big enough to hit without looking, which is the point of speaking.
  static const micSize = 52.0;

  @override
  ConsumerState<_Ask> createState() => _AskState();
}

class _AskState extends ConsumerState<_Ask> {
  bool _listening = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final keyboard = ref.watch(keyboardDictationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _MicButton(
              live: _listening,
              onTap: () => keyboard ? _useKeyboard() : _hold(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focus,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(hintText: widget.hint),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: widget.busy ? null : widget.onSend,
              icon: const Icon(Icons.arrow_upward),
              tooltip: l.chatSend,
            ),
          ],
        ),
        if (keyboard) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              l.chatVoiceHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Warm.onCardSoft(theme.brightness),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The browser path: put the cursor in the field and let the keyboard's own
  /// microphone do the listening.
  void _useKeyboard() => widget.focus.requestFocus();

  /// The phone path: open the recogniser and put what it hears in the field.
  Future<void> _hold() async {
    final dictation = ref.read(dictationProvider);
    if (_listening) {
      await dictation.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!dictation.ready && !await dictation.prepare()) return;
    if (!mounted) return;
    setState(() => _listening = true);

    await dictation.start(
      localeId: dictationLocale(
        Localizations.localeOf(context).languageCode,
      ),
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          // Appended, never replacing: she may have typed half of it already.
          final existing = widget.controller.text.trim();
          widget.controller.text = existing.isEmpty
              ? text
              : '$existing $text';
          widget.controller.selection = TextSelection.collapsed(
            offset: widget.controller.text.length,
          );
          _listening = false;
        });
      },
      onSilence: () {
        if (mounted) setState(() => _listening = false);
      },
      onFailure: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
  }
}

/// The microphone, as the first thing on the row.
class _MicButton extends StatelessWidget {
  const _MicButton({required this.live, required this.onTap});

  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Tooltip(
      message: l.chatVoice,
      child: Pressable(
        onTap: onTap,
        borderRadius: _Ask.micSize / 2,
        child: Container(
          width: _Ask.micSize,
          height: _Ask.micSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: Warm.accentGradient,
            boxShadow: [
              BoxShadow(
                color: Warm.accent.withValues(alpha: live ? 0.55 : 0.30),
                blurRadius: live ? 18 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            live ? Icons.stop_rounded : Icons.mic,
            color: Colors.white,
            size: 24,
          ),
        ),
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
    return Card(
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
    return Card(
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
    return Card(
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

class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l.chatAiOff,
      icon: Icons.smart_toy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.chatAiOffBody,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            l.chatAiOffHow,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// What to ask, worked out from what is already written down.
///
/// Five chips of the same five sentences, wrapping onto four lines on a phone,
/// was both the chip-wall and the reason the assistant looked like a canned
/// list — see [suggestedQuestions]. These are three rows, each carrying the
/// entry it came from, so the app's reading of the day is on the screen before
/// a single word has been sent anywhere.
class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    final picks = suggestedQuestions(
      logs: ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
      now: DateTime.now(),
      ageMonths: child?.ageInMonths,
    );

    return SectionCard(
      title: l.chatSuggestionsTitle,
      icon: Icons.auto_awesome_outlined,
      action: Text(
        l.chatSuggestionsHint,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Warm.onCardSoft(theme.brightness),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pick in picks)
            _SuggestionRow(
              question: pick.question(l),
              reason: pick.reason(l),
              onTap: () => onPick(pick.question(l)),
            ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.question,
    required this.reason,
    required this.onTap,
  });

  final String question;

  /// Where the app got it from, or null when it came from nowhere in
  /// particular. Said out loud rather than implied: a suggestion that claims
  /// to know something has to show what it knows.
  final String? reason;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Warm.soft(theme.brightness),
        borderRadius: BorderRadius.circular(Warm.chipRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Warm.chipRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reason case final why?) ...[
                        const SizedBox(height: 3),
                        Text(
                          why,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Warm.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.north_east,
                  size: 16,
                  color: Warm.onCardSoft(theme.brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
