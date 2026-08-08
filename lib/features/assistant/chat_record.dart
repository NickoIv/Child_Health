import '../../core/voice/voice_commands.dart';

/// Whether a message sent to the assistant is a record rather than a question.
///
/// The microphone card is gone from the home screen and its job came here:
/// «покормила левой 15 минут» said to the assistant is written down, and
/// «сколько раз кормить в три месяца» is answered. One field does both, which
/// is the only arrangement in which a mother with a baby on one arm does not
/// have to decide which of two inputs she wants before she starts talking.
///
/// Deliberately decided on the device, before the model is called. Three
/// reasons, and each of them is the difference between a feature and a
/// liability:
///
/// 1. **It works with no network and no key.** A feed written at four in the
///    morning cannot depend on a Cloudflare worker being up.
/// 2. **It is instant.** The old card wrote an entry in the time it took to
///    lift a thumb; a round trip to a model would make writing one slower than
///    it was before.
/// 3. **It cannot be talked into anything.** The reading comes from the same
///    regular expressions the dictation always used, so a temperature is
///    still a number between 34 and 43 that somebody actually said.
///
/// Everything this is unsure about goes to the assistant. That direction is
/// chosen on purpose: an assistant answering a sentence that was meant as a
/// note costs a parent one more tap, and a question filed as a fever costs her
/// a wrong reading in a medical record.
VoiceCommand? recordIn(String message, {required DateTime now}) {
  final text = message.trim();
  if (text.isEmpty) return null;

  // Asked to write, before anything else is considered. «Запиши, что он
  // сегодня улыбнулся бабушке» contains «что», which the question guard below
  // would otherwise read as a question — and an explicit instruction to write
  // something down outranks any guess made about the words after it.
  final asked = _writeDown.firstMatch(text);
  if (asked != null) {
    final rest = text.substring(asked.end).trim();
    if (rest.isNotEmpty) return parseVoiceCommand(rest, now: now);
  }

  if (_isQuestion(text)) return null;

  // Only a shape the parser recognises. A sentence it cannot place used to
  // become a note in her own words, and here it becomes a question instead —
  // there is now something on the other side of this field that can answer
  // «он третий день плохо спит», and «запиши…» above is the way to say that
  // the same words were meant for the diary.
  final command = parseVoiceCommand(text, now: now);
  return command.isNote ? null : command;
}

/// «Запиши…», «Отметь…», «Добавь запись…», and the «что» that usually follows.
///
/// Anchored at the start: a «запиши» in the middle of a sentence is part of a
/// question about what to write down, not an instruction to write it.
final _writeDown = RegExp(
  r'^(?:запиши(?:те)?|записать|запись:?|отметь(?:те)?|отметить|'
  r'добавь запись|добавить запись)'
  r'[\s,:.—-]*(?:что[\s,]*)?',
  caseSensitive: false,
);

/// A question, in the ordinary sense: it asks for something rather than
/// stating it.
///
/// Matched on whole words rather than on substrings. «кака» is how a nappy is
/// described out loud and «как» is how a question starts, and a substring
/// search cannot tell those apart — it would send «подгузник кака» to the
/// model and leave the parent wondering why nothing was written down.
bool _isQuestion(String text) {
  if (text.contains('?')) return true;

  final words = text
      .toLowerCase()
      .replaceAll('ё', 'е')
      // Splitting on everything that is not a letter or a digit. Cyrillic is
      // named explicitly: Dart's `\w` and `\b` are ASCII-only, and a class
      // built on them treats every Russian word as punctuation.
      .split(RegExp(r'[^а-яa-z0-9]+'));

  return words.any(_asking.contains);
}

/// The words that mean the sentence is for the assistant.
///
/// Interrogatives and the verbs a parent uses to ask for something written
/// *by* the assistant — «напиши поздравление бабушке» is a request, not a
/// diary entry, and it shares its stem with nothing the parser records.
const _asking = <String>{
  'сколько',
  'когда',
  'почему',
  'зачем',
  'что',
  'чем',
  'чего',
  'кто',
  'куда',
  'где',
  'как',
  'какой',
  'какая',
  'какое',
  'какие',
  'каком',
  'каких',
  'можно',
  'нужно',
  'надо',
  'стоит',
  'ли',
  'расскажи',
  'объясни',
  'подскажи',
  'посоветуй',
  'посчитай',
  'напиши',
  'придумай',
  'составь',
  'переведи',
  'помоги',
  'предложи',
  'how',
  'what',
  'when',
  'why',
  'should',
  'can',
};