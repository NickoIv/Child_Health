import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/import/diary_import.dart';
import '../../core/import/pick_file.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Bringing a diary over from another app.
///
/// The whole design is one rule: say what will happen before it happens. A
/// file from another tracker is hundreds of rows a parent cannot check, so
/// the screen reads it, shows the counts, the span and the rows it could not
/// use, and only then offers a button. Nothing is written until that button.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String? _fileName;
  ImportPreview? _preview;
  bool _busy = false;
  int _written = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final preview = _preview;

    return Scaffold(
      appBar: AppBar(title: Text(l.importTitle)),
      body: PageBody(
        maxWidth: 720,
        children: [
          SectionCard(
            title: l.importPickTitle,
            icon: Icons.upload_file_outlined,
            accentColor: VizPalette.slot(1, theme.brightness),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.importHint, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  l.importFormats,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(child.id),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(l.importPickButton),
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _fileName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 16),
            _PreviewCard(preview: preview),
            const SizedBox(height: 16),
            SectionCard(
              title: l.importWriteTitle,
              icon: Icons.playlist_add_check_outlined,
              accentColor: VizPalette.slot(2, theme.brightness),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _written > 0
                        ? l.importDone(_written)
                        : l.importWriteHint(preview.entries.length),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _busy || preview.isEmpty || _written > 0
                        ? null
                        : () => _write(preview),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_done_outlined),
                    label: Text(l.importWriteButton(preview.entries.length)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(String childId) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    final file = await pickTextFile();
    if (!mounted) return;

    if (file == null) {
      setState(() => _busy = false);
      return;
    }

    final preview = previewImport(file.text, childId: childId);
    setState(() {
      _busy = false;
      _fileName = file.name;
      _preview = preview;
      _written = 0;
    });

    if (preview.isEmpty) {
      messenger.showSnackBar(
        appSnack(l.importNothingFound, kind: SnackKind.problem),
      );
    }
  }

  /// Written one at a time, and counted as they land.
  ///
  /// No batch: the repository writes one entry per call, a partial import is
  /// recoverable — the rows that arrived are simply in the diary — and a
  /// failure halfway reports how far it got rather than losing the lot.
  Future<void> _write(ImportPreview preview) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(logRepositoryProvider);

    setState(() => _busy = true);
    var written = 0;
    try {
      for (final entry in preview.entries) {
        await repository.add(entry);
        written++;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _written = written;
      });
      messenger.showSnackBar(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _written = written;
    });
    messenger.showSnackBar(
      appSnack(l.importDone(written), kind: SnackKind.done),
    );
  }
}

/// What the file turned out to hold.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final range = preview.range;

    return SectionCard(
      title: l.importFoundTitle,
      icon: Icons.fact_check_outlined,
      accentColor: VizPalette.slot(3, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (range != null)
            Text(
              l.reportRange(
                shortDate.format(range.from),
                shortDate.format(range.to),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 10),
          for (final type in LogType.values)
            if (preview.countOf(type) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${type.localizedLabel(l)}: ${preview.countOf(type)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: AppTheme.tabular,
                  ),
                ),
              ),
          if (preview.skipped.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l.importSkipped(preview.skipped.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: StatusColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // Named, not merely counted: a parent who knows which lines were
            // dropped can look at them.
            Text(
              preview.skipped.take(12).map((s) => s.line).join(', '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: AppTheme.tabular,
              ),
            ),
          ],
          if (preview.headers.any((h) => h.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Text(l.importColumns, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            // What each column was taken to be, so a wrong guess is visible
            // rather than merely wrong.
            for (var i = 0; i < preview.headers.length; i++)
              if (preview.headers[i].isNotEmpty)
                Text(
                  '${preview.headers[i]} → ${_roleName(l, preview.roles[i])}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _roleName(AppLocalizations l, ColumnRole role) => switch (role) {
    ColumnRole.date => l.importRoleDate,
    ColumnRole.time => l.importRoleTime,
    ColumnRole.kind => l.importRoleKind,
    ColumnRole.duration => l.importRoleDuration,
    ColumnRole.amount => l.importRoleAmount,
    ColumnRole.note => l.importRoleNote,
    ColumnRole.ignored => l.importRoleIgnored,
  };
}
