import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../knowledge/article.dart';
import '../../knowledge/knowledge_base.dart';
import '../../providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/pattern_card.dart';
import '../dashboard/reflection_card.dart';
import '../family/digest_card.dart';
import '../family/moments_card.dart';
import '../family/weekly_story_card.dart';
import '../reports/export_sheet.dart';
import '../shared/widgets.dart';
import 'context_block.dart';

/// Home of the knowledge base: search, red-flag check, and material picked
/// for the child's current age.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final ageMonths = child?.ageInMonths;
    final results = searchArticles(_query, ageMonths: ageMonths);

    return PageBody(
      children: [
        // Above the search field: the facts a question about a child usually
        // starts with, so she does not have to go and look them up first.
        const ChildContextBlock(),
        const SizedBox(height: Warm.majorGap),
        _SearchField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Warm.majorGap),
        if (_query.trim().isNotEmpty)
          _SearchResults(query: _query, results: results)
        else ...[
          // One gap between stacked cards, everywhere on this tab. The old
          // mix of 12, 16 and 24 read as three different screens scrolled
          // into one.
          const _RedFlagCard(),
          const SizedBox(height: Warm.majorGap),
          const _AskCard(),
          const SizedBox(height: Warm.majorGap),
          if (ageMonths != null) ...[
            _ForAgeCard(ageMonths: ageMonths, childName: child!.name),
            const SizedBox(height: Warm.majorGap),
          ],
          const _SectionsCard(),
          const SizedBox(height: 28),
          // Everything the home screen used to carry and no longer does.
          // It lives here because this is the tab a parent opens to read
          // rather than to log — see [DashboardScreen].
          const _InsightsSection(),
          const SizedBox(height: 16),
          const _Disclaimer(),
        ],
      ],
    );
  }
}

/// The reading half of the app, in one place.
///
/// Patterns, the evening reflection, the day for the parent who was out, the
/// week worth keeping, today's photographs, the eight configurable blocks and
/// the exports. Each of these draws nothing when it has nothing to say, so on
/// a quiet Tuesday this section is a heading and a button.
class _InsightsSection extends ConsumerWidget {
  const _InsightsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.assistantInsights, style: theme.textTheme.titleLarge),
        const SizedBox(height: Warm.majorGap),

        // For the parent who was not in the room, and nothing for the one who
        // was: both of these draw themselves only for a viewer.
        const DigestCard(),
        const MomentsCard(),

        const PatternCard(),
        const ReflectionCard(),
        const SizedBox(height: Warm.majorGap),

        const WeeklyStoryCard(),

        // The blocks a parent arranged in settings, still hers to arrange.
        const DashboardBlocks(),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showExportSheet(context, childId: child.id),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(l.reportExport),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l.assistantSearchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.query, required this.results});

  final String query;
  final List<KbArticle> results;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (results.isEmpty) {
      return SectionCard(
        title: l.assistantNothingFound,
        icon: Icons.search_off,
        child: EmptyState(
          icon: Icons.help_outline,
          message: l.assistantNoArticle(query),
          hint: l.assistantTryAnother,
        ),
      );
    }
    return SectionCard(
      title: l.assistantFound,
      icon: Icons.search,
      action: Text(
        l.assistantArticlesCount(results.length),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      child: Column(
        children: [
          for (final a in results) _ArticleTile(article: a),
        ],
      ),
    );
  }
}

/// The one thing that must never be more than a tap away.
class _RedFlagCard extends StatelessWidget {
  const _RedFlagCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: StatusColors.alert.withValues(alpha: 0.10),
      child: InkWell(
        onTap: () => context.go('/assistant/triage'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: StatusColors.alert,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.assistantTriage,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.assistantTriageHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry point to the conversational assistant.
class _AskCard extends ConsumerWidget {
  const _AskCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final configured = ref.watch(assistantServiceProvider).isConfigured;
    return Card(
      child: InkWell(
        onTap: () => context.go('/assistant/chat'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.forum_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.assistantChat,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      configured
                          ? l.assistantChatHint
                          : l.assistantChatOff,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForAgeCard extends StatelessWidget {
  const _ForAgeCard({required this.ageMonths, required this.childName});

  final int ageMonths;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final relevant = articlesForAge(ageMonths)
        .where((a) => a.section != KbSection.urgent)
        .take(5)
        .toList();
    if (relevant.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: l.assistantRelevant,
      icon: Icons.auto_awesome_outlined,
      action: Text(
        l.assistantChildAge(childName, ageMonths),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      child: Column(
        children: [for (final a in relevant) _ArticleTile(article: a)],
      ),
    );
  }
}

class _SectionsCard extends StatelessWidget {
  const _SectionsCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l.assistantAllTopics,
      icon: Icons.menu_book_outlined,
      child: Column(
        children: [
          for (final section in KbSection.values)
            if (articlesInSection(section).isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                leading: _SectionBadge(section: section),
                title: Text(
                  section.title,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  section.subtitle,
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  for (final a in articlesInSection(section))
                    _ArticleTile(article: a),
                ],
              ),
        ],
      ),
    );
  }

}

/// Coloured chip identifying a section.
///
/// The hues come from the validated categorical order, assigned in sequence —
/// the ordering is what keeps adjacent sections distinguishable to a
/// colour-blind reader, so it is not rearranged for taste. Urgent is the
/// exception: it takes the fixed alert colour, because it is a status and not
/// one identity among eight.
///
/// Three of the light-mode hues sit below 3:1 against the surface. Each badge
/// is always beside its section title, which is the relief the palette
/// requires: colour never carries the meaning alone.
class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.section});

  final KbSection section;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = section == KbSection.urgent
        ? StatusColors.alert
        : VizPalette.slot(section.index - 1, brightness);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(_iconFor(section), color: color, size: 21),
    );
  }

  static IconData _iconFor(KbSection s) => switch (s) {
    KbSection.urgent => Icons.emergency_outlined,
    KbSection.newborn => Icons.child_friendly_outlined,
    KbSection.feeding => Icons.restaurant_outlined,
    KbSection.sleep => Icons.bedtime_outlined,
    KbSection.illness => Icons.healing_outlined,
    KbSection.development => Icons.emoji_objects_outlined,
    KbSection.care => Icons.home_outlined,
    KbSection.mother => Icons.favorite_outline,
  };
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article});

  final KbArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(article.title),
      subtitle: Text(
        article.summary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: article.emergency.isEmpty
          ? const Icon(Icons.chevron_right, size: 20)
          : const Icon(
              Icons.priority_high,
              size: 20,
              color: StatusColors.alert,
            ),
      onTap: () => context.go('/assistant/article/${article.id}'),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warm.soft(theme.brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.assistantDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
