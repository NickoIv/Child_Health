import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ai/assistant_service.dart';
import '../../core/theme/app_theme.dart';
import '../../knowledge/article.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

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
              tooltip: 'Назад',
            ),
            Expanded(
              child: Text('Спросить помощника', style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
                      ? 'Спросите что-нибудь о здоровье ребёнка'
                      : 'Спросите про ${child.name}: сон, еда, температура…',
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _busy ? null : () => _send(_input.text),
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'Отправить',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Помощник отвечает только по проверенной базе приложения и не ставит '
          'диагнозов. Решение всегда за врачом.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _send(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || _busy) return;

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
          childContext: child == null
              ? null
              : childContextLine(
                  name: child.name,
                  ageMonths: child.ageInMonths,
                  gender: child.gender.label,
                ),
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
                    'Вызывайте скорую — 103',
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
              'В вашем вопросе есть признак, при котором нельзя ждать. '
              'Я намеренно не передаю такие вопросы ИИ — здесь нужен не совет, '
              'а немедленная помощь.',
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
              label: const Text('Что делать до приезда скорой'),
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
                'Ответ построен по статьям:',
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
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    child: const Text('Открыть базу знаний'),
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
    final theme = Theme.of(context);
    return SectionCard(
      title: 'ИИ-помощник пока не подключён',
      icon: Icons.smart_toy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'База знаний и проверка тревожных признаков работают без него — '
            'они не требуют интернета вообще.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Чтобы включить ИИ, нужно развернуть бесплатный прокси на '
            'Cloudflare Workers и пересобрать приложение с его адресом. '
            'Инструкция — в файле worker/README.md.',
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

  static const _examples = [
    'Температура 38.5, что делать',
    'Сколько должен спать ребёнок в 6 месяцев',
    'Когда начинать прикорм',
    'Можно ли мне антибиотик при ГВ',
    'Ребёнок не какал два дня',
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'О чём спрашивают чаще всего',
      icon: Icons.forum_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in _examples)
            ActionChip(label: Text(e), onPressed: () => onPick(e)),
        ],
      ),
    );
  }
}
