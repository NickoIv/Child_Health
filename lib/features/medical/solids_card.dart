import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/solids.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Which foods have been given, and what followed.
///
/// The table a paediatrician asks for out loud — «что уже вводили и на что
/// была реакция» — and the one thing a parent cannot reconstruct from memory
/// six months in. It is assembled from the ordinary feed entries she was
/// already making, so there is no second list to keep up to date and no way
/// for the two to disagree.
///
/// It lives in the medical card rather than on the home screen because that is
/// where it is read: at a table, in front of somebody with a question.
class SolidsCard extends ConsumerWidget {
  const SolidsCard({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final foods = foodsIn(logs);
    final now = DateTime.now();

    return SectionCard(
      title: l.solidsTitle,
      icon: Icons.restaurant_outlined,
      accentColor: VizPalette.slot(2, theme.brightness),
      child: foods.isEmpty
          ? Text(
              '${l.solidsEmpty}. ${l.solidsEmptyHint}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < foods.length; i++) ...[
                  if (i > 0)
                    Divider(
                      color: Warm.hairline(theme.brightness),
                      height: 20,
                    ),
                  _FoodRow(
                    record: foods[i],
                    now: now,
                    onReaction: () =>
                        _addReaction(context, ref, foods[i].name, l),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _addReaction(
    BuildContext context,
    WidgetRef ref,
    String food,
    AppLocalizations l,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = await showAppSheet<String>(
      context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _ReactionSheet(food: food),
      ),
    );
    if (text == null || text.trim().isEmpty) return;

    await ref.read(logRepositoryProvider).add(
          DevelopmentLog(
            id: '',
            childId: childId,
            date: DateTime.now(),
            type: LogType.note,
            // A note, not an illness: an illness day colours the heat map and
            // belongs to a fever. This belongs to a food.
            title: LogTitles.reaction,
            description: text.trim(),
            food: food,
          ),
        );
    messenger.showAppSnack(
      appSnack(l.quickSaved(food.toLowerCase()), kind: SnackKind.done),
    );
  }
}

/// One food: its name, how often, and either the three days it is still being
/// watched for or what happened.
class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.record,
    required this.now,
    required this.onReaction,
  });

  final FoodRecord record;
  final DateTime now;
  final VoidCallback onReaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final watching = record.isUnderWatchAt(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                record.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (record.times > 0)
              Text(
                l.solidTimesCount(record.times),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: AppTheme.tabular,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l.solidFirstAt(shortDate.format(record.firstAt)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (watching) ...[
          const SizedBox(height: 6),
          _Badge(
            icon: Icons.visibility_outlined,
            label: l.solidWatch(shortDate.format(record.watchUntil)),
            color: StatusColors.warning,
          ),
        ],
        // Every reaction, with the date it was seen. Not summarised into a
        // verdict: «сыпь на щеках к вечеру» is what she saw, and a doctor
        // wants the sentence rather than a red dot.
        for (final r in record.reactions) ...[
          const SizedBox(height: 6),
          _Badge(
            icon: Icons.warning_amber_outlined,
            label: '${shortDate.format(r.date)} — ${r.description}',
            color: StatusColors.alert,
          ),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onReaction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l.solidReactionAdd),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// What she saw, in her own words.
class _ReactionSheet extends StatefulWidget {
  const _ReactionSheet({required this.food});

  final String food;

  @override
  State<_ReactionSheet> createState() => _ReactionSheetState();
}

class _ReactionSheetState extends State<_ReactionSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Warm.accentOn(theme.brightness),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.solidReactionTitle(widget.food),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l.solidReactionWhat,
                hintText: l.solidReactionHint,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _text.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_text.text),
              child: Text(l.quickSaveButton),
            ),
          ],
        ),
      ),
    );
  }
}
