import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../knowledge/triage.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Red-flag check. Deterministic rules, no AI — see lib/knowledge/triage.dart.
class TriageScreen extends ConsumerStatefulWidget {
  const TriageScreen({super.key});

  @override
  ConsumerState<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends ConsumerState<TriageScreen> {
  final _checked = <String>{};
  final _temperature = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _temperature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final ageMonths = child?.ageInMonths ?? 0;
    final questions = questionsForAge(ageMonths);
    final theme = Theme.of(context);

    final result = _submitted
        ? runTriage(
            ageMonths: ageMonths,
            answeredYes: _checked,
            temperature: _parsedTemperature,
          )
        : null;

    return PageBody(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go('/assistant'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Назад',
            ),
            Expanded(
              child: Text(
                'Проверка тревожных признаков',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (child == null)
          const SectionCard(
            title: 'Нужен профиль ребёнка',
            icon: Icons.child_care_outlined,
            child: EmptyState(
              icon: Icons.child_care_outlined,
              message: 'Возраст влияет на оценку — особенно до 3 месяцев',
              hint: 'Создайте профиль в разделе «Дети»',
            ),
          )
        else ...[
          if (result != null) ...[
            _ResultCard(result: result),
            const SizedBox(height: 16),
          ],

          SectionCard(
            title: 'Температура',
            icon: Icons.thermostat_outlined,
            action: Text(
              '${child.name}, ${child.ageLabel}',
              style: theme.textTheme.bodySmall,
            ),
            child: TextField(
              controller: _temperature,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Если измеряли — введите, например 38.5',
                suffixText: '°C',
              ),
            ),
          ),
          const SizedBox(height: 16),

          SectionCard(
            title: 'Отметьте всё, что есть',
            icon: Icons.checklist_outlined,
            child: Column(
              children: [
                for (final q in questions)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _checked.contains(q.id),
                    onChanged: (v) => setState(() {
                      if (v ?? false) {
                        _checked.add(q.id);
                      } else {
                        _checked.remove(q.id);
                      }
                    }),
                    title: Text(q.text),
                    subtitle: q.hint.isEmpty
                        ? null
                        : Text(
                            q.hint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () => setState(() => _submitted = true),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('Оценить состояние'),
          ),
          const SizedBox(height: 10),
          if (_submitted)
            TextButton(
              onPressed: () => setState(() {
                _checked.clear();
                _temperature.clear();
                _submitted = false;
              }),
              child: const Text('Начать заново'),
            ),
        ],
      ],
    );
  }

  double? get _parsedTemperature {
    final text = _temperature.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final TriageResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (result.level) {
      TriageLevel.emergency => StatusColors.alert,
      TriageLevel.today => StatusColors.warning,
      TriageLevel.soon => StatusColors.warning,
      TriageLevel.home => StatusColors.normal,
    };
    final icon = switch (result.level) {
      TriageLevel.emergency => Icons.emergency,
      TriageLevel.today => Icons.local_hospital_outlined,
      TriageLevel.soon => Icons.event_available_outlined,
      TriageLevel.home => Icons.home_outlined,
    };

    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    result.level.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(result.level.advice, style: theme.textTheme.bodyMedium),

            if (result.temperatureRule != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  result.temperatureRule!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],

            if (result.reasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Что учтено:', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final r in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.text,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 16),
            Text(
              'Это не диагноз. Оценка построена по формальным признакам и '
              'не заменяет осмотр. Если вам тревожно, а проверка показала '
              '«наблюдать дома» — всё равно обратитесь к врачу.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
