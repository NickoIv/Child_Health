import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode.dart';
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
                onChanged: (v) =>
                    _save(settings.copyWith(notificationsEnabled: v)),
                title: const Text('Напоминать о прививках и лекарствах'),
              ),
              Text(
                'Настройка сохраняется, но push-уведомления в веб-версии '
                'пока не подключены — напоминания видны в разделе '
                '«Напоминания».',
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
          icon: Icons.logout,
          accentColor: StatusColors.serious,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(UserSettings settings) async {
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
          ),
        );
  }
}
