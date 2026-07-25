/// Deterministic red-flag triage.
///
/// This file contains no AI and never will. A language model that is merely
/// usually right is not an acceptable answer to "should I call an ambulance
/// for my two-month-old". Every rule here is explicit, ordered, and covered by
/// tests; the result is reproducible for identical input.
///
/// The output is never a diagnosis. It is one of four levels of urgency, and
/// every level ends by pointing at a doctor.
library;

enum TriageLevel {
  /// Call 103 now.
  emergency(
    'Вызывайте скорую — 103',
    'Эти признаки требуют помощи немедленно. Не ждите и не наблюдайте.',
  ),

  /// Seen by a doctor today.
  today(
    'Нужен врач сегодня',
    'Обратитесь к педиатру сегодня или в приёмный покой, если поликлиника закрыта.',
  ),

  /// Planned visit within a couple of days.
  soon(
    'Запишитесь к врачу',
    'Состояние не экстренное, но требует осмотра в ближайшие дни.',
  ),

  /// Home care, keep watching — but never a dead end. Even the calmest
  /// outcome has to point at a clinician, because this check sees only what
  /// was ticked and a parent's worry outranks it.
  home(
    'Можно наблюдать дома',
    'Явных тревожных признаков нет. Продолжайте наблюдение и вернитесь сюда, '
        'если что-то изменится. Если беспокойство не проходит — обратитесь '
        'к педиатру: тревога родителя сама по себе достаточное основание.',
  );

  const TriageLevel(this.title, this.advice);

  final String title;
  final String advice;

  bool operator >(TriageLevel other) => index < other.index;
}

/// A yes/no question. Answering yes raises urgency to at least [levelIfYes].
class TriageQuestion {
  const TriageQuestion({
    required this.id,
    required this.text,
    required this.levelIfYes,
    this.hint = '',
    this.minMonths = 0,
    this.maxMonths = 216,
  });

  final String id;
  final String text;

  /// Short clarification — how to actually check the sign.
  final String hint;

  final TriageLevel levelIfYes;
  final int minMonths;
  final int maxMonths;

  bool appliesAt(int ageMonths) =>
      ageMonths >= minMonths && ageMonths <= maxMonths;
}

/// The checklist, ordered from most to least dangerous.
///
/// Sources: NICE NG143 (traffic-light system for fever in under-5s) and the
/// WHO IMCI general danger signs.
const triageQuestions = <TriageQuestion>[
  TriageQuestion(
    id: 'unresponsive',
    text: 'Ребёнка трудно разбудить или он не реагирует на вас',
    hint: 'Не просыпается на голос и прикосновение, взгляд не фокусируется',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'breathing',
    text: 'Ребёнку трудно дышать',
    hint: 'Втягиваются межрёберные промежутки и ямка над грудиной, '
        'раздуваются крылья носа, кряхтящее дыхание, стонет на выдохе',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'cyanosis',
    text: 'Синеют или сереют губы, язык, кожа',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'rash',
    text: 'Есть сыпь, которая не бледнеет под прозрачным стаканом',
    hint: 'Прижмите дно стакана к сыпи и посмотрите сквозь стекло. '
        'Если пятна остались видны — это тревожный признак',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'seizure',
    text: 'Были судороги или ребёнок обмяк',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'neck',
    text: 'Скованная шея или выбухающий родничок',
    hint: 'Ребёнок не может прижать подбородок к груди; родничок '
        'выпуклый и напряжённый в спокойном состоянии',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'green-vomit',
    text: 'Рвота зелёного цвета или кровь в рвоте либо стуле',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'dehydration-severe',
    text: 'Не мочился 8 часов и больше, плачет без слёз, запавшие глаза',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'cry',
    text: 'Непрерывный монотонный крик или необычная вялость',
    hint: 'Крик не похож на обычный: высокий, слабый или безостановочный',
    levelIfYes: TriageLevel.emergency,
  ),
  TriageQuestion(
    id: 'not-drinking',
    text: 'Отказывается пить или сосать грудь',
    levelIfYes: TriageLevel.today,
  ),
  TriageQuestion(
    id: 'fewer-nappies',
    text: 'Мочится заметно реже обычного',
    hint: 'У грудничка меньше 6 мокрых подгузников за сутки',
    levelIfYes: TriageLevel.today,
    maxMonths: 24,
  ),
  TriageQuestion(
    id: 'fever-3-days',
    text: 'Температура держится больше 3 суток',
    levelIfYes: TriageLevel.today,
  ),
  TriageQuestion(
    id: 'worse-after-better',
    text: 'Ребёнку стало лучше, а потом резко хуже',
    levelIfYes: TriageLevel.today,
  ),
  TriageQuestion(
    id: 'ear-pain',
    text: 'Жалуется на боль в ухе или постоянно трогает ухо',
    levelIfYes: TriageLevel.soon,
  ),
  TriageQuestion(
    id: 'rash-mild',
    text: 'Появилась сыпь, которая бледнеет под стеклом',
    levelIfYes: TriageLevel.soon,
  ),
  TriageQuestion(
    id: 'parent-worried',
    text: 'Вам тревожно, даже если вы не можете объяснить почему',
    hint: 'Родительская интуиция — признанный клинический признак. '
        'Не игнорируйте её',
    levelIfYes: TriageLevel.soon,
  ),
];

/// Questions worth asking about a child of [ageMonths].
List<TriageQuestion> questionsForAge(int ageMonths) =>
    triageQuestions.where((q) => q.appliesAt(ageMonths)).toList();

/// Outcome of a triage run.
class TriageResult {
  const TriageResult({
    required this.level,
    required this.reasons,
    this.temperatureRule,
  });

  final TriageLevel level;

  /// The questions that drove the verdict, most severe first.
  final List<TriageQuestion> reasons;

  /// Set when the age/temperature rule fired on its own, explaining why the
  /// verdict is stricter than the checked boxes suggest.
  final String? temperatureRule;
}

/// Evaluates the checklist plus the age-and-temperature rules.
///
/// [temperature] is degrees Celsius, null if not measured. [answeredYes] holds
/// the ids of questions the parent confirmed.
///
/// The age rules come from NICE NG143: any fever in an infant under 3 months
/// is a red flag regardless of how well the baby looks, because newborns mount
/// almost no other signs of serious bacterial infection.
TriageResult runTriage({
  required int ageMonths,
  required Set<String> answeredYes,
  double? temperature,
}) {
  var level = TriageLevel.home;
  String? temperatureRule;

  final reasons = <TriageQuestion>[];
  for (final q in questionsForAge(ageMonths)) {
    if (!answeredYes.contains(q.id)) continue;
    reasons.add(q);
    if (q.levelIfYes > level) level = q.levelIfYes;
  }

  if (temperature != null) {
    if (ageMonths < 3 && temperature >= 38.0) {
      if (TriageLevel.emergency > level) level = TriageLevel.emergency;
      temperatureRule =
          'Ребёнку меньше 3 месяцев и температура ${_fmt(temperature)} °C. '
          'В этом возрасте любая лихорадка требует срочного осмотра, '
          'даже если ребёнок выглядит спокойным.';
    } else if (ageMonths < 6 && temperature >= 39.0) {
      if (TriageLevel.today > level) level = TriageLevel.today;
      temperatureRule =
          'Ребёнку меньше 6 месяцев и температура ${_fmt(temperature)} °C — '
          'нужен осмотр врача сегодня.';
    } else if (temperature >= 40.0) {
      if (TriageLevel.today > level) level = TriageLevel.today;
      temperatureRule =
          'Температура ${_fmt(temperature)} °C — покажите ребёнка врачу сегодня.';
    }
  }

  // Most severe reason first, so the screen leads with it.
  reasons.sort((a, b) => a.levelIfYes.index.compareTo(b.levelIfYes.index));

  return TriageResult(
    level: level,
    reasons: reasons,
    temperatureRule: temperatureRule,
  );
}

String _fmt(double t) =>
    t == t.roundToDouble() ? t.toStringAsFixed(0) : t.toStringAsFixed(1);
