import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_member.dart';
import '../../providers.dart';

/// "You were invited to join this child profile."
///
/// Shown at the top of the dashboard, once, to the person whose address was
/// invited. Two buttons and no third: accepting is the point, and *Later* is
/// there so the banner can be dismissed by someone who is standing in a shop
/// rather than being a decision he has to get right now.
///
/// *Later* dismisses for the session rather than declining outright. There is
/// no "decline" in phase one on purpose — a father who taps the wrong button
/// on a notification he did not expect should not have to ask his wife to
/// invite him again.
class InviteBanner extends ConsumerStatefulWidget {
  const InviteBanner({super.key});

  @override
  ConsumerState<InviteBanner> createState() => _InviteBannerState();
}

class _InviteBannerState extends ConsumerState<InviteBanner> {
  final _dismissed = <String>{};
  bool _accepting = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pending = ref
        .watch(pendingInvitationsProvider)
        .where((i) => !_dismissed.contains(_keyOf(i)))
        .toList();

    if (pending.isEmpty) return const SizedBox.shrink();
    final invitation = pending.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gap),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SoftTone.sky.fill(theme.brightness),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.diversity_1_outlined,
                  size: 20,
                  color: SoftTone.sky.ink(theme.brightness),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.familyInviteBanner,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: SoftTone.sky.ink(theme.brightness),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _accepting ? null : () => _accept(invitation),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(l.familyAccept),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _accepting
                      ? null
                      : () => setState(
                          () => _dismissed.add(_keyOf(invitation)),
                        ),
                  child: Text(l.familyLater),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _keyOf(FamilyMember invitation) =>
      '${invitation.childId}/${invitation.email}';

  Future<void> _accept(FamilyMember invitation) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _accepting = true);

    try {
      await ref
          .read(familyRepositoryProvider)
          .accept(invitation, ref.read(currentUidProvider));
      if (!mounted) return;
      messenger.showAppSnack(
        appSnack(l.familyAcceptedToast, kind: SnackKind.done),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }
}

/// "Mom" / "Dad", in the header.
///
/// Small and permanent. On a shared record the first question anyone has is
/// which of the two accounts they are looking at it from, and answering it in
/// the chrome costs a chip — while answering it by discovering that a button
/// does nothing costs a lot more.
class RoleChip extends ConsumerWidget {
  const RoleChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final readOnly = ref.watch(isReadOnlyProvider);

    // Nothing to disambiguate until somebody else is on the record.
    final shared =
        readOnly ||
        (ref.watch(familyMembersProvider).value ?? const <FamilyMember>[]).any(
          (m) => m.role != FamilyRole.owner,
        );
    if (!shared) return const SizedBox.shrink();

    final tone = readOnly ? SoftTone.sky : SoftTone.rose;
    final ink = tone.ink(theme.brightness);

    return Tooltip(
      message: readOnly ? l.familyReadOnlyHint : l.familyTitle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tone.fill(theme.brightness),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              readOnly ? Icons.visibility_outlined : Icons.star_outline,
              size: 14,
              color: ink,
            ),
            const SizedBox(width: 6),
            Text(
              readOnly ? l.familyRoleViewer : l.familyRoleOwner,
              style: theme.textTheme.labelSmall?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The lock that replaces a control a viewer cannot use.
///
/// A padlock rather than a hidden button: a father who cannot find the "add"
/// button assumes the app is broken, whereas one who sees it locked knows
/// exactly what he is looking at and whose permission it needs.
class ReadOnlyLock extends StatelessWidget {
  const ReadOnlyLock({this.size = 16, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: AppLocalizations.of(context).familyReadOnlyHint,
      child: Icon(
        Icons.lock_outline,
        size: size,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
