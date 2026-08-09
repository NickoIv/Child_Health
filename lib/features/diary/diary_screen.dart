import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/glass.dart';
import '../../core/theme/app_snack.dart';
import '../../core/l10n/labels.dart';
import '../../core/photos/compression.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/units/units.dart';
import '../../models/app_user.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../providers.dart';
import '../dashboard/focus_home.dart';
import '../dashboard/night_sleep_sheet.dart';
import '../family/invite_banner.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';

/// Chronological feed of diary entries with filtering by type, per 2.2.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

/// The eight kinds of entry, in the four bundles a parent actually filters by.
///
/// Nine chips over two rows was the top third of the diary before anything of
/// the diary had been read. And nobody asks for nappies-but-not-feeds: the
/// question a parent opens the filter with is which *part* of the day she wants
/// back — how he was looked after, how he was, what he learned, what somebody
/// wrote down — and four of those fit on one line.
///
/// Every [LogType] belongs to exactly one bundle, which a test holds: a type
/// nobody grouped would silently vanish from every filter but «Все».
enum DiaryFilter {
  care(Icons.water_drop_outlined, [
    LogType.feeding,
    LogType.nappy,
    LogType.sleep,
  ]),
  health(Icons.thermostat, [LogType.illness, LogType.measurement]),
  development(Icons.star_outline, [LogType.milestone]),
  notes(Icons.notes, [LogType.note, LogType.question]);

  const DiaryFilter(this.icon, this.types);

  final IconData icon;
  final List<LogType> types;

  bool matches(DevelopmentLog log) => types.contains(log.type);

  String localizedLabel(AppLocalizations l) => switch (this) {
    DiaryFilter.care => l.diaryFilterCare,
    DiaryFilter.health => l.diaryFilterHealth,
    DiaryFilter.development => l.diaryFilterDevelopment,
    DiaryFilter.notes => l.diaryFilterNotes,
  };
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  DiaryFilter? _filter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final logsAsync = ref.watch(logsProvider);
    if (logsAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: l.diaryFeed,
            icon: Icons.auto_stories_outlined,
            child: ErrorState(
              error: logsAsync.error!,
              onRetry: () => ref.invalidate(logsProvider),
            ),
          ),
        ],
      );
    }

    final readOnly = ref.watch(isReadOnlyProvider);
    final logs = logsAsync.value ?? const <DevelopmentLog>[];
    final visible = _filter == null
        ? logs
        : logs.where(_filter!.matches).toList();

    return Scaffold(
      body: PageBody(
        maxWidth: _Timeline.maxWidth,
        children: [
          _FilterBar(
            selected: _filter,
            onChanged: (t) => setState(() => _filter = t),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            SectionCard(
              title: l.diaryFeed,
              icon: Icons.auto_stories_outlined,
              child: EmptyState(
                icon: Icons.edit_note,
                message: l.diaryEmpty,
                hint: l.diaryEmptyHint,
              ),
            )
          else ...[
            // The card that used to wrap the whole feed is gone. Its heading
            // repeated the title already in the app bar, and its edges drew a
            // box round forty entries that are each a surface of their own —
            // so the only thing it added was two levels of nesting and the
            // width they cost.
            SectionLabel(
              text: l.diaryFeed,
              action: Text(
                l.entriesCount(visible.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Warm.onCardSoft(Theme.of(context).brightness),
                ),
              ),
            ),
            _Timeline(
              logs: visible,
              readOnly: readOnly,
              onOpen: readOnly
                  ? null
                  : (log) => showDiaryEntryForm(
                      context,
                      ref,
                      childId: child.id,
                      existing: log,
                    ),
              onDelete: readOnly
                  ? null
                  : (log) => _confirmDelete(context, log),
            ),
          ],
        ],
      ),
      // The one control on this screen that writes. A viewer keeps it, sees
      // the padlock, and is told once what it means rather than being left to
      // wonder where the button went.
      floatingActionButton: liftedFab(
        context,
        FloatingActionButton.extended(
          onPressed: readOnly
              ? () => ScaffoldMessenger.of(
                  context,
                ).showApp(l.familyReadOnlyHint)
              : () => _openForm(context),
          backgroundColor: readOnly
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          foregroundColor: readOnly
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
          icon: Icon(readOnly ? Icons.lock_outline : Icons.add),
          label: Text(readOnly ? l.familyReadOnly : l.diaryAddEntry),
        ),
      ),
    );
  }

  /// Deleting is the one action here with no undo, so it asks first. The
  /// pencil sitting right beside it makes the slip easy to make otherwise.
  Future<void> _confirmDelete(BuildContext context, DevelopmentLog log) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.diaryDeleteTitle),
        content: Text(l.diaryDeleteBody(localizedLogTitle(l, log))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(logRepositoryProvider).delete(log.id);
      messenger.showSnackBar(appSnack(l.entryDeleted, kind: SnackKind.done));
    }
  }

  Future<void> _openForm(BuildContext context) async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;
    await showDiaryEntryForm(context, ref, childId: child.id);
  }
}

/// One row, and it stays one row.
///
/// A [Wrap] here grew to whatever the longest translation needed — in Kazakh
/// the old nine chips took three lines. Scrolling sideways costs a swipe on the
/// rare occasion the last bundle is off-screen; wrapping cost the top of the
/// diary on every visit.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  static const _height = 40.0;

  final DiaryFilter? selected;
  final ValueChanged<DiaryFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: _height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoicePill(
              label: l.commonAll,
              icon: Icons.all_inclusive,
              selected: selected == null,
              onTap: () => onChanged(null),
            ),
          ),
          for (final f in DiaryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoicePill(
                label: f.localizedLabel(l),
                icon: f.icon,
                selected: selected == f,
                onTap: () => onChanged(selected == f ? null : f),
              ),
            ),
        ],
      ),
    );
  }
}

/// The day as one column.
///
/// A diary is read by scanning, not by reading: what a parent wants at nine in
/// the evening is the shape of the day — fed, changed, slept, fed again — and
/// a list of equal-weight cards makes her read every one to find it. The rail
/// down the left gives the eye something to follow, and the clock down the
/// right turns the column into a day.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.logs,
    required this.onOpen,
    required this.onDelete,
    this.readOnly = false,
  });

  /// Entries still open, and still not editable.
  final bool readOnly;

  /// Wide enough for a sentence, narrow enough to stay a timeline. Past this
  /// the rail and the clock drift so far apart that the connection between
  /// them stops being visible.
  static const maxWidth = 760.0;

  final List<DevelopmentLog> logs;
  final ValueChanged<DevelopmentLog>? onOpen;
  final ValueChanged<DevelopmentLog>? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < logs.length; i++) ...[
          // A heading only where the day turns over, so a single day reads as
          // one uninterrupted run.
          if (i == 0 || dateOnly(logs[i].date) != dateOnly(logs[i - 1].date))
            Padding(
              // More air above a new day than between two entries inside it:
              // the gap is what says the morning ended, and eighteen pixels
              // was not enough to say it.
              padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: SectionLabel(text: _dayLabel(logs[i].date, now)),
                  ),
                  // How many that day came to. The question a diary is opened
                  // with is nearly always "how many were there yesterday",
                  // and until now it had to be answered by counting rows.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${_countOn(logs, logs[i].date)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Warm.onCardSoft(theme.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Keyed by the entry's own id, so the arrival animation runs for a
          // feed that was just written down and not for the fifty above it
          // every time the stream ticks.
          Arrival(
            key: ValueKey(logs[i].id),
            child: _TimelineEntry(
              log: logs[i],
              now: now,
              // The line stops at the last entry of the run rather than
              // running out of the bottom of the card into nothing.
              connected:
                  i < logs.length - 1 &&
                  dateOnly(logs[i + 1].date) == dateOnly(logs[i].date),
              readOnly: readOnly,
              onOpen: onOpen == null ? null : () => onOpen!(logs[i]),
              onDelete: onDelete == null ? null : () => onDelete!(logs[i]),
            ),
          ),
        ],
      ],
    );
  }

  /// The current year needs no year on it; anything older does.
  static String _dayLabel(DateTime date, DateTime now) =>
      date.year == now.year ? dayMonth.format(date) : dayMonthYear.format(date);

  /// How many entries fall on the same calendar day as [date].
  static int _countOn(List<DevelopmentLog> logs, DateTime date) {
    final day = dateOnly(date);
    return logs.where((log) => dateOnly(log.date) == day).length;
  }
}

class _TimelineEntry extends ConsumerWidget {
  const _TimelineEntry({
    required this.log,
    required this.now,
    required this.connected,
    required this.onOpen,
    required this.onDelete,
    this.readOnly = false,
  });

  final DevelopmentLog log;
  final DateTime now;
  final bool connected;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = logColor(log, theme.brightness);
    final detail = _detail(l, ref.watch(unitSystemProvider));

    // The event is a surface of its own now rather than a row on the card
    // behind it. A day of feeds and nappies read as one grey block of text;
    // giving each one edges is what turns the column back into a list of
    // separate moments.
    return Pressable(
      // Tap, and only tap. A long press hides the one thing every entry needs
      // to do behind a gesture nobody discovers and nothing announces.
      onTap: onOpen,
      borderRadius: _radius,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Rail(icon: _iconFor(log), accent: accent, connected: connected),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: Warm.cardGap),
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                decoration: BoxDecoration(
                  color: Warm.card(theme.brightness),
                  borderRadius: BorderRadius.circular(_radius),
                  boxShadow: Warm.shadow(theme.brightness),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizedLogTitle(l, log),
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (detail.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              detail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (log.photos.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _PhotoPreview(photoIds: log.photos),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Grey, both lines. The clock orders the day; it is
                        // not one of the things being read.
                        Text(
                          timeOfDay.format(log.date),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          l.nowAgo(localizedDuration(l, _minutesAgo)),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    if (readOnly)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: ReadOnlyLock(),
                      )
                    else
                      IconButton(
                        tooltip: l.diaryDeleteTitle,
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Softer than the card it sits on, which is 22. Nested rounding reads as a
  /// mistake unless the inner radius is visibly the smaller of the two.
  static const _radius = Warm.cardRadius;

  /// Never below a minute: "0 мин назад" reads as a bug, and an entry made
  /// seconds ago is simply the newest one.
  int get _minutesAgo {
    final minutes = now.difference(log.date).inMinutes;
    return minutes < 1 ? 1 : minutes;
  }

  /// One line under the title: what the entry actually says.
  String _detail(AppLocalizations l, UnitSystem units) {
    final parts = <String>[
      routineSummary(l, log),
      if (log.metrics.temperatureC != null)
        Units.formatTemperature(log.metrics.temperatureC!),
      if (log.metrics.weightKg != null)
        Units.formatWeight(log.metrics.weightKg!, units),
      if (log.metrics.heightCm != null)
        Units.formatHeight(log.metrics.heightCm!, units),
      if (log.metrics.headCircumferenceCm != null)
        l.pillHead(Units.formatHeight(log.metrics.headCircumferenceCm!, units)),
      if (log.metrics.chestCircumferenceCm != null)
        l.pillChest(
          Units.formatHeight(log.metrics.chestCircumferenceCm!, units),
        ),
      log.description.trim(),
      for (final tag in log.tags) '#$tag',
    ]..removeWhere((part) => part.isEmpty);

    return parts.join(' · ');
  }

  static IconData _iconFor(DevelopmentLog log) {
    // A night is its own kind of sleep, and a dose is a note with a job.
    if (log.isNightSleep) return Icons.nightlight_outlined;
    if (log.type == LogType.note && log.title == LogTitles.medicine) {
      return Icons.medication_outlined;
    }
    return switch (log.type) {
      LogType.milestone => Icons.star_outline,
      LogType.measurement => Icons.straighten,
      LogType.illness => Icons.thermostat,
      LogType.feeding => Icons.water_drop_outlined,
      LogType.nappy => Icons.child_care_outlined,
      LogType.sleep => Icons.bedtime_outlined,
      LogType.question => Icons.help_outline,
      LogType.note => Icons.notes,
    };
  }

}

/// The coloured dot and the thread between dots.
///
/// The colour is the type of the event, and it is the fastest thing on the
/// screen to read: scanning a day for "when did she last sleep" is a search
/// for a lavender dot, not a search for the word.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.icon,
    required this.accent,
    required this.connected,
  });

  static const _diameter = 34.0;

  final IconData icon;
  final Color accent;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _diameter,
      child: Column(
        children: [
          const SizedBox(height: 6),
          Container(
            width: _diameter,
            height: _diameter,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              // A ring rather than a shadow: the dot has to stay a dot on
              // whichever of the two surfaces it lands on.
              border: Border.all(
                color: accent.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          if (connected)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One thumbnail, and a count for the rest.
///
/// The strip used to grow with the entry; on a timeline that pushed the next
/// event off the screen. The first photo is the one she recognises the entry
/// by, and the badge says how many more are behind it.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photoIds});

  static const _size = 64.0;

  final List<String> photoIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = photoIds.length - 1;

    // A Wrap, not a Row: the entry column is narrow now that each event has
    // its own padding, and two 64px thumbnails plus a delete button do not
    // always fit across a phone. Wrapping drops the badge under the
    // thumbnail; a Row clipped it.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PhotoThumb(photoId: photoIds.first, size: _size, album: photoIds),
        if (extra > 0) ...[
          InkWell(
            onTap: () =>
                showPhotoViewer(context, photoIds: photoIds, initialIndex: 1),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Warm.soft(theme.brightness),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '+$extra',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoIds,
    required this.uploading,
    required this.error,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photoIds;
  final bool uploading;
  final String? error;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Expanded, not a Spacer: at dialog width on a phone the heading
            // and the button together ran past the edge.
            Expanded(
              child: Text(
                l.diaryPhotos,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (uploading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(l.commonAdd),
              ),
          ],
        ),
        if (photoIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in photoIds)
                Stack(
                  children: [
                    PhotoThumb(photoId: id, size: 64),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IconButton(
                        iconSize: 18,
                        tooltip: l.commonDelete,
                        onPressed: () => onRemove(id),
                        icon: const Icon(Icons.cancel),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Opens the entry form and saves the result.
///
/// Public so other screens can reach it: the growth tab needs to add a
/// measurement without sending the parent to the diary first, and an entry
/// has to be editable from wherever it is shown.
Future<void> showDiaryEntryForm(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  LogType initialType = LogType.note,
  DevelopmentLog? existing,
}) async {
  // A night was entered as one block — bedtime, wakings, feeds — and has to be
  // corrected the same way. The general form would show it as a stretch of
  // sleep with a duration and silently drop the rest.
  if (existing != null && existing.isNightSleep) {
    await showNightSleepSheet(context, childId: childId, existing: existing);
    return;
  }

  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final draft = await showDialog<DevelopmentLog>(
    context: context,
    builder: (_) => _LogFormDialog(
      childId: childId,
      initialType: existing?.type ?? initialType,
      existing: existing,
    ),
  );
  if (draft == null) return;

  final repository = ref.read(logRepositoryProvider);
  // A draft carrying an id is an edit; without one it is a new entry.
  if (draft.id.isEmpty) {
    await repository.add(draft);
  } else {
    await repository.update(draft);
  }

  // Said out loud. The form is opened from four different screens and on
  // three of them the entry lands somewhere the parent cannot see it — a
  // measurement added from the growth tab joins a list further down, and a
  // dialog that simply closes leaves her wondering whether it saved.
  messenger.showSnackBar(appSnack(l.entrySaved, kind: SnackKind.done));
}

class _LogFormDialog extends ConsumerStatefulWidget {
  const _LogFormDialog({
    required this.childId,
    this.initialType = LogType.note,
    this.existing,
  });

  final String childId;
  final LogType initialType;
  final DevelopmentLog? existing;

  @override
  ConsumerState<_LogFormDialog> createState() => _LogFormDialogState();
}

class _LogFormDialogState extends ConsumerState<_LogFormDialog> {
  final _photoIds = <String>[];
  bool _uploading = false;
  String? _photoError;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _head = TextEditingController();
  final _chest = TextEditingController();
  final _temperature = TextEditingController();

  LogType _type = LogType.note;
  Severity _severity = Severity.mild;

  /// Now for a new entry, and whatever was recorded when editing one.
  DateTime _date = DateTime.now();

  /// Everything the dropdown offers, routine care included.
  static final _offeredTypes = LogType.values;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    final existing = widget.existing;
    if (existing == null) return;

    _title.text = existing.title;
    _description.text = existing.description;
    _tags.text = existing.tags.join(', ');
    _date = existing.date;
    _severity = existing.severity ?? Severity.mild;
    _photoIds.addAll(existing.photos);

    // Metrics are stored in metric units and shown in the parent's chosen
    // ones, so they are converted back on the way into the fields.
    final units = ref.read(unitSystemProvider);
    final metrics = existing.metrics;
    if (metrics.weightKg != null) {
      _weight.text = _display(Units.weightToDisplay(metrics.weightKg!, units));
    }
    if (metrics.heightCm != null) {
      _height.text = _display(Units.heightToDisplay(metrics.heightCm!, units));
    }
    if (metrics.headCircumferenceCm != null) {
      _head.text = _display(
        Units.heightToDisplay(metrics.headCircumferenceCm!, units),
      );
    }
    if (metrics.chestCircumferenceCm != null) {
      _chest.text = _display(
        Units.heightToDisplay(metrics.chestCircumferenceCm!, units),
      );
    }
    if (metrics.temperatureC != null) {
      _temperature.text = metrics.temperatureC!.toStringAsFixed(1);
    }
  }

  /// Trims the trailing zero a conversion leaves behind, so the field reads
  /// "9.6" rather than "9.600000000000001".
  static String _display(double value) {
    final rounded = (value * 100).roundToDouble() / 100;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    _weight.dispose();
    _height.dispose();
    _head.dispose();
    _chest.dispose();
    _temperature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final units = ref.watch(unitSystemProvider);
    return AlertDialog(
      title: Text(widget.existing == null ? l.diaryNewEntry : l.diaryEditEntry),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<LogType>(
                  initialValue: _type,
                  // Inside a dialog on a phone the field is ~200px wide, and
                  // «Веха развития» plus the arrow does not fit. Expanded and
                  // ellipsised, it shrinks instead of overflowing.
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.diaryType),
                  items: [
                    // Routine care is normally one tap on the dashboard, which
                    // stamps the current time. It is offered here too so a feed
                    // or a nappy nobody wrote down at three in the morning can
                    // still be added later, with the time it actually happened.
                    for (final t in _offeredTypes)
                      DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.localizedLabel(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (t) => setState(() => _type = t ?? LogType.note),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l.diaryTitleField),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.diaryTitleRequired
                      : null,
                ),
                const SizedBox(height: 12),
                DateTimeField(
                  value: _date,
                  onChanged: (v) => setState(() => _date = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.diaryDescription),
                ),
                if (_type == LogType.measurement) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          _weight,
                          l.fieldWeight(Units.weightUnit(units)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          _height,
                          l.fieldHeight(Units.heightUnit(units)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          _head,
                          l.fieldHead(Units.heightUnit(units)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          _chest,
                          l.fieldChest(Units.heightUnit(units)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_type == LogType.illness) ...[
                  const SizedBox(height: 12),
                  _numberField(_temperature, l.fieldTemperature),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Severity>(
                    initialValue: _severity,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.fieldSeverity),
                    items: [
                      for (final s in Severity.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.localizedLabel(l),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (s) =>
                        setState(() => _severity = s ?? Severity.mild),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tags,
                  decoration: InputDecoration(
                    labelText: l.diaryTags,
                    hintText: l.diaryTagsHint,
                  ),
                ),
                const SizedBox(height: 16),
                _PhotoPicker(
                  photoIds: _photoIds,
                  uploading: _uploading,
                  error: _photoError,
                  onAdd: _pickPhotos,
                  onRemove: _removePhoto,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.commonSave)),
      ],
    );
  }

  Widget _numberField(TextEditingController c, String label) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        return double.tryParse(v.replaceAll(',', '.')) == null
            ? l.commonNumberInvalid
            : null;
      },
    );
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  /// Reads a field and converts it to the metric value that gets stored.
  double? _toStorage(
    TextEditingController controller,
    double Function(double, UnitSystem) convert,
    UnitSystem units,
  ) {
    final entered = _parse(controller);
    return entered == null ? null : convert(entered, units);
  }

  /// Uploads immediately on pick rather than on save.
  ///
  /// Compression takes a moment on a large photo, and doing it while the
  /// parent is still typing hides that latency. The cost is an orphaned photo
  /// document if the form is then cancelled — cheap, and cleanable later.
  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _photoError = null;
    });

    final repository = ref.read(photoRepositoryProvider);
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final photo = await repository.upload(
          childId: widget.childId,
          bytes: bytes,
        );
        if (!mounted) return;
        setState(() => _photoIds.add(photo.id));
      } on PhotoTooLargeException catch (e) {
        if (mounted) {
          setState(
            () => _photoError = photoProblemText(
              AppLocalizations.of(context),
              e.problem,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(
            () => _photoError = AppLocalizations.of(
              context,
            ).photoUploadFailed('$e'),
          );
        }
      }
    }

    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _removePhoto(String id) async {
    await ref.read(photoRepositoryProvider).delete(id);
    if (mounted) setState(() => _photoIds.remove(id));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final units = ref.read(unitSystemProvider);
    final log = DevelopmentLog(
      // Keeping the id is what makes this an edit rather than a copy.
      id: widget.existing?.id ?? '',
      childId: widget.childId,
      date: _date,
      type: _type,
      title: _title.text.trim(),
      description: _description.text.trim(),
      // Converted to metric on the way in. What the parent typed depends on
      // their unit setting; what gets stored never does.
      metrics: switch (_type) {
        LogType.measurement => Metrics(
          weightKg: _toStorage(_weight, Units.weightToStorage, units),
          heightCm: _toStorage(_height, Units.heightToStorage, units),
          headCircumferenceCm: _toStorage(_head, Units.heightToStorage, units),
          chestCircumferenceCm: _toStorage(
            _chest,
            Units.heightToStorage,
            units,
          ),
        ),
        LogType.illness => Metrics(temperatureC: _parse(_temperature)),
        _ => const Metrics(),
      },
      // Keeping the id is what makes this an edit rather than a copy.
      photos: List.of(_photoIds),
      tags: _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      severity: _type == LogType.illness ? _severity : null,
    );
    Navigator.of(context).pop(log);
  }
}
