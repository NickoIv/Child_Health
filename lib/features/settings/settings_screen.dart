import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/theme/theme_mode.dart';
import '../../firebase/push_messaging.dart';
import '../../models/app_user.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

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
              tooltip: 'Назад',
            ),
            Expanded(
              child: Text('Профиль и настройки',
                  style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SectionCard(
          title: 'Родитель',
          icon: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Как вас зовут'),
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
          title: 'Единицы измерения',
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
                      label: Text(
                        u == UnitSystem.metric ? 'см, кг' : 'in, lb',
                      ),
                    ),
                ],
                selected: {settings.unitSystem},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    _save(settings.copyWith(unitSystem: s.first)),
              ),
              const SizedBox(height: 12),
              Text(
                'Измерения всегда хранятся в метрических единицах и '
                'пересчитываются только для показа — поэтому переключение '
                'ничего не портит в уже введённых данных.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Температура остаётся в °C в обеих системах: все пороги в '
                'приложении и в рекомендациях указаны в градусах Цельсия.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: 'Оформление',
          icon: Icons.palette_outlined,
          accentColor: VizPalette.slot(6, theme.brightness),
          child: RadioGroup<ThemePreference>(
            groupValue: ref.watch(themePreferenceProvider),
            onChanged: (v) => ref
                .read(themePreferenceProvider.notifier)
                .set(v ?? ThemePreference.auto),
            child: Column(
              children: [
                for (final t in ThemePreference.values)
                  RadioListTile<ThemePreference>(
                    contentPadding: EdgeInsets.zero,
                    value: t,
                    title: Text(t.label),
                    subtitle: t.hint.isEmpty ? null : Text(t.hint),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const DashboardLayoutEditor(),
        const SizedBox(height: 16),

        SectionCard(
          title: 'Уведомления',
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
                title: const Text('Напоминать о прививках и лекарствах'),
                subtitle: _busyWithPush
                    ? const Text('Подключаю…')
                    : null,
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
                'Работает, пока приложение установлено на домашний экран '
                'или открыто в браузере. Разрешение спрашивает сам браузер — '
                'если откажете, включить снова можно будет только в его '
                'настройках сайта.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: 'Учётная запись',
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
                    label: const Text('Сменить пароль'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Удаление учётной записи',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Вместе с записью безвозвратно удаляются все дети, дневник, '
                'медкарта и напоминания. Отменить это будет нельзя, поэтому '
                'сначала выгрузите PDF-отчёт, если он вам нужен.',
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
                  label: const Text('Удалить учётную запись'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
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
      _tell('Пароль изменён');
    } on AuthException catch (e) {
      _tell(e.message, error: true);
    }
  }

  /// Deletes the parent's data first, then the account.
  ///
  /// That order matters: once the Firebase user is gone the security rules
  /// deny every one of those documents, and nothing could ever remove them.
  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
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
      _tell(e.message, error: true);
    }
  }

  void _tell(String message, {bool error = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.errorContainer : null,
        showCloseIcon: true,
      ),
    );
  }

  /// Turning the switch on is what asks the browser for permission.
  ///
  /// Never on load: an unprompted permission dialog is the fastest way to be
  /// denied forever, and on the web a denial can only be undone in the
  /// browser's own site settings.
  Future<void> _toggleNotifications(UserSettings settings, bool enable) async {
    setState(() {
      _busyWithPush = true;
      _pushMessage = null;
    });

    final profile = ref.read(userProfileProvider).value;
    final tokens = List<String>.of(profile?.pushTokens ?? const []);

    if (!enable) {
      await unregisterFromPush();
      await _save(
        settings.copyWith(notificationsEnabled: false),
        pushTokens: const [],
      );
      if (mounted) {
        setState(() {
          _busyWithPush = false;
          _pushOk = false;
          _pushMessage = 'Уведомления выключены';
        });
      }
      return;
    }

    final result = await registerForPush();
    if (!mounted) return;

    if (!result.status.isOn) {
      // The setting stays off: pretending it worked would leave a parent
      // waiting for reminders that can never arrive.
      await _save(settings.copyWith(notificationsEnabled: false));
      setState(() {
        _busyWithPush = false;
        _pushOk = false;
        _pushMessage = result.status.message;
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
    return AlertDialog(
      title: const Text('Сменить пароль'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Текущий пароль'),
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Введите текущий пароль' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Новый пароль'),
              // Firebase's own floor. Checking here saves a round trip and an
              // error message that arrives after the dialog has closed.
              validator: (v) => (v ?? '').length < 6
                  ? 'Минимум 6 символов'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repeat,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Новый пароль ещё раз',
              ),
              validator: (v) =>
                  v == _next.text ? null : 'Пароли не совпадают',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _PasswordChange(_current.text, _next.text),
            );
          },
          child: const Text('Сменить'),
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
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _word = 'УДАЛИТЬ';

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
    final ready =
        _password.text.isNotEmpty &&
        _confirm.text.trim().toUpperCase() == _word;

    return AlertDialog(
      title: const Text('Удалить учётную запись?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Все данные о детях будут удалены навсегда. Восстановить их '
            'не сможем ни мы, ни вы.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Ваш пароль'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            decoration: const InputDecoration(
              labelText: 'Напишите $_word',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: ready
              ? () => Navigator.pop(context, _password.text)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Удалить навсегда'),
        ),
      ],
    );
  }
}
