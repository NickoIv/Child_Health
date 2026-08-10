import '../models/development_log.dart';

/// What usually appears when, and deliberately not what a child owes anybody.
///
/// Every parenting app has this table and most of them get it wrong in the
/// same way: a date, a checkbox and the word «должен». A mother reads «в 4
/// месяца переворачивается», her four-month-old does not turn over, and the
/// evening is gone. The table is not the problem — the certainty is.
///
/// So four rules hold everything below, and they are load-bearing:
///
/// **Ranges, never dates.** Each entry is the window a skill usually appears
/// in, and the windows are wide because the truth is wide. The motor ones are
/// the WHO's own windows from the Multicentre Growth Reference Study, which
/// run from the 1st to the 99th percentile — sitting without support is 3.8 to
/// 9.2 months, walking alone 8.2 to 17.6. A child at either end is an ordinary
/// child.
///
/// **Nothing is ever overdue.** There is no function here that returns what a
/// child has not done. The app shows what is usual around now and what is
/// coming; a skill whose window has closed simply stops being mentioned. An
/// app is in no position to tell a mother her son is late, and the one thing
/// it would reliably produce is fear.
///
/// **No checklist.** Nothing here is tappable and nothing is ticked off. A
/// list with boxes is a score, and a score is the obligation we refused on the
/// home screen for the same reason. What marks a skill is her own diary: she
/// writes «перевернулся» and the entry finds itself.
///
/// **Her words are the record.** [Milestone.keys] are matched against
/// milestone entries she has already written, so this table never becomes a
/// second diary that can disagree with the first.
///
/// Russian, like the knowledge base beside it and like every title this app
/// stores: it is content, not interface.
enum MilestoneArea {
  /// Head, rolling, sitting, walking — and the hands.
  motor('Движение'),

  /// Smiling, playing, noticing who is who.
  social('Общение'),

  speech('Речь'),

  /// Spoon, cup, potty.
  selfCare('Самостоятельность');

  const MilestoneArea(this.title);

  final String title;
}

class Milestone {
  const Milestone({
    required this.id,
    required this.area,
    required this.fromMonths,
    required this.toMonths,
    required this.title,
    required this.keys,
  });

  final String id;
  final MilestoneArea area;

  /// The window it usually appears in, inclusive at both ends.
  final int fromMonths;
  final int toMonths;

  final String title;

  /// Lower-case fragments of what a parent actually writes in the diary.
  /// «перевернул» catches «перевернулся» and «перевернулась» both.
  final List<String> keys;

  bool usualAt(int ageMonths) =>
      ageMonths >= fromMonths && ageMonths <= toMonths;
}

/// The table. Wide windows on purpose; see the rules above.
const milestones = <Milestone>[
  // --- Motor: WHO windows where the WHO has one ---------------------------
  Milestone(
    id: 'head',
    area: MilestoneArea.motor,
    fromMonths: 1,
    toMonths: 4,
    title: 'Держит голову, лёжа на животе',
    keys: ['держит голов', 'голову держ'],
  ),
  Milestone(
    id: 'forearms',
    area: MilestoneArea.motor,
    fromMonths: 2,
    toMonths: 5,
    title: 'Опирается на предплечья, лёжа на животе',
    keys: ['опирается', 'на локт', 'на предплеч'],
  ),
  Milestone(
    id: 'grasp',
    area: MilestoneArea.motor,
    fromMonths: 3,
    toMonths: 7,
    title: 'Тянется к предмету и берёт его',
    keys: ['тянется', 'хватает', 'взял игрушк', 'взяла игрушк'],
  ),
  Milestone(
    id: 'roll',
    area: MilestoneArea.motor,
    fromMonths: 3,
    toMonths: 8,
    title: 'Переворачивается',
    keys: ['перевернул', 'переворач'],
  ),
  Milestone(
    id: 'sit',
    area: MilestoneArea.motor,
    fromMonths: 4,
    toMonths: 9,
    title: 'Сидит без поддержки',
    keys: ['сидит', 'сел сам', 'села сам'],
  ),
  Milestone(
    id: 'handToHand',
    area: MilestoneArea.motor,
    fromMonths: 6,
    toMonths: 10,
    title: 'Перекладывает предмет из руки в руку',
    keys: ['из руки в руку', 'переклад'],
  ),
  Milestone(
    id: 'crawl',
    area: MilestoneArea.motor,
    fromMonths: 5,
    toMonths: 14,
    title: 'Ползает на четвереньках',
    keys: ['ползёт', 'ползает', 'пополз', 'четверенек'],
  ),
  Milestone(
    id: 'standHold',
    area: MilestoneArea.motor,
    fromMonths: 5,
    toMonths: 12,
    title: 'Встаёт, держась за опору',
    keys: ['встал', 'встаёт', 'у опоры', 'за опору'],
  ),
  Milestone(
    id: 'pincer',
    area: MilestoneArea.motor,
    fromMonths: 8,
    toMonths: 14,
    title: 'Берёт мелкое двумя пальцами',
    keys: ['двумя пальц', 'пинцет'],
  ),
  Milestone(
    id: 'standAlone',
    area: MilestoneArea.motor,
    fromMonths: 7,
    toMonths: 17,
    title: 'Стоит без опоры',
    keys: ['стоит сам', 'стоит без опоры'],
  ),
  Milestone(
    id: 'walk',
    area: MilestoneArea.motor,
    fromMonths: 8,
    toMonths: 18,
    title: 'Делает первые шаги',
    keys: ['пошёл', 'пошла', 'первые шаг', 'первый шаг'],
  ),
  Milestone(
    id: 'tower',
    area: MilestoneArea.motor,
    fromMonths: 12,
    toMonths: 24,
    title: 'Ставит кубик на кубик',
    keys: ['кубик', 'башн'],
  ),
  Milestone(
    id: 'run',
    area: MilestoneArea.motor,
    fromMonths: 18,
    toMonths: 36,
    title: 'Бегает и поднимается по ступенькам',
    keys: ['бегает', 'ступень', 'лестниц'],
  ),

  // --- Social -------------------------------------------------------------
  Milestone(
    id: 'smile',
    area: MilestoneArea.social,
    fromMonths: 1,
    toMonths: 3,
    title: 'Улыбается в ответ',
    keys: ['улыб'],
  ),
  Milestone(
    id: 'laugh',
    area: MilestoneArea.social,
    fromMonths: 2,
    toMonths: 6,
    title: 'Смеётся вслух',
    keys: ['смеёт', 'засмеял', 'хохоч'],
  ),
  Milestone(
    id: 'strangers',
    area: MilestoneArea.social,
    fromMonths: 5,
    toMonths: 12,
    title: 'Отличает своих от чужих',
    keys: ['чужих', 'стесня'],
  ),
  Milestone(
    id: 'wave',
    area: MilestoneArea.social,
    fromMonths: 7,
    toMonths: 14,
    title: 'Машет «пока», играет в ладушки',
    keys: ['пока', 'ладушк', 'машет'],
  ),
  Milestone(
    id: 'point',
    area: MilestoneArea.social,
    fromMonths: 9,
    toMonths: 16,
    title: 'Показывает пальцем на то, что хочет',
    keys: ['показывает пальц', 'тычет'],
  ),
  Milestone(
    id: 'playNear',
    area: MilestoneArea.social,
    fromMonths: 18,
    toMonths: 36,
    title: 'Играет рядом с другими детьми',
    keys: ['играет с дет', 'играет рядом'],
  ),

  // --- Speech -------------------------------------------------------------
  Milestone(
    id: 'coo',
    area: MilestoneArea.speech,
    fromMonths: 1,
    toMonths: 5,
    title: 'Гулит',
    keys: ['гулит', 'агука', 'гуление'],
  ),
  Milestone(
    id: 'babble',
    area: MilestoneArea.speech,
    fromMonths: 5,
    toMonths: 11,
    title: 'Лепечет слоги: ба-ба, ма-ма',
    keys: ['лепеч', 'ба-ба', 'ма-ма', 'слоги'],
  ),
  Milestone(
    id: 'firstWord',
    area: MilestoneArea.speech,
    fromMonths: 9,
    toMonths: 16,
    title: 'Первое осмысленное слово',
    keys: ['первое слово', 'сказал первое'],
  ),
  Milestone(
    id: 'someWords',
    area: MilestoneArea.speech,
    fromMonths: 15,
    toMonths: 26,
    title: 'Говорит несколько слов',
    keys: ['говорит слов', 'много слов'],
  ),
  Milestone(
    id: 'twoWords',
    area: MilestoneArea.speech,
    fromMonths: 18,
    toMonths: 30,
    title: 'Соединяет два слова',
    keys: ['два слова', 'фраз'],
  ),
  Milestone(
    id: 'sentences',
    area: MilestoneArea.speech,
    fromMonths: 24,
    toMonths: 36,
    title: 'Говорит короткими предложениями',
    keys: ['предложен'],
  ),

  // --- Self-care ----------------------------------------------------------
  Milestone(
    id: 'spoonFed',
    area: MilestoneArea.selfCare,
    fromMonths: 5,
    toMonths: 10,
    title: 'Ест с ложки',
    keys: ['с ложки', 'ложки ест'],
  ),
  Milestone(
    id: 'cup',
    area: MilestoneArea.selfCare,
    fromMonths: 8,
    toMonths: 16,
    title: 'Пьёт из чашки',
    keys: ['из чашк', 'из кружк'],
  ),
  Milestone(
    id: 'spoonSelf',
    area: MilestoneArea.selfCare,
    fromMonths: 12,
    toMonths: 26,
    title: 'Сам держит ложку',
    keys: ['сам ест', 'сама ест', 'держит ложк'],
  ),
  Milestone(
    id: 'potty',
    area: MilestoneArea.selfCare,
    fromMonths: 18,
    toMonths: 36,
    title: 'Просится на горшок',
    keys: ['горшок', 'горшк'],
  ),
];

/// What is usual around now, in the order the areas are declared.
///
/// There is no companion returning what a child has *not* done, and there
/// will not be one: a window that has closed simply drops off this list.
List<Milestone> milestonesUsualAt(int ageMonths) =>
    milestones.where((m) => m.usualAt(ageMonths)).toList();

/// What opens next, so the card has something to say to a parent whose child
/// is between windows — and so the whole thing reads as what is coming rather
/// than as a standard being applied.
List<Milestone> milestonesSoonAfter(int ageMonths, {int within = 4}) =>
    milestones
        .where(
          (m) =>
              m.fromMonths > ageMonths && m.fromMonths <= ageMonths + within,
        )
        .toList()
      ..sort((a, b) => a.fromMonths.compareTo(b.fromMonths));

/// The ids she has already written down, matched against her own words.
///
/// Milestone entries only. A feed whose note happens to contain «сидит» is
/// not an announcement, and treating it as one would put a tick against
/// something that never happened.
Set<String> milestonesNotedIn(List<DevelopmentLog> logs) {
  final noted = <String>{};
  for (final log in logs) {
    if (log.type != LogType.milestone) continue;
    final text = '${log.title} ${log.description}'.toLowerCase();
    for (final m in milestones) {
      if (m.keys.any(text.contains)) noted.add(m.id);
    }
  }
  return noted;
}
