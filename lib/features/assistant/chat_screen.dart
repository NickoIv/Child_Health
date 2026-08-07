import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ai/actions.dart';
import '../../ai/assistant_service.dart';
import '../../ai/conversation.dart';
import '../../ai/suggested_questions.dart';
import '../../core/theme/app_theme.dart';
import '../../knowledge/article.dart';
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

/// Conversational front end over the knowledge base.
///
/// The model never sees a question the triage gate flagged, and never answers
/// from anything but the retrieved articles — see lib/ai/assistant_service.dart.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _turns = <_Turn>[];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    final service = ref.watch(assistantServiceProvider);

    return PageBody(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go('/assistant'),
              icon: const Icon(Icons.arrow_back),
              tooltip: l.commonBack,
            ),
            Expanded(
              child: Text(l.chatTitle, style: theme.textTheme.titleLarge),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(_input.text),
                decoration: InputDecoration(
                  hintText: child == null
                      ? l.chatEmpty
                      : l.chatHint(child.name),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _busy ? null : () => _send(_input.text),
              icon: const Icon(Icons.arrow_upward),
              tooltip: l.chatSend,
            ),
          ],
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
      AssistantAnswer(
        :final text,
        :final sources,
        :final action,
        :final isFromGeneralKnowledge,
      ) =>
        _AnswerCard(
          text: text,
          sources: sources,
          action: action,
          fromGeneralKnowledge: isFromGeneralKnowledge,
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
    this.action,
    this.fromGeneralKnowledge = false,
  });

  final String text;
  final List<KbArticle> sources;
  final AssistantAction? action;

  /// An everyday answer, drawn on the model's own knowledge. Said out loud
  /// rather than left to look like everything else the app has vetted.
  final bool fromGeneralKnowledge;

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
            if (fromGeneralKnowledge) ...[
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
                      l.chatGeneralAnswer,
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
