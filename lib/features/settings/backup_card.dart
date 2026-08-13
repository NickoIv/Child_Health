import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backup/run_backup.dart';
import '../../core/storage/persist.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../shared/widgets.dart';

/// A copy she owns, and the truth about where the rest of it lives.
///
/// The app could import somebody else's diary and could not hand back its
/// own. For a record of a child's health that is the wrong way round: data
/// has to be leaveable, or the app is somewhere you are stuck rather than
/// somewhere you chose.
class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  bool _busy = false;

  /// Whether the browser has promised not to evict the local copy. Null while
  /// it is being asked — the row simply is not drawn yet.
  bool? _persistent;

  @override
  void initState() {
    super.initState();
    hasPersistentStorage().then((granted) {
      if (mounted) setState(() => _persistent = granted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final soft = Warm.onCardSoft(theme.brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gap),
      child: SectionCard(
        title: l.backupTitle,
        icon: Icons.inventory_2_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.backupExplain,
              style: theme.textTheme.bodySmall?.copyWith(color: soft),
            ),
            const SizedBox(height: 8),
            Text(
              l.backupNoPhotos,
              style: theme.textTheme.bodySmall?.copyWith(color: soft),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(l.backupSave),
              ),
            ),
            // Said plainly rather than hidden. A parent who is told the
            // browser may reclaim the local copy can decide to keep the file
            // above; one who is not told finds out by losing it.
            if (_persistent case final granted?) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    granted ? Icons.lock_outline : Icons.info_outline,
                    size: 15,
                    color: soft,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      granted
                          ? l.backupStorageSafe
                          : l.backupStorageEvictable,
                      style: theme.textTheme.bodySmall?.copyWith(color: soft),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    // The one implementation, shared with the reminder on the home screen —
    // see [runBackup]. It also records that a copy exists, which is what
    // stops that reminder asking again.
    final name = await runBackup(ref);
    if (!mounted) return;

    messenger.showAppSnack(
      name != null
          ? appSnack(l.backupSaved(name), kind: SnackKind.done)
          : appSnack(l.backupFailed, kind: SnackKind.problem),
    );
    setState(() => _busy = false);
  }
}
