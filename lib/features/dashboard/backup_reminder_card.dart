import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backup/run_backup.dart';
import '../../core/care/backup_store.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// «Сохраните копию» — once a month, and never twice about the same diary.
///
/// The only card on this screen that is not about the child, and it is here
/// because it is about the only thing on the screen that cannot be recovered.
/// The export has been a button in settings, which means it has been used by
/// people who already knew they wanted it; the ones it exists for are the
/// ones who will never open that screen.
///
/// It asks and then gets out of the way. Nothing about it counts anything at
/// the parent, and «позже» means a week, not tomorrow.
class BackupReminderCard extends ConsumerStatefulWidget {
  const BackupReminderCard({super.key, this.now});

  final DateTime? now;

  @override
  ConsumerState<BackupReminderCard> createState() =>
      _BackupReminderCardState();
}

class _BackupReminderCardState extends ConsumerState<BackupReminderCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tone = SoftTone.sky;
    final ink = tone.ink(theme.brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gap),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tone.fill(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 19, color: ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.backupRemindTitle,
                    style: theme.textTheme.titleSmall?.copyWith(color: ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.backupRemindBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined, size: 18),
                  label: Text(l.backupSave),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _busy ? null : _later,
                  // The same word the invitation banner uses. «Позже» means a
                  // week here rather than a session, and there is no reason
                  // for the app to own two spellings of it.
                  child: Text(l.familyLater),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    // The same path as the settings card, which also records that a copy now
    // exists — so this card is gone on the next build without being told.
    final name = await runBackup(ref, now: widget.now);
    if (!mounted) return;

    messenger.showAppSnack(
      name != null
          ? appSnack(l.backupSaved(name), kind: SnackKind.done)
          : appSnack(l.backupFailed, kind: SnackKind.problem),
    );
    setState(() => _busy = false);
  }

  void _later() =>
      ref.read(backupStoreProvider.notifier).snooze(now: widget.now);
}
