import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/invite_code.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// The other end of an invitation link.
///
/// Nobody typed an address to get here and nobody types one now. He opened a
/// message in WhatsApp, signed in with whatever Google account he already
/// uses, and this reads the address off his own token.
///
/// One button, and everything above it exists so the button is not a surprise:
/// what the invitation gives, what it does not, and — the part that matters
/// most — which account it is about to be attached to. A phone signed into a
/// second Google account is the ordinary case, not the strange one, and
/// finding out afterwards would mean asking for a new link.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  /// Null while it is being fetched. The screen shows a spinner rather than
  /// guessing, because "no such code" and "not looked up yet" would otherwise
  /// be the same picture.
  InviteCode? _invitation;
  bool _looked = false;
  bool _busy = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _look();
  }

  Future<void> _look() async {
    InviteCode? found;
    try {
      found = await ref.read(familyRepositoryProvider).codeById(widget.code);
    } catch (_) {
      // A refused read and a missing code are the same sentence here: the
      // link does not work, ask for another.
      found = null;
    }
    if (!mounted) return;
    setState(() {
      _invitation = found;
      _looked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final email = ref.watch(currentEmailProvider);
    final invitation = _invitation;
    final usable = invitation != null && invitation.isUsableAt(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(l.joinTitle),
        titleTextStyle: theme.textTheme.titleMedium,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close),
          tooltip: l.commonClose,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: !_looked
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _body(l, theme, usable, email),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    AppLocalizations l,
    ThemeData theme,
    bool usable,
    String email,
  ) {
    if (_done) {
      return [
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: StatusColors.normal,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.joinDone, style: theme.textTheme.titleSmall),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.go('/'),
          child: Text(l.joinOpenDiary),
        ),
      ];
    }

    if (!usable) {
      // Expired, already used, or never existed. All three are the same thing
      // to him and all three have the same answer, so they are not told apart
      // — a link that says "already used by someone else" would only invite
      // him to wonder who.
      return [
        Row(
          children: [
            Icon(
              Icons.link_off,
              size: 22,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.joinSpent, style: theme.textTheme.titleSmall),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () => context.go('/'),
          child: Text(l.commonClose),
        ),
      ];
    }

    return [
      Icon(Icons.diversity_1_outlined, size: 32, color: Warm.accent),
      const SizedBox(height: 14),
      Text(l.joinIntro, style: theme.textTheme.titleSmall),
      const SizedBox(height: 10),
      Text(
        l.joinReadOnly,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      // The account, said out loud before the button rather than discovered
      // after it.
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SoftTone.sky.fill(theme.brightness),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          l.joinAs(email.isEmpty ? '—' : email),
          style: theme.textTheme.bodySmall?.copyWith(
            color: SoftTone.sky.ink(theme.brightness),
          ),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _busy ? null : _accept,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(l.joinAccept),
      ),
    ];
  }

  Future<void> _accept() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      await ref
          .read(familyRepositoryProvider)
          .claimCode(
            code: widget.code,
            viewerUid: ref.read(currentUidProvider),
            viewerEmail: ref.read(currentEmailProvider),
            now: DateTime.now(),
          );
      if (!mounted) return;
      setState(() {
        _done = true;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Two people opened the same link at once, or it expired between the
      // screen being drawn and the button being pressed. Re-reading it puts
      // the honest state on the screen instead of a complaint.
      setState(() => _busy = false);
      messenger.showAppSnack(appSnack(l.joinSpent, kind: SnackKind.info));
      await _look();
    }
  }
}
