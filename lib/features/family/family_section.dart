import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_member.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Who else can see this child, and the one field that adds someone.
///
/// A whole screen for this would be a screen opened twice ever. It is a card
/// in settings: an address, a button, and a list of the two or three people
/// who matter. What it deliberately is not is a permissions editor — there is
/// one thing an invited person can be, and picking it from a menu of one
/// would only imply there are others.
class FamilySection extends ConsumerStatefulWidget {
  const FamilySection({super.key});

  @override
  ConsumerState<FamilySection> createState() => _FamilySectionState();
}

class _FamilySectionState extends ConsumerState<FamilySection> {
  final _email = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final child = ref.watch(selectedChildProvider);
    final readOnly = ref.watch(isReadOnlyProvider);
    final members =
        ref.watch(familyMembersProvider).value ?? const <FamilyMember>[];

    if (child == null) return const SizedBox.shrink();

    return SectionCard(
      title: l.familyTitle,
      icon: Icons.diversity_1_outlined,
      accentColor: SoftTone.sky.ink(theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.familySubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),

          // The owner is always on the list even though she is not a
          // document: seeing herself named beside the person she invited is
          // what makes the list read as a family rather than as a log.
          _MemberRow(
            label: l.familyRoleOwner,
            detail: ref.watch(currentEmailProvider),
            status: null,
            onRemove: null,
          ),
          for (final member in members.where((m) => m.role != FamilyRole.owner))
            _MemberRow(
              label: l.familyRoleViewer,
              detail: member.email,
              status: member.isAccepted ? l.familyAccepted : l.familyPending,
              accepted: member.isAccepted,
              onRemove: readOnly
                  ? null
                  : () => ref.read(familyRepositoryProvider).revoke(
                      childId: child.id,
                      email: member.email,
                    ),
            ),

          if (members.where((m) => m.role != FamilyRole.owner).isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.familyNobody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),

          // A viewer sees the family and cannot change it. Inviting others is
          // the owner's to give away, not the guest's to pass on.
          if (readOnly) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.familyOwnerOnly,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.familyInviteEmail,
                helperText: l.familyInviteHint,
                errorText: _error,
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              onSubmitted: (_) => _invite(child.id),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _sending ? null : () => _invite(child.id),
                icon: const Icon(Icons.person_add_alt),
                label: Text(l.familyInvite),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _invite(String childId) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = normalizeEmail(_email.text);

    if (!looksLikeEmail(email)) {
      setState(() => _error = l.familyEmailInvalid);
      return;
    }
    // Inviting yourself would create a viewer membership for the owner and
    // lock her out of her own record on the next launch.
    if (email == ref.read(currentEmailProvider)) {
      setState(() => _error = l.familySelfInvite);
      return;
    }
    final existing =
        ref.read(familyMembersProvider).value ?? const <FamilyMember>[];
    if (existing.any((m) => m.email == email)) {
      setState(() => _error = l.familyAlreadyMember);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref.read(familyRepositoryProvider).invite(
        childId: childId,
        ownerUid: ref.read(currentUidProvider),
        email: email,
      );
      if (!mounted) return;
      _email.clear();
      messenger.showSnackBar(SnackBar(content: Text(l.familyInviteSent)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(l, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.label,
    required this.detail,
    required this.status,
    this.accepted = false,
    this.onRemove,
  });

  final String label;
  final String detail;
  final String? status;
  final bool accepted;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final tone = accepted || status == null ? SoftTone.mint : SoftTone.sand;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.fill(theme.brightness),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == null ? Icons.star_outline : Icons.visibility_outlined,
              size: 17,
              color: tone.ink(theme.brightness),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                Text(
                  detail.isEmpty ? '—' : detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                status!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tone.ink(theme.brightness),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (onRemove != null)
            IconButton(
              tooltip: l.familyRemove,
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}
