import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Questions to raise at the next appointment.
///
/// They come to mind at 2am and vanish the moment a doctor asks «есть
/// вопросы?». Written down here, they also print into the report, so the list
/// is in hand rather than in memory.
///
/// A card of its own because it is read in two places: on the preparation
/// screen, where the list is the point, and nowhere else — the medical card
/// links to it rather than repeating it.
class DoctorQuestionsCard extends ConsumerWidget {
  const DoctorQuestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final questions = ref.watch(doctorQuestionsProvider);

    return SectionCard(
      title: l.medicalAskDoctor,
      icon: Icons.help_outline,
      accentColor: VizPalette.slot(1, theme.brightness),
      action: TextButton.icon(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: Text(l.medicalWriteDown),
      ),
      child: questions.isEmpty
          ? Text(
              l.medicalQuestionsHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (final q in questions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.circle_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(q.title),
                    subtitle: Text(shortDate.format(q.date)),
                    trailing: IconButton(
                      tooltip: l.medicalAsked,
                      icon: const Icon(Icons.check, size: 20),
                      onPressed: () => _markAsked(context, ref, q),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Ticked off once it has been asked — and put back if the tick was a slip.
  ///
  /// The row is deleted, not flagged, so without a way back a mis-tap loses a
  /// question she thought of at three in the morning and will not think of
  /// again. The undo writes the same words to the same date, which is as
  /// close to "never happened" as a new document gets.
  Future<void> _markAsked(
    BuildContext context,
    WidgetRef ref,
    DevelopmentLog question,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(logRepositoryProvider);

    await repository.delete(question.id);

    messenger.showAppSnack(
      appSnack(
        l.medicalQuestionAsked,
        kind: SnackKind.done,
        action: SnackBarAction(
          label: l.commonUndo,
          onPressed: () => repository.add(
            DevelopmentLog(
              id: '',
              childId: question.childId,
              date: question.date,
              type: LogType.question,
              title: question.title,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _QuestionDialog(),
    );
    if (text == null || text.isEmpty) return;

    await ref.read(logRepositoryProvider).add(
          DevelopmentLog(
            id: '',
            childId: child.id,
            date: DateTime.now(),
            type: LogType.question,
            title: text,
          ),
        );

    // Said out loud, because the list it lands in may be below the fold and
    // a question typed into a dialog that closes on silence looks lost.
    messenger.showAppSnack(
      appSnack(l.medicalQuestionSaved, kind: SnackKind.done),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog();

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.medicalAskDoctor),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(hintText: l.medicalQuestionHint),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}