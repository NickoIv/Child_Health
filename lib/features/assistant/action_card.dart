import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ai/actions.dart';
import '../../core/care/active_timer.dart';
import '../../core/l10n/labels.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_snack.dart';
import '../../knowledge/knowledge_base.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../reports/export_sheet.dart';
import '../shared/widgets.dart';

/// The one tap between a proposal and a record.
///
/// Everything the app is about to do is spelled out in the parent's own
/// language before it happens — the entry as the diary will show it, the
/// reminder with its date, the screen by the name on the tab. She reads a
/// sentence and decides; nothing is written on the way to this card.
///
/// A viewer sees the proposal and cannot act on it. That is not a
/// double-check: the repositories he holds are the read-only wrappers, and
/// hiding the button only spares him a refusal he did not need to earn.
class AssistantActionCard extends ConsumerStatefulWidget {
  const AssistantActionCard({super.key, required this.actions});

  /// One card for all of them, and one tap.
  ///
  /// «Покормила левой пятнадцать минут и поменяла подгузник» is two entries,
  /// and asking her to confirm them one at a time would make speaking a
  /// sentence slower than tapping two buttons — which is the whole of what
  /// this feature is for.
  final List<AssistantAction> actions;

  @override
  ConsumerState<AssistantActionCard> createState() =>
      _AssistantActionCardState();
}

class _AssistantActionCardState extends ConsumerState<AssistantActionCard> {
  /// Answered — confirmed or declined — so the card steps aside. It is a
  /// proposal about a moment, and a stale one further up a long thread is
  /// something to tap by accident.
  bool _settled = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (_settled) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    final readOnly = ref.watch(isReadOnlyProvider);
    if (child == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _icon(widget.actions.first),
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  l.actionSuggested,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Every one of them spelled out, on its own line. A card that said
            // «записать 2 записи» would be asking her to confirm a number.
            for (final action in widget.actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _describe(l, action),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (readOnly)
              Text(
                l.actionReadOnly,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Row(
                children: [
                  FilledButton(
                    onPressed: _busy ? null : _confirm,
                    child: Text(l.actionConfirm),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _settled = true),
                    child: Text(l.actionDismiss),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    setState(() => _busy = true);

    try {
      // Written first, navigated last. An [OpenScreenAction] leaves this
      // screen and takes the rest of the list with it, so anything that
      // records something has to have happened by then — «покормила, и открой
      // дневник» must not lose the feed on the way to the diary.
      final written = <String>[];
      AssistantAction? navigation;

      for (final action in widget.actions) {
        final draft = assistantDraft(
          action,
          childId: child.id,
          at: DateTime.now(),
        );

        if (draft != null) {
          await ref.read(logRepositoryProvider).add(draft);
          if (!mounted) return;
          written.add(localizedLogTitle(l, draft));
        } else if (action is CreateReminderAction) {
          await ref
              .read(reminderRepositoryProvider)
              .add(assistantReminder(action, childId: child.id));
          if (!mounted) return;
          written.add(action.title);
        } else if (action is TimerAction) {
          final timers = ref.read(activeTimerProvider.notifier);
          if (action.start) {
            await timers.start(
              kind: action.kind ?? TimerKind.feeding,
              childId: child.id,
              side: action.side,
            );
            if (!mounted) return;
            messenger.showApp(l.timerStarted, kind: SnackKind.done);
          } else {
            // Stopping is what produces the entry, exactly as the card on the
            // home screen does — so the clock and the assistant cannot write
            // two different feeds for one evening.
            final stopped = await timers.stop();
            if (!mounted) return;
            if (stopped == null) {
              messenger.showApp(l.timerNothingRunning, kind: SnackKind.info);
            } else {
              final draft = timerDraft(stopped, at: DateTime.now());
              await ref.read(logRepositoryProvider).add(draft);
              if (!mounted) return;
              written.add(localizedLogTitle(l, draft));
            }
          }
        } else {
          navigation = action;
        }
      }

      // One strip for everything that was recorded, not one per entry: three
      // in a row would queue and the last would be the only one she reads.
      if (written.isNotEmpty) {
        messenger.showApp(
          l.quickSaved(written.join(', ')),
          kind: SnackKind.done,
        );
      }

      if (navigation is OpenScreenAction) {
        if (!mounted) return;
        context.go(navigation.path);
      } else if (navigation is OpenArticleAction) {
        if (!mounted) return;
        context.go('/assistant/article/${navigation.articleId}');
      } else if (navigation is BuildReportAction) {
        if (!mounted) return;
        await showExportSheet(context, childId: child.id);
      }
    } on Exception {
      // The repository refuses a viewer's write, and the network can be gone.
      // Either way the parent gets a sentence rather than a stuck spinner.
      if (!mounted) return;
      messenger.showApp(l.actionFailed, kind: SnackKind.problem);
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _settled = true;
    });
  }

  /// What will happen, in the language the app is being read in.
  ///
  /// Entries are described by building the draft and asking the diary's own
  /// wording for it, so the sentence on this card and the line that appears
  /// in the timeline afterwards cannot drift apart.
  String _describe(AppLocalizations l, AssistantAction action) {
    final draft = assistantDraft(action, childId: '', at: DateTime.now());
    if (draft != null) {
      final summary = routineSummary(l, draft);
      final title = localizedLogTitle(l, draft);
      return l.actionWrite(summary.isEmpty ? title : '$title · $summary');
    }

    return switch (action) {
      CreateReminderAction(:final title, :final at) => l.actionCreateReminder(
        title,
        '${shortDate.format(at)} ${timeOfDay.format(at)}',
      ),
      OpenScreenAction(:final path) => l.actionOpenScreen(_screenName(l, path)),
      OpenArticleAction(:final articleId) => l.actionOpenArticle(
        articleById(articleId)?.title ?? articleId,
      ),
      TimerAction(:final start) => start
          ? l.actionStartTimer
          : l.actionStopTimer,
      BuildReportAction() => l.actionBuildReport,
      // Every log-writing action produced a draft above.
      _ => l.actionBuildReport,
    };
  }

  /// The name on the tab, so the card and the navigation agree. The two
  /// destinations that are not tabs are named by what they do.
  String _screenName(AppLocalizations l, String path) {
    for (final destination in appDestinations) {
      if (destination.path == path) return destination.label(l);
    }
    return path == '/assistant/triage' ? l.triageTitle : path;
  }

  IconData _icon(AssistantAction action) => switch (action) {
    // Every action that writes an entry shares one glyph: what the card has
    // to say is «this will be written down», and eight different pictograms
    // for eight kinds of entry would be eight things to learn.
    LogFeedingAction() ||
    LogSleepAction() ||
    LogNappyAction() ||
    LogTemperatureAction() ||
    LogGrowthAction() ||
    LogSolidAction() ||
    LogPumpingAction() ||
    LogNightSleepAction() ||
    AskDoctorAction() => Icons.edit_note_outlined,
    TimerAction() => Icons.timer_outlined,
    CreateReminderAction() => Icons.notifications_outlined,
    OpenScreenAction() || OpenArticleAction() => Icons.open_in_new,
    BuildReportAction() => Icons.picture_as_pdf_outlined,
  };
}
