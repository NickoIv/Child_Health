import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../knowledge/knowledge_base.dart';
import '../shared/widgets.dart';

/// Reading view for one article.
///
/// Order is fixed and non-negotiable: emergency signs first, then what to do
/// now, then when to call a doctor. Background reading comes last, because at
/// 3am nobody scrolls past the explanation to find the instruction.
class ArticleScreen extends StatelessWidget {
  const ArticleScreen({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context) {
    final article = articleById(articleId);
    if (article == null) {
      return PageBody(
        children: [
          SectionCard(
            title: 'Статья не найдена',
            icon: Icons.help_outline,
            child: Column(
              children: [
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  message: 'Такой статьи в базе нет',
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => context.go('/assistant'),
                  child: const Text('К списку тем'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
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
              child: Text(
                article.section.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(article.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          article.summary,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        if (article.emergency.isNotEmpty) ...[
          _Block(
            title: 'Скорая помощь — 103',
            icon: Icons.emergency_outlined,
            color: StatusColors.alert,
            items: article.emergency,
            emphasised: true,
          ),
          const SizedBox(height: 16),
        ],

        _Block(
          title: 'Что делать сейчас',
          icon: Icons.play_circle_outline,
          color: theme.colorScheme.primary,
          items: article.doNow,
        ),
        const SizedBox(height: 16),

        _Block(
          title: 'Когда обратиться к врачу',
          icon: Icons.local_hospital_outlined,
          color: StatusColors.warning,
          items: article.callDoctor,
        ),

        if (article.details.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Подробнее',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final d in article.details) ...[
                  Text(d, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        SectionCard(
          title: 'Источники',
          icon: Icons.library_books_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in article.sources) ...[
                Text(s.title, style: theme.textTheme.bodySmall),
                if (s.url.isNotEmpty)
                  SelectableText(
                    s.url,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StatusColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 20,
                color: StatusColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Это справочная информация, а не диагноз и не назначение. '
                  'Если что-то беспокоит — обратитесь к педиатру. '
                  'При тревожных признаках звоните 103.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.emphasised = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: emphasised ? color.withValues(alpha: 0.10) : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                // Expanded so a long heading wraps instead of running off a
                // phone screen — "Когда обратиться к врачу" overflowed by
                // 19px at 390 logical pixels.
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: emphasised ? color : null,
                      fontWeight: emphasised ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item, style: theme.textTheme.bodyMedium),
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
