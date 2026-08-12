import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/family/invite_mail.dart';
import '../../core/family/phone.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../core/web/open_url.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_member.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// An invitation that exists, and the ways it can still reach the person.
///
/// Kept in the widget's state rather than announced in a snackbar. «Просто
/// тишина и никакой обратной связи»: a strip that slides away after three
/// seconds is indistinguishable from nothing having happened, and this is the
/// one screen in the app where what happened has to survive being looked away
/// from — she reads it, picks up the other phone, and comes back.
class _Handoff {
  const _Handoff({
    required this.childName,
    required this.email,
    required this.phone,
    required this.result,
  });

  final String childName;
  final String email;

  /// Digits only, or empty. Kept because the fields are cleared once the
  /// invitation exists and the WhatsApp link still needs a recipient.
  final String phone;

  final InviteMailResult result;

  /// Whether anything actually left the building. False is the ordinary case
  /// for this build — there is no mail key — and it is why the handoff row
  /// below is not a fallback but the main path.
  bool get delivered =>
      result == InviteMailResult.sent || result == InviteMailResult.sentWhatsApp;
}

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
  final _phone = TextEditingController();

  /// So a missing address can put the cursor where it is missing from.
  ///
  /// «В ватсап просто пишет проверьте адрес»: he filled in the WhatsApp
  /// number, left the email alone, and was answered about a field he had
  /// deliberately not touched. A red line under a box he was not looking at
  /// is not an explanation.
  final _emailFocus = FocusNode();
  String? _error;
  String? _phoneError;
  bool _sending = false;

  /// The last invitation created on this screen, and what became of it.
  /// Stays until the next one replaces it.
  _Handoff? _handoff;

  /// So the answer can be brought to her rather than waited for.
  ///
  /// The family card sits a long way down the settings page, and the panel
  /// appears *below* the button that was just pressed — on a phone that is
  /// under the fold. «У меня не высвечивается отправлено или нет» was partly
  /// this: it was on the screen, one scroll away, which is the same as not.
  final _panelKey = GlobalKey();

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _emailFocus.dispose();
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
              // Only while it is still waiting, and only for the owner: once
              // he has accepted there is nothing left to send, and the strip
              // that offered this at the moment of inviting is long gone by
              // the time she thinks to do it.
              onCopy: member.isAccepted || readOnly
                  ? null
                  : () => _copyInvite(child.name, member.email),
              // And the same handoff a week later, when the panel below is
              // long gone and he still has not been sent anything. No number
              // is stored, so this opens WhatsApp on the chat list with the
              // message written out and she picks him.
              onWhatsApp: member.isAccepted || readOnly
                  ? null
                  : () => _openWhatsApp(
                      _Handoff(
                        childName: child.name,
                        email: member.email,
                        phone: '',
                        result: InviteMailResult.notConfigured,
                      ),
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
            TextField(
              controller: _email,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.familyInviteEmail,
                // An example inside the box, so the field says what belongs
                // in it before anyone has pressed anything. On the screen he
                // sent, this box was empty, its label was a category and the
                // only writing on it appeared after the mistake.
                hintText: l.familyInviteEmailHint,
                helperText: '${l.familyInviteHint}. ${l.familyInviteExplain}',
                helperMaxLines: 4,
                errorText: _error,
                // Material swaps the helper out for the error, so whatever
                // the error says is now the only explanation on the field —
                // and it has to be allowed to be a sentence rather than a
                // truncated one.
                errorMaxLines: 4,
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              onSubmitted: (_) => _invite(child.id, child.name),
            ),
            const SizedBox(height: 12),
            // Optional, and the one that actually works here: a link sent to
            // WhatsApp arrives on the phone he is already holding, while an
            // email lands in a tab he opens on Tuesdays.
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.familyInvitePhone,
                helperText: l.familyInvitePhoneHint,
                helperMaxLines: 3,
                errorText: _phoneError,
                prefixIcon: const Icon(Icons.chat_outlined),
              ),
              onSubmitted: (_) => _invite(child.id, child.name),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _sending ? null : () => _invite(child.id, child.name),
                // A press that is doing something has to look like it. The
                // button used to grey out and say nothing else, which for the
                // seconds a slow write takes is the same picture as a button
                // that ignored the tap.
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt),
                label: Text(_sending ? l.familyInviteSending : l.familyInvite),
              ),
            ),
            if (_handoff case final handoff?) ...[
              const SizedBox(height: 14),
              _HandoffPanel(
                key: _panelKey,
                handoff: handoff,
                onCopy: () => _copyInvite(handoff.childName, handoff.email),
                onWhatsApp: () => _openWhatsApp(handoff),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Opens WhatsApp with the invitation already written out.
  ///
  /// The delivery that does not depend on anything staying configured — see
  /// [whatsAppLink]. She presses send in her own WhatsApp, on her own account,
  /// and can see for herself that it arrived.
  Future<void> _openWhatsApp(_Handoff handoff) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final opened = await openUrl(
      whatsAppLink(
        phone: handoff.phone,
        message: l.familyInviteMessage(
          handoff.childName,
          handoff.email,
          appLink(),
        ),
      ),
    );
    if (!mounted || opened) return;
    // Blocked, or no browser to open it in. The copy button is right beside
    // this one and always works.
    messenger.showAppSnack(
      appSnack(l.familyWhatsAppNotOpened, kind: SnackKind.info),
    );
  }


  /// The invitation as something she can actually send.
  ///
  /// The clipboard rather than a share sheet: this runs in a browser, the
  /// share sheet is not there on a desktop, and every messenger she might
  /// use accepts a paste.
  Future<void> _copyInvite(String childName, String email) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Where this copy of the app is actually served from, so the link works
    // on a custom domain too — see [appLink].
    final link = appLink();

    await Clipboard.setData(
      ClipboardData(
        text: l.familyInviteMessage(childName, email, link),
      ),
    );
    if (!mounted) return;
    messenger.showAppSnack(
      appSnack(l.familyInviteCopied, kind: SnackKind.done),
    );
  }

  /// How long the invitation may take to be acknowledged before the screen
  /// stops waiting for it.
  ///
  /// A Firestore write on the web completes when the *server* has it, and the
  /// document is in the local cache long before that. Offline — or on the edge
  /// of a signal, which is most of a lift and some of a clinic — the future
  /// simply never completes, and everything after it, including every word the
  /// screen was going to say, never happens either.
  static const _writeBudget = Duration(seconds: 12);

  Future<void> _invite(String childId, String childName) async {
    final l = AppLocalizations.of(context);
    final email = normalizeEmail(_email.text);

    if (!looksLikeEmail(email)) {
      // Empty and wrong are not the same mistake. A number in the WhatsApp
      // box and nothing here means he thinks the number *is* the invitation,
      // and «проверьте адрес» answers a question he did not ask — so this
      // says what the address is for instead, and puts the cursor in it.
      setState(
        () => _error = email.isEmpty ? l.familyEmailRequired : l.familyEmailInvalid,
      );
      _emailFocus.requestFocus();
      return;
    }
    // Typed but unusable is worth saying; left alone is not.
    final phone = normalizePhone(_phone.text);
    if (_phone.text.trim().isNotEmpty && !looksLikePhone(_phone.text)) {
      setState(() => _phoneError = l.familyPhoneInvalid);
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
      _phoneError = null;
      _handoff = null;
    });

    try {
      await ref
          .read(familyRepositoryProvider)
          .invite(
            childId: childId,
            ownerUid: ref.read(currentUidProvider),
            email: email,
          )
          .timeout(_writeBudget);
    } on TimeoutException {
      // Written locally and on its way. Nothing waits for the server: the
      // invitation text is already correct, and handing it over is what she
      // opened this card to do.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(l, e);
        _sending = false;
      });
      return;
    }
    if (!mounted) return;

    // The access exists the moment the document does. Everything below is only
    // how he finds out, so none of it can take the invitation with it.
    final token = await ref
        .read(idTokenReaderProvider)()
        // Bounded for the same reason as the write above: this reaches out to
        // Firebase, and without a network it reaches out for ever.
        .timeout(const Duration(seconds: 8), onTimeout: () => '');

    final mailed = await sendInviteMail(
      idToken: token,
      childId: childId,
      childName: childName,
      email: email,
      link: appLink(),
      fromName: ref.read(userProfileProvider).value?.displayName ?? '',
      phone: phone,
    );
    if (!mounted) return;

    setState(() {
      _sending = false;
      _email.clear();
      _phone.clear();
      // The answer, on the screen, staying there. What became of the letter is
      // one line of it; the two buttons under that line are the part that
      // actually delivers.
      _handoff = _Handoff(
        childName: childName,
        email: email,
        phone: phone,
        result: mailed,
      );
    });
    _showPanel();
  }

  /// Brings the answer to her. See [_panelKey].
  void _showPanel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _panelKey.currentContext;
      // No Scrollable above it in a test that pumps the card on its own, and
      // nothing to scroll when it is already in view. Neither is a problem.
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }
}

/// What happened to the invitation, and the two ways to hand it over.
///
/// Both buttons are always here, including after a successful automatic send.
/// The automatic one goes through an API account that can lapse and report a
/// delivery anyway — which is what «не отправляется, просто тишина» looked
/// like from the other end. A parent who can see the message text and press
/// send herself does not have to trust any of that.
class _HandoffPanel extends StatelessWidget {
  const _HandoffPanel({
    required this.handoff,
    required this.onCopy,
    required this.onWhatsApp,
    super.key,
  });

  final _Handoff handoff;
  final VoidCallback onCopy;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tone = handoff.delivered ? SoftTone.mint : SoftTone.sand;
    final ink = tone.ink(theme.brightness);

    // Three different truths, and the panel tells them apart. Saying
    // «отправлено» when nothing was sent is what sent a father to an inbox
    // that was never going to have anything in it.
    final headline = switch (handoff.result) {
      InviteMailResult.sentWhatsApp => l.familyInviteWhatsApp,
      InviteMailResult.sent => l.familyInviteMailed(handoff.email),
      InviteMailResult.notConfigured => l.familyInviteCreated,
      InviteMailResult.failed => l.familyInviteMailFailed,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.fill(theme.brightness),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                handoff.delivered
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 18,
                color: ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.familyInviteHandoff,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // Wrapped rather than in a Row: «Скопировать приглашение» and
          // «Открыть WhatsApp» side by side overflow a 360-pixel phone in
          // Russian, and in Kazakh they overflow it in every language.
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
                label: Text(l.familyCopyInvite),
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
