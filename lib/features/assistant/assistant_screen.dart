import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../knowledge/article.dart';
import '../../knowledge/knowledge_base.dart';
import '../../knowledge/milestones.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/pattern_card.dart';
import '../dashboard/reflection_card.dart';
import '../family/digest_card.dart';
import '../family/moments_card.dart';
import '../family/weekly_story_card.dart';
import '../reports/export_sheet.dart';
import '../shared/widgets.dart';

/// Home of the knowledge base: search, red-flag check, and material picked
/// for the child's current age.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

/// The two halves this tab turned out to be.
///
/// It had grown into one scroll carrying a search field, an emergency card, a
/// way into the chat, five articles for the age, eight collapsible sections of
/// the knowledge base, and then — under a heading nobody scrolled to — the
/// digest, the patterns, the evening card, the week, and five configurable
/// blocks. «Слишком загружено информацией».
///
/// They are not one thing badly arranged; they are two things. One is read
/// when there is a question, the other when there is a minute. Naming that
/// split and putting it behind one control is the whole compaction: each half
/// is now a page a tired person can reach the bottom of.
enum AssistantView {
  knowledge,
  insights;

  String label(AppLocalizations l) => switch (this) {
    AssistantView.knowledge => l.assistantViewKnowledge,
    AssistantView.insights => l.assistantViewInsights,
  };

  IconData get icon => switch (this) {
    AssistantView.knowledge => Icons.menu_book_outlined,
    AssistantView.insights => Icons.insights_outlined,
  };
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  String _query = '';
  AssistantView _view = AssistantView.knowledge;

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
    final searching = _query.trim().isNotEmpty;

    return PageBody(
      children: [
        // The five facts a question starts with used to be printed here as
        // well as on the chat screen one tap away — the same block, the same
        // numbers, twice. It belongs where a question is actually asked.
        _SearchField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Warm.majorGap),

        if (searching)
          _SearchResults(query: _query, results: results)
        else ...[
          // Searching answers the question the switch is for, so the switch
          // gets out of the way rather than sitting above the results.
          _ViewSwitch(
            selected: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
          const SizedBox(height: Warm.majorGap),

          if (_view == AssistantView.knowledge) ...[
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
              _UsuallyNowCard(ageMonths: ageMonths),
              const SizedBox(height: Warm.majorGap),
            ],
            const _SectionsCard(),
            const SizedBox(height: 16),
            const _Disclaimer(),
          ] else
            const _InsightsSection(),
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
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No heading of its own any more: the switch above says which half
        // this is, and printing the same word twice was part of what made the
        // tab feel like a pile.

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

/// The one control that decides which half of the tab is on screen.
///
/// Two [ChoicePill]s rather than a [SegmentedButton]: the same selected look
/// as the diary's filter row, and the same guarantee about its colours.
class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.selected, required this.onChanged});

  final AssistantView selected;
  final ValueChanged<AssistantView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        for (final view in AssistantView.values) ...[
          if (view != AssistantView.values.first) const SizedBox(width: 8),
          Expanded(
            child: ChoicePill(
              label: view.label(l),
              icon: view.icon,
              selected: selected == view,
              onTap: () => onChanged(view),
            ),
          ),
        ],
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
        child: Column(
          children: [
            EmptyState(
              icon: Icons.help_outline,
              message: l.assistantNoArticle(query),
              hint: l.assistantSearchIsArticles,
            ),
            const SizedBox(height: Warm.innerGap),
            // The way out of the dead end, and the whole point of this branch:
            // «какая погода сегодня?» has no article and never will, and the
            // thing that can answer it is one tap away.
            _AskAiButton(query: query, prominent: true),
          ],
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
          const Divider(height: 20),
          // Even with articles found: the base answers what it was written
          // about, and a parent's actual question is usually narrower.
          _AskAiButton(query: query, prominent: false),
        ],
      ),
    );
  }
}

/// Hands the words already typed to the assistant.
///
/// Carries the query rather than opening an empty chat: retyping a question
/// the app is already holding is exactly the tax this is here to remove.
class _AskAiButton extends StatelessWidget {
  const _AskAiButton({required this.query, required this.prominent});

  final String query;
  final bool prominent;

  void _open(BuildContext context) => context.go(
    '/assistant/chat?q=${Uri.encodeQueryComponent(query.trim())}',
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = Text(l.assistantAskAi);
    const icon = Icon(Icons.auto_awesome, size: 18);

    return SizedBox(
      width: double.infinity,
      child: prominent
          ? FilledButton.icon(
              onPressed: () => _open(context),
              icon: icon,
              label: label,
            )
          : TextButton.icon(
              onPressed: () => _open(context),
              icon: icon,
              label: label,
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

/// What usually appears around now — and never what has not appeared.
///
/// The rules this widget exists to keep are stated in full in
/// `knowledge/milestones.dart`. The two that show on screen: nothing here is
/// tappable, so the list can never become a score she is keeping; and the line
/// about the width of normal is printed at the top in ordinary type, not
/// tucked underneath in grey, because it is the most important sentence on the
/// card.
class _UsuallyNowCard extends ConsumerWidget {
  const _UsuallyNowCard({required this.ageMonths});

  final int ageMonths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final usual = milestonesUsualAt(ageMonths);
    final soon = milestonesSoonAfter(ageMonths).take(3).toList();
    if (usual.isEmpty && soon.isEmpty) return const SizedBox.shrink();

    final noted = milestonesNotedIn(
      ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
    );

    return SectionCard(
      title: l.milestonesUsualTitle,
      icon: Icons.child_care_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.milestonesSpread,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Warm.onCardSoft(theme.brightness),
            ),
          ),
          const SizedBox(height: 14),
          for (final m in usual)
            _MilestoneRow(milestone: m, noted: noted.contains(m.id)),
          if (soon.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l.milestonesSoon,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Warm.onCardSoft(theme.brightness),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in soon)
              _MilestoneRow(milestone: m, noted: noted.contains(m.id)),
          ],
          const SizedBox(height: 4),
          // The one thing to do with a worry, and it is not a checkbox: it
          // goes to the doctor, in her own words, on the page that already
          // collects questions for the appointment.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/medical'),
              child: Text(l.milestonesAsk),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.noted});

  final Milestone milestone;

  /// She has already written it in the diary. A quiet mark, never a tick in a
  /// box — the box is what would turn the empty ones into a reproach.
  final bool noted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            noted ? Icons.check_circle : Icons.circle_outlined,
            size: 15,
            color: noted
                ? Warm.accentOn(theme.brightness)
                : Warm.onCardSoft(theme.brightness).withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Warm.onCard(theme.brightness),
                    fontWeight: noted ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  noted
                      ? '${milestone.area.title} · ${l.milestonesNoted}'
                      : '${milestone.area.title} · '
                            '${l.milestonesRange(milestone.fromMonths, milestone.toMonths)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Warm.onCardSoft(theme.brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
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
