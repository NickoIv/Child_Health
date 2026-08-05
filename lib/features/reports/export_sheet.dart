import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';
import 'period_report.dart';
import 'period_report_pdf.dart';
import 'report_share.dart';

/// Pick a period, get a PDF.
///
/// Three buttons and nothing else: the only decision worth asking about is
/// how far back to look, and a form with a date picker on it would turn a
/// thirty-second job into a task.
Future<void> showExportSheet(BuildContext context, {required String childId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ExportSheet(childId: childId),
  );
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({required this.childId});

  final String childId;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  ReportPeriod? _building;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.reportExport,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final period in ReportPeriod.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.tonal(
                  onPressed: _building != null ? null : () => _export(period),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _building == period
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.reportPeriodDays(period.days)),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ] else if (_building != null) ...[
              const SizedBox(height: 4),
              Text(
                l.reportPreparing,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build it, say it is ready, hand it over.
  ///
  /// The rendering is the only slow part, so «Готовим PDF…» sits under the
  /// buttons while it runs and the sheet closes the moment there is a file.
  /// Sharing is awaited afterwards rather than before the pop: on a phone the
  /// system sheet then opens over the medical screen instead of over a bottom
  /// sheet that is on its way out, and on the web the download has already
  /// started by the time the confirmation is read.
  Future<void> _export(ReportPeriod period) async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    setState(() {
      _building = period;
      _error = null;
    });

    final Uint8List bytes;
    try {
      final logs = ref.read(logsProvider).value ?? const <DevelopmentLog>[];
      final report = buildPeriodReport(child, logs, period);

      if (report.isEmpty) {
        setState(() {
          _building = null;
          _error = l.reportNothing;
        });
        return;
      }

      bytes = await renderPeriodReport(report, l, localeName: locale);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _building = null;
        _error = friendlyError(l, e);
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(l.reportReady),
        duration: const Duration(seconds: 2),
      ),
    );

    // Straight to the share sheet on a phone, straight to the downloads
    // folder in a browser. Nothing is uploaded on either.
    try {
      await shareReportPdf(
        bytes: bytes,
        filename: reportFilename(child.name, period.days),
      );
    } catch (_) {
      // The file exists and the sheet has gone; all that failed is the
      // handover, and there is nothing left to retry into.
      messenger.showSnackBar(SnackBar(content: Text(l.reportShareFailed)));
    }
  }
}
