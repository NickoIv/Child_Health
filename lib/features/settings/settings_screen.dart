import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_snack.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/l10n/auth_errors.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/night_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../data/auth_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/theme/theme_mode.dart';
import '../../firebase/push_messaging.dart';
import '../../models/app_user.dart';
import '../../providers.dart';
import '../shared/widgets.dart';
import 'import_screen.dart';

/// Parent profile and preferences, per requirement 2.1.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  bool _nameLoaded = false;
  bool _busyWithPush = false;
  String? _pushMessage;
  bool _pushOk = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    final settings = profile?.settings ?? const UserSettings();

    // Fill the field once, from whatever arrived first, and then leave it
    // alone — rewriting it on every rebuild would fight the parent typing.
    if (!_nameLoaded && profile != null) {
      _name.text = profile.displayName;
      _nameLoaded = true;
    }

    return PageBody(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back),
              tooltip: l.commonBack,
            ),
            Expanded(
              child: Text(l.settingsTitle,
                  style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SectionCard(
          title: l.settingsParent,
          icon: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l.settingsYourName),
                onSubmitted: (_) => _save(settings),
                onTapOutside: (_) => _save(settings),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.alternate_email,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      auth?.email ?? '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: l.settingsUnits,
          icon: Icons.straighten,
          accentColor: VizPalette.slot(0, theme.brightness),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<UnitSystem>(
                segments: [
                  for (final u in UnitSystem.values)
                    ButtonSegment(
                      value: u,
                      label: Text(u.localizedLabel(l)),
                    ),
                ],
                selected: {settings.unitSystem},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    _save(settings.copyWith(unitSystem: s.first)),
              ),
              const SizedBox(height: 12),
              Text(
                l.settingsUnitsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.settingsTemperatureHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: l.settingsAppearance,
          icon: Icons.palette_outlined,
          accentColor: VizPalette.slot(6, theme.brightness),
          child: RadioGroup<ThemePreference>(
            groupValue: ref.watch(themePreferenceProvider),
            onChanged: (v) => ref
                .read(themePreferenceProvider.notifier)
                .set(v ?? defaultTheme),
            child: Column(
              children: [
                for (final t in ThemePreference.values)
                  RadioListTile<ThemePreference>(
                    contentPadding: EdgeInsets.zero,
                    value: t,
                    title: Text(t.localizedLabel(l)),
                    subtitle: t == ThemePreference.auto
                        ? Text(l.themeAutoHint)
                        : null,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Its own card rather than a fourth option under the theme: it is not
        // a lighter or darker version of the app, it is the app with the blue
        // and green taken out of it, and it is chosen for a different reason.
        SectionCard(
          title: l.nightModeTitle,
          icon: Icons.nightlight_outlined,
          accentColor: VizPalette.slot(1, theme.brightness),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.nightModeHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<NightPreference>(
                groupValue: ref.watch(nightPreferenceProvider),
                onChanged: (v) => ref
                    .read(nightPreferenceProvider.notifier)
                    .set(v ?? defaultNight),
                child: Column(
                  children: [
                    for (final n in NightPreference.values)
                      RadioListTile<NightPreference>(
                        contentPadding: EdgeInsets.zero,
                        value: n,
                        title: Text(switch (n) {
                          NightPreference.off => l.nightModeOff,
                          NightPreference.auto => l.nightModeAuto,
                          NightPreference.on => l.nightModeOn,
                        }),
                        subtitle: n == NightPreference.auto
                            ? Text(l.nightModeAutoHint)
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const DashboardLayoutEditor(),
        const SizedBox(height: 16),

        SectionCard(
          title: l.settingsLanguage,
          icon: Icons.translate_outlined,
          accentColor: VizPalette.slot(4, theme.brightness),
          child: RadioGroup<Locale>(
            groupValue: ref.watch(localeProvider),
            onChanged: (value) {
              if (value != null) ref.read(localeProvider.notifier).set(value);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final locale in supportedLocales)
                  RadioListTile<Locale>(
                    contentPadding: EdgeInsets.zero,
                    value: locale,
                    // Each language names itself: a parent looking for Kazakh
                    // is looking for «Қазақша», not for its Russian name.
                    title: Text(switch (locale.languageCode) {
                      'en' => l.languageEnglish,
                      'kk' => l.languageKazakh,
                      _ => l.languageRussian,
                    }),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: l.settingsNotifications,
          icon: Icons.notifications_outlined,
          accentColor: VizPalette.slot(2, theme.brightness),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.notificationsEnabled,
                onChanged: _busyWithPush
                    ? null
                    : (v) => _toggleNotifications(settings, v),
                title: Text(l.settingsRemindMe),
                subtitle: _busyWithPush ? Text(l.settingsConnecting) : null,
              ),
              if (_pushMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _pushMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _pushOk
                        ? StatusColors.normal
                        : theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l.settingsNotificationsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Above the account card, and only here: bringing a diary over is
        // something a parent does once, in the first week, and a permanent
        // place in the navigation for a one-time job would cost more than it
        // gives.
        SectionCard(
          title: l.settingsImport,
          icon: Icons.upload_file_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsImportHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ImportScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(l.importPickButton),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: l.accountMenu,
          icon: Icons.manage_accounts_outlined,
          accentColor: StatusColors.serious,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap, not Row: on a narrow phone three buttons on one line
              // overflow, and this card is the one place a parent must never
              // find a control cut in half.
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.key_outlined),
                    label: Text(l.settingsChangePassword),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(Icons.logout),
                    label: Text(l.settingsSignOut),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(l.settingsDeleteSection, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                l.settingsDeleteWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _deleteAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l.settingsDeleteAccount),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Last card on the last screen, which is where a credit belongs: it
        // is the answer to "who made this", asked once, by someone who has
        // already gone looking for it.
        SectionCard(
          title: l.settingsAbout,
          icon: Icons.info_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AboutRow(label: l.settingsAuthor, value: AppInfo.author),
              const SizedBox(height: 10),
              _AboutRow(label: l.settingsVersion, value: AppInfo.version),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final l = AppLocalizations.of(context);
    // Asked before the dialog opens: a form whose only possible outcome is a
    // refusal is worse than a sentence explaining why.
    final user = ref.read(authStateProvider).value;
    if (user != null && !user.hasPassword) {
      _tell(l.authErrorNoPassword, error: true);
      return;
    }

    final result = await showDialog<_PasswordChange>(
      context: context,
      builder: (_) => const _PasswordDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: result.current,
            newPassword: result.next,
          );
      _tell(l.passwordChanged);
    } on AuthException catch (e) {
      _tell(authErrorText(l, e), error: true);
    }
  }

  /// Deletes the parent's data first, then the account.
  ///
  /// That order matters: once the Firebase user is gone the security rules
  /// deny every one of those documents, and nothing could ever remove them.
  Future<void> _deleteAccount() async {
    // A Google account has no password to type; Firebase is satisfied instead
    // by a fresh trip through Google, which the repository handles.
    final hasPassword = ref.read(authStateProvider).value?.hasPassword ?? true;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(requiresPassword: hasPassword),
    );
    if (password == null || !mounted) return;

    final uid = ref.read(currentUidProvider);
    final children = ref.read(childrenProvider).value ?? const [];

    try {
      final childRepository = ref.read(childRepositoryProvider);
      for (final child in children) {
        await childRepository.delete(child.id);
      }
      await ref.read(userRepositoryProvider).delete(uid);
      await ref
          .read(authRepositoryProvider)
          .deleteAccount(currentPassword: password);
      // No message: the router has already thrown us back to the login
      // screen, and this widget is gone.
    } on AuthException catch (e) {
      if (mounted) {
        _tell(authErrorText(AppLocalizations.of(context), e), error: true);
      }
    }
  }

  void _tell(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showApp(
      message,
      kind: error ? SnackKind.problem : SnackKind.done,
    );
  }

  /// Turning the switch on is what asks the browser for permission.
  ///
  /// Never on load: an unprompted permission dialog is the fastest way to be
  /// denied forever, and on the web a denial can only be undone in the
  /// browser's own site settings.
  Future<void> _toggleNotifications(UserSettings settings, bool enable) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busyWithPush = true;
      _pushMessage = null;
    });

    final profile = ref.read(userProfileProvider).value;
    final tokens = List<String>.of(profile?.pushTokens ?? const []);

    if (!enable) {
      await ref.read(notificationServiceProvider).cancelAll();
      await unregisterFromPush();
      await _save(
        settings.copyWith(notificationsEnabled: false),
        pushTokens: const [],
      );
      if (mounted) {
        setState(() {
          _busyWithPush = false;
          _pushOk = false;
          _pushMessage = l.settingsNotificationsOff;
        });
      }
      return;
    }

    // Reminders the phone raises by itself need the same system permission,
    // but they do not need a configured push backend — so they are asked for
    // first and judged separately.
    final notifications = ref.read(notificationServiceProvider);
    final localGranted = await notifications.requestPermission();
    if (localGranted) {
      await notifications.syncAll(
        ref.read(allRemindersProvider).value ?? const [],
      );
    }

    final result = await registerForPush();
    if (!mounted) return;

    if (!result.status.isOn) {
      // Push did not come up. If the phone itself may remind, the switch has
      // still earned its place; otherwise it goes back off rather than leave
      // a parent waiting for something that can never arrive.
      await _save(settings.copyWith(notificationsEnabled: localGranted));
      setState(() {
        _busyWithPush = false;
        _pushOk = localGranted;
        _pushMessage = localGranted
            ? l.settingsLocalOnly(result.status.message)
            : result.status.message;
      });
      return;
    }

    if (result.token != null && !tokens.contains(result.token)) {
      tokens.add(result.token!);
    }
    await _save(
      settings.copyWith(notificationsEnabled: true),
      pushTokens: tokens,
    );

    if (mounted) {
      setState(() {
        _busyWithPush = false;
        _pushOk = true;
        _pushMessage = PushStatus.granted.message;
      });
    }
  }

  Future<void> _save(UserSettings settings, {List<String>? pushTokens}) async {
    final uid = ref.read(currentUidProvider);
    final auth = ref.read(authStateProvider).value;
    if (uid.isEmpty) return;

    await ref
        .read(userRepositoryProvider)
        .save(
          AppUser(
            uid: uid,
            email: auth?.email ?? '',
            displayName: _name.text.trim(),
            settings: settings,
            pushTokens:
                pushTokens ??
                ref.read(userProfileProvider).value?.pushTokens ??
                const [],
          ),
        );
  }
}

/// One fact about the app: a small-caps label and the fact itself.
class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label.toUpperCase(),
            style: AppTheme.microLabel(theme.brightness),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Warm.onCard(theme.brightness),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordChange {
  const _PasswordChange(this.current, this.next);

  final String current;
  final String next;
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.settingsChangePassword),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: l.passwordCurrent),
              validator: (v) =>
                  (v ?? '').isEmpty ? l.passwordCurrentRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: l.passwordNew),
              // Firebase's own floor. Checking here saves a round trip and an
              // error message that arrives after the dialog has closed.
              validator: (v) =>
                  (v ?? '').length < 6 ? l.authPasswordTooShort : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repeat,
              obscureText: true,
              decoration: InputDecoration(labelText: l.passwordRepeat),
              validator: (v) =>
                  v == _next.text ? null : l.passwordsDoNotMatch,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _PasswordChange(_current.text, _next.text),
            );
          },
          child: Text(l.settingsChangeButton),
        ),
      ],
    );
  }
}

/// Deletion asks for the password *and* for the word «УДАЛИТЬ».
///
/// One is Firebase's requirement; the other is ours. This is the only action
/// in the app that cannot be undone, and a mis-tap should not be able to
/// reach it.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.requiresPassword});

  /// False for an account that signs in through Google or Apple: there is no
  /// password to ask for, and confirmation happens in the provider's own
  /// window after this dialog closes.
  final bool requiresPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final _word = AppLocalizations.of(context).deleteAccountWord;

  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final ready =
        (!widget.requiresPassword || _password.text.isNotEmpty) &&
        _confirm.text.trim().toUpperCase() == _word;

    return AlertDialog(
      title: Text(l.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.deleteAccountWarning,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (widget.requiresPassword) ...[
            TextField(
              controller: _password,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: l.deleteAccountPassword),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              l.deleteAccountGoogleNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _confirm,
            decoration: InputDecoration(
              labelText: l.deleteAccountWriteWord(_word),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: ready
              ? () => Navigator.pop(context, _password.text)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(l.deleteAccountConfirm),
        ),
      ],
    );
  }
}
