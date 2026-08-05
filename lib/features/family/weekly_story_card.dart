import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/weekly_story.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../reports/report_share.dart';
import '../reports/weekly_story_pdf.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';

/// The week, as a thing worth keeping.
///
/// For both parents, which is the one place this differs from the digest: the
/// mother lived every day of it, but a week is longer than anyone's memory of
/// it, and "she slept nine hours on Thursday" is not a fact either parent
/// still holds by Sunday.
///
/// A photograph, four numbers and a warm title. No average, no percentile, no
/// comparison with a norm or with last week — a keepsake that quietly grades
/// the family is not a keepsake. And nothing is stored for it: the week is
/// computed from the diary each time the card is drawn.
class WeeklyStoryCard extends ConsumerWidget {
  const WeeklyStoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(weeklyStoryProvider);
    // A week with nothing in it is not a week to celebrate, and a frame full
    // of zeroes would be the app asking why.
    if (story.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = SoftTone.lavender.ink(theme.brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gap),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SoftTone.lavender.fill(theme.brightness),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.coverPhotoId != null)
              _Cover(photoId: story.coverPhotoId!),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 20, color: ink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          storyTitle(l, story.title),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.reportRange(
                      dayMonth.format(story.from),
                      dayMonth.format(story.to),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 22,
                    runSpacing: 14,
                    children: [
                      _Fact(
                        value: '${story.feedings}',
                        label: l.storyFeedings,
                        ink: ink,
                      ),
                      _Fact(
                        value: localizedDuration(l, story.sleepMinutes),
                        label: l.storySleep,
                        ink: ink,
                      ),
                      _Fact(
                        value: '${story.nappies}',
                        label: l.storyNappies,
                        ink: ink,
                      ),
                      // Only when a night was actually recorded: a "best
                      // night" of nothing is a question, not a memory.
                      if (story.hasBestNight)
                        _Fact(
                          value: localizedDuration(l, story.bestNightMinutes),
                          label: l.storyBestNight,
                          ink: ink,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ExportButton(story: story),
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

/// The cover, edge to edge and tappable.
///
/// Wide and short on purpose: a photograph at its own aspect ratio can be a
/// portrait taller than the phone, and the card has to stay a card.
class _Cover extends ConsumerWidget {
  const _Cover({required this.photoId});

  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = ref.watch(photoProvider(photoId));

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: photo.maybeWhen(
        data: (p) => p == null
            ? const SizedBox.shrink()
            : InkWell(
                // The viewer the diary already opens, with nothing added.
                onTap: () => showPhotoViewer(context, photoIds: [photoId]),
                child: Image.memory(p.bytes, fit: BoxFit.cover),
              ),
        orElse: () => Container(
          color: Warm.soft(theme.brightness),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label, required this.ink});

  final String value;
  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: ink)),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Builds the page and hands it to the platform.
///
/// Available to a viewer as well: exporting reads the record and writes
/// nothing to it, and a father who cannot send his own week to his own mother
/// would be a strange kind of guest.
class _ExportButton extends ConsumerStatefulWidget {
  const _ExportButton({required this.story});

  final WeeklyStory story;

  @override
  ConsumerState<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<_ExportButton> {
  bool _building = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return TextButton.icon(
      onPressed: _building ? null : _export,
      icon: _building
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share, size: 18),
      label: Text(_building ? l.reportPreparing : l.storyExport),
    );
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    setState(() => _building = true);
    try {
      // The cover travels as bytes rather than as an id: the page is rendered
      // off the widget tree and has no provider to read.
      final coverId = widget.story.coverPhotoId;
      final cover = coverId == null
          ? null
          : (await ref.read(photoProvider(coverId).future))?.bytes;

      final bytes = await renderWeeklyStory(
        widget.story,
        child,
        l,
        cover: cover,
        localeName: locale,
      );

      if (!mounted) return;
      setState(() => _building = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.storyPdfReady),
          duration: const Duration(seconds: 2),
        ),
      );

      // Share sheet on a phone, downloads folder in a browser. Nothing is
      // uploaded on either.
      await shareReportPdf(
        bytes: bytes,
        filename: storyFilename(child.name),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _building = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(l, e))));
    }
  }
}
