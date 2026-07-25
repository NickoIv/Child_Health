import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final dayMonth = DateFormat('d MMMM', 'ru_RU');
final dayMonthYear = DateFormat('d MMMM y', 'ru_RU');
final shortDate = DateFormat('dd.MM.yyyy', 'ru_RU');
final timeOfDay = DateFormat('HH:mm', 'ru_RU');

/// Page padding that keeps content readable on a wide browser window instead
/// of stretching a single column across 2000 px.
class PageBody extends StatelessWidget {
  const PageBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: children,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.action,
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Big number with a caption, used across the dashboard and the statistics.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.caption,
    this.color,
    super.key,
  });

  final String value;
  final String caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.hint,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Turns a backend failure into something a parent can act on.
///
/// Firestore reports problems as English exception dumps with a console URL
/// in them; showing that raw is no help to anyone.
String friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('failed-precondition') && text.contains('index')) {
    return 'База данных достраивает индексы. Это занимает несколько минут '
        'после первого развёртывания — обновите страницу чуть позже.';
  }
  if (text.contains('permission-denied')) {
    return 'Нет доступа к этим данным. Попробуйте выйти и войти заново.';
  }
  if (text.contains('unavailable') || text.contains('network')) {
    return 'Нет связи с сервером. Изменения сохранятся локально и '
        'синхронизируются, когда соединение вернётся.';
  }
  if (text.contains('unauthenticated')) {
    return 'Сессия истекла. Войдите в учётную запись заново.';
  }
  return 'Не удалось загрузить данные. Попробуйте обновить страницу.';
}

/// Error panel with the human-readable message up front and the raw text
/// tucked away for when it has to be reported.
class ErrorState extends StatelessWidget {
  const ErrorState({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            friendlyError(error),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(
              'Техническая информация',
              style: theme.textTheme.labelSmall,
            ),
            shape: const Border(),
            collapsedShape: const Border(),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableText(
                  error.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown by every screen when no child profile exists yet.
class NoChildPlaceholder extends StatelessWidget {
  const NoChildPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(
        icon: Icons.child_care_outlined,
        message: 'Профиль ребёнка ещё не создан',
        hint: 'Откройте раздел «Дети» и добавьте первый профиль',
      ),
    );
  }
}

/// Russian noun agreement: 1 день / 2 дня / 5 дней.
String plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return '$n $many';
  if (mod10 == 1) return '$n $one';
  if (mod10 >= 2 && mod10 <= 4) return '$n $few';
  return '$n $many';
}
