import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/shared_moments.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';

/// Today's photographs, for the parent who was not in the room.
///
/// The digest above it answers whether the day went all right. This answers
/// the other question a father actually has, which is what she looked like
/// this afternoon — and answers it without him having to open the diary and
/// scroll a stream of feeds to find the two pictures in it.
///
/// What it deliberately does not have: a comment box, a heart, a reply, a
/// notification when a new one lands, or any way for the person looking to
/// add one. A viewer is here to see the child, not to be given a feed to
/// perform in. The moment there is a reaction button, the mother is
/// photographing for an audience.
///
/// Nothing today means nothing on screen — not an empty frame explaining that
/// no photographs were taken, which would read as a small daily reproach.
class MomentsCard extends ConsumerWidget {
  const MomentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();

    final moments = ref.watch(recentMomentsProvider);
    if (moments.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ids = <String>[for (final m in moments) m.photoId];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gap),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SoftTone.rose.fill(theme.brightness),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 20,
                  color: SoftTone.rose.ink(theme.brightness),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.momentsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: SoftTone.rose.ink(theme.brightness),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // A Wrap rather than a Row: three 96px tiles fit a narrow phone,
            // but not once the system text scale is turned up under them.
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final moment in moments)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The album is all three, so tapping one and swiping
                      // reaches the others — the viewer the diary already
                      // opens, with nothing added to it for this card.
                      PhotoThumb(photoId: moment.photoId, size: 96, album: ids),
                      const SizedBox(height: 6),
                      Text(
                        timeOfDay.format(moment.at),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              momentLine(l, lineFor(moments.length)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SoftTone.rose.ink(theme.brightness),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            const Align(alignment: Alignment.centerLeft, child: _ThankButton()),
          ],
        ),
      ),
    );
  }
}

/// The one thing a viewer may send, and the only control on this card.
///
/// A heart and a fixed sentence. No field to type into, no second sentence to
/// choose from, and nothing that arrives on her phone with a sound — the point
/// is that the day was noticed, and every richer version of that turns into an
/// inbox somebody then owes a reply to.
///
/// Once a day, decided by the date already on the membership document rather
/// than by a flag on this phone: he has two devices, and the answer has to be
/// the same on both.
class _ThankButton extends ConsumerStatefulWidget {
  const _ThankButton();

  @override
  ConsumerState<_ThankButton> createState() => _ThankButtonState();
}

class _ThankButtonState extends ConsumerState<_ThankButton> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    final email = ref.watch(currentEmailProvider);
    if (child == null || email.isEmpty) return const SizedBox.shrink();

    final members = ref.watch(familyMembersProvider).value ?? const [];
    final me = members.where((m) => m.email == email).firstOrNull;
    if (me == null) return const SizedBox.shrink();

    final sent = me.thankedOnDay(DateTime.now());

    return TextButton.icon(
      onPressed: sent || _sending ? null : () => _send(child.id, email),
      icon: Icon(
        sent ? Icons.favorite : Icons.favorite_border,
        size: 18,
        color: sent ? SoftTone.rose.ink(theme.brightness) : null,
      ),
      label: Text(sent ? l.appreciationThankSent : l.appreciationThankButton),
    );
  }

  Future<void> _send(String childId, String email) async {
    setState(() => _sending = true);
    try {
      await ref.read(familyRepositoryProvider).thank(
        childId: childId,
        email: email,
        day: DateTime.now(),
      );
    } catch (_) {
      // Nothing to recover and nothing worth interrupting him for: the
      // button simply comes back, and he can tap it again.
    }
    if (mounted) setState(() => _sending = false);
  }
}

/// The sentence for a number of photographs. Kept out of the widget so a test
/// can read it without building anything.
String momentLine(AppLocalizations l, MomentLine line) => switch (line) {
  MomentLine.one => l.momentsLineOne,
  MomentLine.two => l.momentsLineTwo,
  MomentLine.many => l.momentsLineMany,
};
