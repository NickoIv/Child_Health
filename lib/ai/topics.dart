/// Which rules a question is answered under.
///
/// The assistant may now help with the ordinary business of having a small
/// child — the routine, the dummy, the paperwork, the nursery place — using
/// what the model knows. Medicine does not move: it is still answered only
/// from the forty-seven vetted articles, and nothing about that depends on the
/// model agreeing.
///
/// The gate is a whitelist, decided here in Dart before the model is called:
///
/// - Anything that touches health, symptoms, medicines, feeding, development
///   or vaccination is [AnswerMode.medical], the strict prompt as before.
/// - Only a question that matches the everyday list **and** nothing on the
///   medical list gets [AnswerMode.everyday].
/// - Anything the lists do not recognise is [AnswerMode.medical].
///
/// So the failure mode is a nappy question answered too carefully, never a
/// fever answered from memory. Asking a model to classify its own question is
/// the design this replaces: the one call where being wrong is expensive is
/// exactly the call not to hand it.
library;

enum AnswerMode {
  /// Only the retrieved articles. The default, and what silence means.
  medical,

  /// The model's own knowledge, for things a paediatric knowledge base was
  /// never going to contain.
  everyday,
}

/// Anything here forces [AnswerMode.medical], however domestic the rest of the
/// sentence sounds.
///
/// Stems rather than words, and deliberately over-eager, for the same reason
/// the emergency list is: a false positive costs a parent a slightly more
/// cautious answer, and a miss costs her a confident invented one.
const medicalStems = <String>[
  // Symptoms and states
  'температур', 'жар', 'лихорад', 'озноб', 'болезн', 'болеет', 'заболел',
  'симптом', 'диагноз', 'боль', 'болит', 'кашл', 'насморк', 'сопл', 'горло',
  'ухо', 'уши', 'сыпь', 'аллерг', 'рвот', 'тошнит', 'понос', 'диаре',
  'стул', 'запор', 'колик', 'срыгив', 'икот', 'зуб', 'десн', 'глаз', 'кожа',
  'опрелост', 'потниц', 'живот', 'дыхан', 'дышит', 'храп', 'родничок',
  'желтуш', 'пупок', 'обезвож', 'судорог', 'вялы', 'температура',
  // Medicine and care
  'лекарств', 'антибиотик', 'парацетамол', 'ибупрофен', 'нурофен', 'сироп',
  'капли', 'свеч', 'мазь', 'доза', 'дозиров', 'таблет', 'витамин', 'железо',
  'анемия', 'прививк', 'вакцин', 'манту', 'анализ', 'узи', 'врач', 'педиатр',
  'больниц', 'поликлиник', 'скорая', 'лечен', 'лечить',
  // Feeding, growth, development
  'кормл', 'кормить', 'груд', 'гв ', 'молок', 'смес', 'бутылочк', 'прикорм',
  // «вес» on its own would swallow «весь день» and «весной», so the weight
  // stems are the forms that can only be about a weight.
  'аппетит', 'недобор', 'весит', 'веса ', 'вес ребен', 'набрал', 'прибавк',
  'рост', 'перцентил', 'норма', 'развит',
  'ползает', 'переворач', 'сидит', 'ходит', 'говорит', 'отстает', 'отстаёт',
  // Sleep as a problem rather than a schedule
  'не спит', 'плохо спит', 'просыпается', 'засыпа', 'апноэ',
];

/// And what may be answered from the model's own knowledge, when nothing above
/// matched. The four topics the plan named, and their neighbours.
const everydayStems = <String>[
  // Paperwork and money
  'документ', 'свидетельств', 'прописк', 'регистрац', 'пособи', 'выплат',
  'egov', 'егов', 'иин', 'удостоверен', 'загранпаспорт', 'декрет', 'отпуск',
  'бюджет', 'расход',
  // Nursery, childcare, school
  'садик', 'ясли', 'детский сад', 'очеред', 'няня', 'школ',
  'развивашк', 'кружок',
  // Routine and habits
  'режим дня', 'распорядок', 'расписан', 'ритуал', 'соск', 'пустышк',
  'горшок', 'приуча',
  // Behaviour and the family
  'истерик', 'каприз', 'упрям', 'ревнос', 'братик', 'сестрич', 'границ',
  'наказ', 'похвал', 'мультик', 'экран', 'планшет', 'игрушк', 'книжк',
  // Things and going places
  'коляск', 'автокресл', 'кроватк', 'слинг', 'переноск', 'одежд', 'обув',
  'путешеств', 'поездк', 'самолёт', 'самолет', 'поезд', 'дача', 'прогулк',
  'стирк', 'уборк', 'фотограф', 'праздник', 'день рожден', 'имя ребёнк',
];

/// Which rules [question] is answered under.
///
/// `ё` is folded to `е` exactly as in the emergency gate: parents type both,
/// and a filter that misses «зелёнка» because the list spells it «зеленка» is
/// a filter that misses.
AnswerMode modeFor(String question) {
  final q = question.toLowerCase().replaceAll('ё', 'е');
  bool hits(List<String> stems) =>
      stems.any((stem) => q.contains(stem.replaceAll('ё', 'е')));

  if (hits(medicalStems)) return AnswerMode.medical;
  if (hits(everydayStems)) return AnswerMode.everyday;

  // Unrecognised is not "harmless". The strict prompt is what silence means.
  return AnswerMode.medical;
}
