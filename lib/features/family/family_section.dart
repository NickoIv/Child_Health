import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/family/invite_mail.dart';
import '../../core/family/phone.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../core/web/open_url.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_member.dart';
import '../../models/invite_code.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Who else can see this child, and the one button that adds someone.
///
/// There were two fields here — an address and a phone number — and both were
/// asking her to know something she often does not: «может проще убрать почту
/// и оставить ватсап, чтобы у пользователей не было трудностей».
///
/// The address could not simply be deleted. Access is granted to the account
/// somebody signs in with, and an account is an email; a phone number has
/// nobody to grant anything to. So the address is still what the grant is made
/// to — it is just read off his own token when he opens the link, instead of
/// being typed by her from memory. Nobody types anything now.
///
/// What this deliberately is not is a permissions editor. There is one thing
/// an invited person can be, and offering it from a menu of one would only
/// imply there are others.
class FamilySection extends ConsumerStatefulWidget {
  const FamilySection({super.key});

  @override
  ConsumerState<FamilySection> createState() => _FamilySectionState();
}

class _FamilySectionState extends ConsumerState<FamilySection> {
  bool _making = false;
  String? _error;

  /// The last link made on this screen. Stays until the next one replaces it
  /// — a strip that slides away after three seconds is indistinguishable from
  /// nothing having happened, which is what «просто тишина и никакой обратной
  /// связи» was.
  InviteCode? _link;
  String _linkChildName = '';

  /// So the answer can be brought to her rather than waited for. The panel
  /// appears *below* the button that was just pressed, which on a phone is
  /// under the fold — on the screen, one scroll away, which is the same as
  /// not on it.
  final _panelKey = GlobalKey();

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
              // Only while it is still waiting, and only for the owner: once
              // he has accepted there is nothing left to send. These are for
              // the invitations made by address, before links existed — a new
              // one is handed over from the panel below.
              onCopy: member.isAccepted || readOnly
                  ? null
                  : () => _copyInvite(child.name, member.email),
              onWhatsApp: member.isAccepted || readOnly
                  ? null
                  : () => _openWhatsApp(
                      l.familyInviteMessage(child.name, member.email, appLink()),
                    ),
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
            Text(
              l.familyInviteLinkExplain,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _making ? null : () => _make(child.id, child.name),
                // A press that is doing something has to look like it. A
                // button that only greys out is, for the seconds a slow write
                // takes, the same picture as a button that ignored the tap.
                icon: _making
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt),
                label: Text(
                  _making ? l.familyInviteSending : l.familyInviteLink,
                ),
              ),
            ),
            if (_error case final message?) ...[
              const SizedBox(height: 10),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (_link case final link?) ...[
              const SizedBox(height: 14),
              _LinkPanel(
                key: _panelKey,
                url: joinLink(link.code),
                onCopy: () => _copyLink(link),
                onWhatsApp: () => _openWhatsApp(
                  l.familyInviteLinkMessage(_linkChildName, joinLink(link.code)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// The address the link points at, on whichever host this copy is served
  /// from. Hash-routed, because that is the strategy this build uses — a path
  /// URL would 404 on a hard refresh against Firebase Hosting.
  String joinLink(String code) => '${appLink()}/#$joinPath/$code';

  Future<void> _make(String childId, String childName) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _making = true;
      _error = null;
      _link = null;
    });

    try {
      final code = await ref
          .read(familyRepositoryProvider)
          .createCode(
            childId: childId,
            ownerUid: ref.read(currentUidProvider),
            now: DateTime.now(),
          )
          // Bounded, because a Firestore write on the web completes when the
          // *server* acknowledges it — with no signal it never completes, and
          // everything after it, including every word this screen was going
          // to say, never runs.
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _making = false;
        _link = code;
        _linkChildName = childName;
      });
      _showPanel();
    } catch (_) {
      if (!mounted) return;
      // A link that was not written cannot be handed over, so unlike the old
      // invitation there is nothing to fall back to. Said plainly, with the
      // button still there to press again.
      setState(() {
        _making = false;
        _error = l.familyLinkFailed;
      });
    }
  }

  /// Brings the answer to her. See [_panelKey].
  void _showPanel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _panelKey.currentContext;
      // Nothing to scroll when the card is pumped on its own in a test, and
      // nothing to do when it is already in view. Neither is a problem.
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  Future<void> _copyLink(InviteCode link) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(
        text: l.familyInviteLinkMessage(_linkChildName, joinLink(link.code)),
      ),
    );
    if (!mounted) return;
    messenger.showAppSnack(
      appSnack(l.familyLinkCopied, kind: SnackKind.done),
    );
  }

  /// The old invitation, for the addresses invited before links existed.
  ///
  /// The clipboard rather than a share sheet: this runs in a browser, the
  /// share sheet is not there on a desktop, and every messenger she might use
  /// accepts a paste.
  Future<void> _copyInvite(String childName, String email) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(
        text: l.familyInviteMessage(childName, email, appLink()),
      ),
    );
    if (!mounted) return;
    messenger.showAppSnack(
      appSnack(l.familyInviteCopied, kind: SnackKind.done),
    );
  }

  /// Opens WhatsApp with [message] already written out.
  ///
  /// The delivery that does not depend on anything staying configured — see
  /// [whatsAppLink]. The Worker's own send goes through a GREEN-API account
  /// that lapsed months ago and answered every request politely while
  /// delivering nothing. She presses send in her own WhatsApp and can see for
  /// herself that it arrived.
  Future<void> _openWhatsApp(String message) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // No recipient: WhatsApp opens on the chat list with the message ready
    // and she picks him. One tap, against a phone number she would otherwise
    // have had to find and type.
    final opened = await openUrl(whatsAppLink(phone: '', message: message));
    if (!mounted || opened) return;
    messenger.showAppSnack(
      appSnack(l.familyWhatsAppNotOpened, kind: SnackKind.info),
    );
  }
}

/// The link, and the two ways to hand it over.
///
/// The link itself is printed as well as offered, because a link that only
/// exists inside a button is a link she cannot check, cannot read out and
/// cannot see has been made at all.
class _LinkPanel extends StatelessWidget {
  const _LinkPanel({
    required this.url,
    required this.onCopy,
    required this.onWhatsApp,
    super.key,
  });

  final String url;
  final VoidCallback onCopy;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = SoftTone.mint.ink(theme.brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SoftTone.mint.fill(theme.brightness),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.link, size: 18, color: ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.familyLinkReady,
                  style: theme.textTheme.titleSmall?.copyWith(color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            url,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Wrapped rather than in a Row: the two labels side by side overflow
          // a 360-pixel phone in Russian, and in Kazakh in every language.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(l.familyOpenWhatsApp),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: Text(l.familyCopyLink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.label,
    required this.detail,
    required this.status,
    this.accepted = false,
    this.onCopy,
    this.onWhatsApp,
    this.onRemove,
  });

  final String label;
  final String detail;
  final String? status;
  final bool accepted;

  /// Offered while an invitation is still waiting: nothing was emailed, so
  /// these are how it actually reaches the other person.
  final VoidCallback? onCopy;
  final VoidCallback? onWhatsApp;
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
          if (onWhatsApp != null)
            IconButton(
              tooltip: l.familyOpenWhatsApp,
              onPressed: onWhatsApp,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
            ),
          if (onCopy != null)
            IconButton(
              tooltip: l.familyCopyInvite,
              onPressed: onCopy,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_outlined, size: 18),
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
