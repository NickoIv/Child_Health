import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/daily_digest.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// Today, for the parent who was not in the room.
///
/// Five numbers and a sentence. It exists because the alternative is a father
/// scrolling a timeline of forty entries to work out whether the day went all
/// right, and then asking — which turns a shared record back into a thing the
/// mother has to narrate.
///
/// Only a viewer sees it. The mother lived the day; a card telling her how it
/// went would be the app explaining her own afternoon back to her.
class DigestCard extends ConsumerWidget {
  const DigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final digest = ref.watch(dailyDigestProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gap),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SoftTone.sand.fill(theme.brightness),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_twilight_outlined,
                  size: 20,
                  color: SoftTone.sand.ink(theme.brightness),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.digestTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: SoftTone.sand.ink(theme.brightness),
                    ),
                  ),
                ),
                Text(
                  l.digestSubtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (digest.isEmpty)
              Text(
                l.digestEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              // A Wrap rather than a Row: the temperature is usually absent
              // and the durations are the widest thing on the card in Kazakh.
              Wrap(
                spacing: 22,
                runSpacing: 14,
                children: [
                  _Fact(
                    value: '${digest.feedings}',
                    countTo: digest.feedings,
                    label: l.digestFeedings,
                  ),
                  if (digest.sleepMinutes > 0)
                    _Fact(
                      value: localizedDuration(l, digest.sleepMinutes),
                      label: l.digestSleep,
                    ),
                  _Fact(
                    value: '${digest.nappies}',
                    countTo: digest.nappies,
                    label: l.digestNappies,
                  ),
                  // Shown only when somebody took a reading. An empty slot
                  // reading "—" invites the question the card cannot answer.
                  if (digest.lastTemperature != null)
                    _Fact(
                      value: Units.formatTemperature(digest.lastTemperature!),
                      label: l.digestTemperature,
                      color: digest.lastTemperature! >= 38.0
                          ? StatusColors.alert
                          : null,
                    ),
                  if (digest.photos > 0)
                    _Fact(
                      value: '${digest.photos}',
                      countTo: digest.photos,
                      label: l.digestPhotos,
                      icon: Icons.photo_camera_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                warmLine(l, digest.mood),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SoftTone.sand.ink(theme.brightness),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The sentence for a mood. Kept out of the widget so a test can read it
/// without building anything.
String warmLine(AppLocalizations l, DayMood mood) => switch (mood) {
  DayMood.calm => l.digestCalm,
  DayMood.busy => l.digestBusy,
  DayMood.hardNight => l.digestHardNight,
};

class _Fact extends StatelessWidget {
  const _Fact({
    required this.value,
    required this.label,
    this.countTo,
    this.color,
    this.icon,
  });

  final String value;
  final String label;

  /// A plain count — feeds, nappies, photographs — which runs up to itself
  /// when the card arrives.
  ///
  /// Null for readings. A temperature or a duration that counts up is a
  /// number moving while someone reads it, and a reading you watch settle is
  /// a reading you check twice.
  final int? countTo;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
            ],
            if (countTo case final target?)
              CountUp(
                key: ValueKey('$label:$target'),
                value: target,
                builder: (context, shown) => Text(
                  '$shown',
                  style: theme.textTheme.titleLarge?.copyWith(color: color),
                ),
              )
            else
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(color: color),
              ),
          ],
        ),
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
