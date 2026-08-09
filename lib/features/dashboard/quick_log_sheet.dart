import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/daily_care.dart';
import '../../core/care/active_timer.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_snack.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';
import 'voice_note_button.dart';

/// The four things a parent records without thinking, all through one sheet.
///
/// Two steps, and the first one asks the only question that matters at three
/// in the morning: is this happening now, or am I writing up something that
/// already happened? Ninety-nine times out of a hundred it is now, so "Сейчас"
/// leads straight to the answer buttons and the entry is two taps old before
/// the keyboard has had a chance to appear.
///
/// The note lives on the second step of the other branch only. Someone filling
/// in last night's feed has time to write; someone tapping between a bottle and
/// a nappy does not, and a field she has to skip past is a field that costs her
/// something.
enum QuickLogAction {
  feeding,
  nappy,
  sleep,
  temperature;

  /// Filled rather than outlined.
  ///
  /// A hairline icon on a pastel card reads as a placeholder — it has the
  /// weight of the caption under it, when it is meant to be the thing a thumb
  /// aims at without reading anything.
  IconData get icon => switch (this) {
    QuickLogAction.feeding => Icons.water_drop,
    QuickLogAction.nappy => Icons.child_care,
    QuickLogAction.sleep => Icons.bedtime,
    QuickLogAction.temperature => Icons.thermostat,
  };

  /// Label on the dashboard button, phrased as the thing the parent just did
  /// rather than as the name of a record type.
  String buttonLabel(AppLocalizations l) => switch (this) {
    QuickLogAction.feeding => l.quickFeed,
    QuickLogAction.nappy => l.quickNappy,
    QuickLogAction.sleep => l.quickSleep,
    QuickLogAction.temperature => l.quickTemperature,
  };

  String sheetTitle(AppLocalizations l) => switch (this) {
    QuickLogAction.feeding => l.quickSheetFeeding,
    QuickLogAction.nappy => l.quickSheetNappy,
    QuickLogAction.sleep => l.quickSheetSleep,
    QuickLogAction.temperature => l.quickSheetTemperature,
  };
}

Future<void> showQuickLogSheet(
  BuildContext context, {
  required QuickLogAction action,
  required String childId,
  bool? startNow,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheetContext) => Padding(
      // Lifts the note field clear of the keyboard rather than letting it be
      // typed into blind. Measured from the sheet's own context: reading the
      // caller's as it is torn down throws while the sheet animates out.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _QuickLogSheet(
        action: action,
        childId: childId,
        startNow: startNow,
      ),
    ),
  );
}

class _QuickLogSheet extends ConsumerStatefulWidget {
  const _QuickLogSheet({
    required this.action,
    required this.childId,
    this.startNow,
  });

  final QuickLogAction action;
  final String childId;

  /// Set when the sheet was opened from a suggestion, which asked the "now or
  /// then" question on the card itself. Asking it twice would make the
  /// shortcut longer than the button it was meant to shorten.
  final bool? startNow;

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  /// Null until she has chosen between now and a time of her own — that choice
  /// is the whole of the first step.
  late bool? _now = widget.startNow;

  /// She chose to measure it rather than to write it down. Only the side is
  /// still missing, and only for a feed — so the second step is the same three
  /// buttons, and what they do is start a clock instead of filing an entry.
  bool _timing = false;

  DateTime _at = DateTime.now();
  final _note = TextEditingController();
  double _temperature = 37.0;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Read at save time so a sheet left open for a minute still records the
  /// moment she tapped, not the moment it opened.
  DateTime get _when => (_now ?? true) ? DateTime.now() : _at;

  bool get _picking => _now == false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(widget.action.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.action.sheetTitle(l),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_now == null) ..._whenStep(l) else ..._valueStep(l, theme),
          ],
        ),
      ),
    );
  }

  /// Step one: two buttons, nothing else on screen — three where the thing can
  /// be measured instead of remembered.
  List<Widget> _whenStep(AppLocalizations l) => [
    _BigButton(
      icon: Icons.bolt_outlined,
      label: l.quickTimeNow,
      filled: true,
      onPressed: () => setState(() => _now = true),
    ),
    const SizedBox(height: 12),
    // Only a feed and a sleep have a length worth measuring. A nappy and a
    // temperature are moments, and a stopwatch on either would be a joke at
    // the parent's expense.
    if (_canTime) ...[
      _BigButton(
        icon: Icons.timer_outlined,
        label: l.timerStart,
        onPressed: () {
          if (widget.action == QuickLogAction.sleep) {
            // Nothing left to ask: a sleep has no side.
            _startTimer(l, null);
          } else {
            setState(() {
              _now = true;
              _timing = true;
            });
          }
        },
      ),
      const SizedBox(height: 12),
    ],
    _BigButton(
      icon: Icons.schedule_outlined,
      label: l.quickTimeChoose,
      onPressed: () => setState(() {
        _now = false;
        // Opening on the current time means the usual correction is a few
        // minutes back, not a date to rebuild from scratch.
        _at = DateTime.now();
      }),
    ),
  ];

  bool get _canTime =>
      widget.action == QuickLogAction.feeding ||
      widget.action == QuickLogAction.sleep;

  /// Starts the clock and gets out of the way.
  ///
  /// No confirmation step and no second sheet: she is holding a child who has
  /// just latched on, and the entire value of this is that it took one tap
  /// while that was happening.
  Future<void> _startTimer(AppLocalizations l, FeedingSide? side) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    await ref.read(activeTimerProvider.notifier).start(
          kind: widget.action == QuickLogAction.feeding
              ? TimerKind.feeding
              : TimerKind.sleep,
          childId: widget.childId,
          side: side,
        );

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(appSnack(l.timerStarted, kind: SnackKind.done));
  }

  /// Step two: when it happened, if she chose that, then what happened.
  List<Widget> _valueStep(AppLocalizations l, ThemeData theme) => [
    if (_picking) ...[
      DateTimeField(
        value: _at,
        dateLabel: l.commonDate,
        timeLabel: l.commonTime,
        onChanged: (v) => setState(() => _at = v),
      ),
      const SizedBox(height: 12),
      // The note and the microphone that fills it in, side by side. The
      // microphone is beside the field rather than inside it because what it
      // does is dictate into the field, and a control that lives in the
      // decoration reads as something that clears or searches it.
      VoiceNoteButton(
        controller: _note,
        field: TextField(
          controller: _note,
          maxLines: 2,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.quickNoteOptional,
            prefixIcon: const Icon(Icons.edit_note_outlined),
          ),
        ),
      ),
      const SizedBox(height: 18),
    ],
    // Which breast was last, before she has to choose one.
    //
    // The question every nursing mother asks herself every two hours and the
    // one reason a paper notebook survives beside a phone. It is printed here
    // rather than on the home screen because here is where it is needed: at
    // the moment of choosing, with the answer directly above the three
    // buttons it applies to.
    if (widget.action == QuickLogAction.feeding) ...[
      _LastFeedLine(childId: widget.childId),
      const SizedBox(height: 14),
    ],
    if (widget.action == QuickLogAction.temperature)
      ..._temperatureStep(l, theme)
    else
      ..._options(l),
  ];

  List<Widget> _options(AppLocalizations l) {
    final entries = switch (widget.action) {
      QuickLogAction.feeding => [
        for (final s in FeedingSide.values)
          (
            icon: switch (s) {
              FeedingSide.left => Icons.chevron_left,
              FeedingSide.right => Icons.chevron_right,
              FeedingSide.bottle => Icons.local_drink_outlined,
            },
            label: s.localizedLabel(l),
            onTap: () => _timing ? _startTimer(l, s) : _saveFeeding(l, s),
          ),
      ],
      QuickLogAction.nappy => [
        for (final k in NappyKind.values)
          (
            icon: switch (k) {
              NappyKind.wet => Icons.water_drop_outlined,
              NappyKind.dirty => Icons.eco_outlined,
              NappyKind.both => Icons.done_all,
            },
            label: k.localizedLabel(l),
            onTap: () => _saveNappy(l, k),
          ),
      ],
      // Preset lengths rather than a duration picker: a newborn's sleep is
      // measured in "about an hour", and nobody is entering 47 minutes.
      _ => [
        for (final m in const [30, 60, 90, 120, 180])
          (
            icon: Icons.bedtime_outlined,
            label: _sleepLabel(l, m),
            onTap: () => _saveSleep(l, m),
          ),
      ],
    };

    return [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BigButton(
            icon: e.icon,
            label: e.label,
            onPressed: _saving ? null : e.onTap,
          ),
        ),
    ];
  }

  List<Widget> _temperatureStep(AppLocalizations l, ThemeData theme) {
    final fever = _temperature >= 38.0;
    final color = fever ? StatusColors.alert : StatusColors.normal;

    return [
      Text(
        '${_temperature.toStringAsFixed(1)} °C',
        textAlign: TextAlign.center,
        style: theme.textTheme.displaySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: () => _step(-0.1),
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 24),
          IconButton.filledTonal(
            onPressed: () => _step(0.1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      Slider(
        value: _temperature,
        min: 35.0,
        max: 42.0,
        divisions: 70,
        onChanged: (v) => setState(() => _temperature = v),
      ),
      if (fever)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l.quickFever,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      const SizedBox(height: 10),
      FilledButton(
        onPressed: _saving ? null : () => _saveTemperature(l),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(_BigButton.height),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l.quickSaveButton),
      ),
    ];
  }

  void _step(double delta) {
    setState(() {
      // Rounded to one decimal: floating point drift would otherwise show
      // 37.400000000000006 after a few taps.
      _temperature = ((_temperature + delta) * 10).roundToDouble() / 10;
      _temperature = _temperature.clamp(35.0, 42.0);
    });
  }

  Future<void> _saveFeeding(AppLocalizations l, FeedingSide side) {
    return _commit(
      DevelopmentLog(
        id: '',
        childId: widget.childId,
        date: _when,
        type: LogType.feeding,
        // Titles are what already sits in Firestore, so they stay the model's
        // own wording rather than the interface language of whoever tapped.
        title: LogType.feeding.label,
        description: _note.text.trim(),
        feedingSide: side,
      ),
      l.quickSaved(
        '${l.quickSheetFeeding.toLowerCase()}, '
        '${side.localizedLabel(l).toLowerCase()}',
      ),
    );
  }

  Future<void> _saveNappy(AppLocalizations l, NappyKind kind) {
    return _commit(
      DevelopmentLog(
        id: '',
        childId: widget.childId,
        date: _when,
        type: LogType.nappy,
        title: LogType.nappy.label,
        description: _note.text.trim(),
        nappyKind: kind,
      ),
      l.quickSaved(kind.localizedLabel(l).toLowerCase()),
    );
  }

  Future<void> _saveSleep(AppLocalizations l, int minutes) {
    return _commit(
      DevelopmentLog(
        id: '',
        childId: widget.childId,
        date: _when,
        type: LogType.sleep,
        title: LogType.sleep.label,
        description: _note.text.trim(),
        durationMinutes: minutes,
      ),
      l.quickSaved(
        '${l.quickSheetSleepShort.toLowerCase()} '
        '${localizedDuration(l, minutes)}',
      ),
    );
  }

  Future<void> _saveTemperature(AppLocalizations l) {
    return _commit(
      DevelopmentLog(
        id: '',
        childId: widget.childId,
        date: _when,
        // A fever is an illness day; anything else is just a measurement.
        // This is what makes the heat map fill in without extra taps.
        type: _temperature >= 38.0 ? LogType.illness : LogType.measurement,
        title: '${LogTitles.temperature} '
            '${_temperature.toStringAsFixed(1)} °C',
        description: _note.text.trim(),
        metrics: Metrics(temperatureC: _temperature),
        severity: _temperature >= 39.0
            ? Severity.severe
            : _temperature >= 38.0
            ? Severity.moderate
            : null,
      ),
      l.quickSaved('${_temperature.toStringAsFixed(1)} °C'),
      // Recording a fever and then being left alone with it is the moment
      // this app exists for.
      articleId: _temperature >= 38.0 ? 'fever' : null,
    );
  }

  /// Write it, close the sheet, say so.
  ///
  /// The messenger and the router are resolved before the pop, so the
  /// confirmation survives the sheet it was triggered from.
  Future<void> _commit(
    DevelopmentLog log,
    String confirmation, {
    String? articleId,
  }) async {
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await ref.read(logRepositoryProvider).add(log);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    messenger.showSnackBar(
      // The tick draws itself in beside the sentence rather than in front of
      // it: the sheet is already gone and her hands are already back on the
      // child, so this has to be readable at a glance and gone.
      appSnack(
        confirmation,
        kind: SnackKind.done,
        duration: const Duration(seconds: 3),
        action: articleId == null
            ? null
            : SnackBarAction(
                label: l.quickFeverAction,
                onPressed: () => router.go('/assistant/article/$articleId'),
              ),
      ),
    );
  }

  static String _sleepLabel(AppLocalizations l, int minutes) =>
      switch (minutes) {
        30 => l.quickSleep30,
        60 => l.quickSleep60,
        90 => l.quickSleep90,
        120 => l.quickSleep120,
        _ => l.quickSleep180,
      };
}

/// «Прошлое кормление — правая, 2 ч назад», or nothing at all.
///
/// Nothing at all on the first day, deliberately: a line that says there is no
/// previous feed is a line about the absence of data, and the sheet it would
/// sit in is one a mother opened to record her child's first one.
class _LastFeedLine extends ConsumerWidget {
  const _LastFeedLine({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final last = lastFeedingIn(logs);
    final side = last?.feedingSide;
    if (last == null || side == null) return const SizedBox.shrink();

    final minutes = DateTime.now().difference(last.date).inMinutes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Warm.soft(theme.brightness),
        borderRadius: BorderRadius.circular(Warm.chipRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 16,
            color: Warm.onCardSoft(theme.brightness),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.timerLastFeed(
                side.localizedLabel(l),
                minutes < 1
                    ? l.quickTimeNow.toLowerCase()
                    : l.nowAgo(localizedDuration(l, minutes)),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Warm.onCard(theme.brightness),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every button in the sheet is this one: same height, same radius, same
/// full-bleed width, whether it picks a time or records a feed.
class _BigButton extends StatefulWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  static const height = 56.0;
  static const radius = 18.0;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(_BigButton.height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_BigButton.radius),
      ),
    ).copyWith(
      // The scale is driven from the button's own pressed state rather than
      // from a wrapper, so a disabled button — one already saving — does not
      // dip under a second tap.
      elevation: const WidgetStatePropertyAll(0),
    );

    final icon = Icon(widget.icon);
    final label = Text(widget.label);

    return AnimatedScale(
      scale: _down ? Pressable.pressedScale : 1.0,
      duration: Pressable.duration,
      curve: Curves.easeOut,
      child: Listener(
        onPointerDown: (_) {
          if (widget.onPressed != null) _set(true);
        },
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: widget.filled
            ? FilledButton.icon(
                onPressed: widget.onPressed,
                icon: icon,
                label: label,
                style: style,
              )
            : FilledButton.tonalIcon(
                onPressed: widget.onPressed,
                icon: icon,
                label: label,
                style: style,
              ),
      ),
    );
  }
}
