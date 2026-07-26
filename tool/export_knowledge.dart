// Exports the knowledge base as a single document for clinical review.
//
// The base is 47 articles spread across six Dart files. Nobody is going to
// review that by reading source, and a reviewer who has to hunt for the
// numbers will miss one. This produces a document a paediatrician can read
// end to end in one sitting, with every article in the same shape and a
// separate appendix collecting every dose, threshold and age boundary — the
// places where an error is dangerous rather than merely wrong.
//
// Run:  dart run tool/export_knowledge.dart
// Out:  docs/knowledge_review.md

import 'dart:io';

import 'package:child_health_tracker/knowledge/article.dart';
import 'package:child_health_tracker/knowledge/knowledge_base.dart';
import 'package:child_health_tracker/knowledge/triage.dart';

void main() {
  final out = StringBuffer();
  _writeHeader(out);
  _writeTriage(out);
  _writeArticles(out);
  _writeNumbersAppendix(out);

  final file = File('docs/knowledge_review.md');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(out.toString());

  stdout.writeln(
    'Записано ${file.path}: ${knowledgeBase.length} статей, '
    '${out.length ~/ 1024} КБ',
  );
}

void _writeHeader(StringBuffer out) {
  final now = DateTime.now();
  out.writeln('# База знаний: материал для проверки педиатром');
  out.writeln();
  out.writeln(
    'Сформировано автоматически ${now.day}.${_two(now.month)}.${now.year} '
    'из исходного кода приложения «Календарь развития и здоровья ребёнка» '
    '(Казахстан).',
  );
  out.writeln();
  out.writeln('**Что требуется проверить, в порядке важности:**');
  out.writeln();
  out.writeln(
    '1. **Числа.** Дозировки, пороги температуры, возрастные границы. '
    'Все они собраны отдельно в приложении в конце документа — '
    'начинать разумно оттуда.',
  );
  out.writeln(
    '2. **Признаки для вызова скорой.** Не пропущено ли что-то важное '
    'и нет ли лишнего, что вызовет ложные вызовы.',
  );
  out.writeln(
    '3. **Соответствие практике Казахстана.** Материал опирается на ВОЗ, '
    'NICE, AAP и NHS; расхождения с местными протоколами возможны.',
  );
  out.writeln(
    '4. **Формулировки.** Текст читает невыспавшийся родитель, '
    'а не коллега.',
  );
  out.writeln();
  out.writeln(
    'Замечания удобно оставлять прямо в тексте — достаточно указать '
    'идентификатор статьи в квадратных скобках рядом с заголовком.',
  );
  out.writeln();
  out.writeln('---');
  out.writeln();
}

void _writeTriage(StringBuffer out) {
  out.writeln('## Триаж: автоматическая оценка срочности');
  out.writeln();
  out.writeln(
    'Это не текст, а работающие правила. Приложение задаёт вопросы ниже '
    'и выдаёт один из четырёх уровней. Языковая модель в этой цепочке '
    'не участвует.',
  );
  out.writeln();

  out.writeln('### Уровни');
  out.writeln();
  for (final level in TriageLevel.values) {
    out.writeln('- **${level.title}** — ${level.advice}');
  }
  out.writeln();

  out.writeln('### Вопросы и то, к чему приводит ответ «да»');
  out.writeln();
  out.writeln('| Вопрос | Уровень | Возраст |');
  out.writeln('|---|---|---|');
  for (final q in triageQuestions) {
    final age = q.minMonths == 0 && q.maxMonths >= 216
        ? 'любой'
        : '${q.minMonths}–${q.maxMonths} мес.';
    out.writeln('| ${q.text} | ${q.levelIfYes.title} | $age |');
  }
  out.writeln();

  out.writeln('### Правила по возрасту и температуре');
  out.writeln();
  out.writeln(
    '- Младше **3 месяцев** и температура **38 °C и выше** → скорая, '
    'независимо от самочувствия.',
  );
  out.writeln(
    '- Младше **6 месяцев** и температура **39 °C и выше** → врач сегодня.',
  );
  out.writeln('- Температура **40 °C и выше** в любом возрасте → врач сегодня.');
  out.writeln();
  out.writeln('---');
  out.writeln();
}

void _writeArticles(StringBuffer out) {
  out.writeln('## Статьи');
  out.writeln();

  for (final section in KbSection.values) {
    final articles = articlesInSection(section);
    if (articles.isEmpty) continue;

    out.writeln('## ${section.title}');
    out.writeln();
    out.writeln('_${section.subtitle}_');
    out.writeln();

    for (final a in articles) {
      out.writeln('### ${a.title}  `[${a.id}]`');
      out.writeln();
      out.writeln('> ${a.summary}');
      out.writeln();

      final ageRange = a.minMonths == 0 && a.maxMonths >= 216
          ? 'любой возраст'
          : 'возраст ${a.minMonths}–${a.maxMonths} мес.';
      out.writeln('*Показывается для: $ageRange*');
      out.writeln();

      if (a.emergency.isNotEmpty) {
        out.writeln('**СКОРАЯ ПОМОЩЬ (103):**');
        out.writeln();
        for (final e in a.emergency) {
          out.writeln('- $e');
        }
        out.writeln();
      }

      out.writeln('**Что делать сейчас:**');
      out.writeln();
      for (final d in a.doNow) {
        out.writeln('- $d');
      }
      out.writeln();

      out.writeln('**Когда к врачу:**');
      out.writeln();
      for (final c in a.callDoctor) {
        out.writeln('- $c');
      }
      out.writeln();

      if (a.details.isNotEmpty) {
        out.writeln('**Подробнее:**');
        out.writeln();
        for (final d in a.details) {
          out.writeln('- $d');
        }
        out.writeln();
      }

      out.writeln('*Источники: ${a.sources.map((s) => s.title).join('; ')}*');
      out.writeln();
      out.writeln('---');
      out.writeln();
    }
  }
}

/// Every sentence containing a number, gathered in one place.
///
/// A reviewer reading 47 articles in sequence will skim; the same reviewer
/// checking a list of doses will not. This appendix exists because the
/// dangerous errors in this base are numeric, not editorial.
void _writeNumbersAppendix(StringBuffer out) {
  final numeric = RegExp(r'\d');

  out.writeln('# Приложение: все числа');
  out.writeln();
  out.writeln(
    'Каждое утверждение с числом, собранное из всех статей. Дозировки, '
    'пороги, возрастные границы и сроки. Это место, где ошибка опаснее '
    'всего, поэтому проверять удобнее здесь, а не в тексте.',
  );
  out.writeln();

  var total = 0;
  for (final a in knowledgeBase) {
    final lines = <(String, String)>[
      for (final e in a.emergency)
        if (e.contains(numeric)) ('скорая', e),
      for (final d in a.doNow)
        if (d.contains(numeric)) ('действие', d),
      for (final c in a.callDoctor)
        if (c.contains(numeric)) ('к врачу', c),
      for (final d in a.details)
        if (d.contains(numeric)) ('подробнее', d),
    ];
    if (lines.isEmpty) continue;

    out.writeln('### ${a.title}  `[${a.id}]`');
    out.writeln();
    for (final (where, text) in lines) {
      out.writeln('- _($where)_ $text');
      total++;
    }
    out.writeln();
  }

  out.writeln('---');
  out.writeln();
  out.writeln(
    'Всего утверждений с числами: **$total** '
    'в ${knowledgeBase.length} статьях.',
  );
}

String _two(int n) => n.toString().padLeft(2, '0');
