import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ai/assistant_service.dart';
import '../../ai/conversation.dart';
import '../../core/theme/app_theme.dart';
import '../../knowledge/article.dart';
import '../../providers.dart';
import '../../core/care/conversation_memory.dart';
import '../shared/widgets.dart';
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
      AssistantAnswer(:final text, :final sources) => _AnswerCard(
        text: text,
        sources: sources,
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
  const _AnswerCard({required this.text, required this.sources});

  final String text;
  final List<KbArticle> sources;

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

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick});

  final ValueChanged<String> onPick;

  static List<String> _examples(AppLocalizations l) => [
    l.chatSuggestion1,
    l.chatSuggestion2,
    l.chatSuggestion3,
    l.chatSuggestion4,
    l.chatSuggestion5,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.chatSuggestionsTitle,
      icon: Icons.forum_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in _examples(l))
            ActionChip(label: Text(e), onPressed: () => onPick(e)),
        ],
      ),
    );
  }
}
