import '../../models/development_log.dart';

/// What a spoken sentence turned out to be.
///
/// Seven shapes and a fallback, matched by regular expressions on the device.
/// There is no model here, nothing is sent anywhere, and nothing is saved
/// until a parent has read the confirmation and tapped once — which is the
/// line this whole feature is built around. A microphone that wrote a fever
/// into a medical record because a room was noisy would be worse than no
/// microphone at all.
enum VoiceIntent { feeding, bottle, sleep, nappy, temperature, note }

/// One parsed sentence, ready to be shown back and then written.
class VoiceCommand {
  const VoiceCommand({
    required this.intent,
    required this.text,
    this.minutes,
    this.millilitres,
    this.side,
    this.nappyKind,
    this.temperatureC,
    this.at,
  });

  /// Everything that was heard, kept whatever the intent turned out to be:
  /// the confirmation card shows it, so a mis-hearing is caught by the person
  /// who said it rather than by the record a week later.
  final String text;

  final VoiceIntent intent;
  final int? minutes;
  final int? millilitres;
  final FeedingSide? side;
  final NappyKind? nappyKind;
  final double? temperatureC;

  /// When she said it happened, if she said.
  ///
  /// Null means now, which is what a dictated entry used to be without
  /// exception — «покормила вчера в девять вечера» was filed at the moment the
  /// microphone stopped, and the whole point of saying the time out loud was
  /// lost. Typing it into the form put it on the right day; speaking it should
  /// too.
  final DateTime? at;

  /// Nothing matched, so it becomes a note in her own words.
  bool get isNote => intent == VoiceIntent.note;

  VoiceCommand withMoment(DateTime? moment) => VoiceCommand(
    intent: intent,
    text: text,
    minutes: minutes,
    millilitres: millilitres,
    side: side,
    nappyKind: nappyKind,
    temperatureC: temperatureC,
    at: moment,
  );
}

/// Turns a heard sentence into a command, or into a note.
///
/// Ordered from the most specific pattern to the least: "bottle 90 ml" is a
/// feed, and a sentence containing both a side and a bottle is read as the
/// bottle, because that is the number the parent bothered to say.
///
/// Three languages, one set of patterns. The numbers and units are what carry
/// the meaning, and the words around them are matched as alternatives rather
/// than parsed — a grammar here would be a parser to maintain in a language
/// nobody on the team reads.
VoiceCommand parseVoiceCommand(String heard, {DateTime? now}) {
  final moment = spokenMoment(heard, now: now ?? DateTime.now());
  return _parseIntent(heard).withMoment(moment);
}

VoiceCommand _parseIntent(String heard) {
  final text = heard.trim();
  final s = text.toLowerCase().replaceAll(',', '.');

  double? number(RegExp pattern) {
    final match = pattern.firstMatch(s);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  // Temperature first: it is the one number in this app that must never be
  // mistaken for anything else. Thirty-four to forty-three, so "37.8" is a
  // reading and "90" cannot be.
  final degrees = number(
    RegExp(r'(?:температур\w*|дене қызу\w*|temperature|temp)\D{0,12}(\d{2}[.]?\d?)'),
  ) ??
      number(RegExp(r'\b(3[4-9]\.\d|4[0-3]\.\d)\b'));
  if (degrees != null && degrees >= 34 && degrees <= 43) {
    return VoiceCommand(
      intent: VoiceIntent.temperature,
      text: text,
      temperatureC: degrees,
    );
  }

  final isNappy = RegExp(r'подгузн|памперс|жаялық|nappy|diaper').hasMatch(s);
  if (isNappy) {
    final wet = RegExp(r'мокр|пись|дымқыл|wet|pee').hasMatch(s);
    final dirty = RegExp(r'кака|стул|грязн|нәжіс|stool|dirty|poo').hasMatch(s);
    // Both said, or neither: "both" is the honest record of a sentence that
    // mentioned each, and a wet nappy is the ordinary case when nothing was
    // specified.
    final kind = wet && dirty
        ? NappyKind.both
        : dirty
        ? NappyKind.dirty
        : NappyKind.wet;
    return VoiceCommand(
      intent: VoiceIntent.nappy,
      text: text,
      nappyKind: kind,
    );
  }

  final minutes = _minutes(s);

  if (RegExp(r'сон|спал|поспал|ұйықта|ұйқы|slept|sleep').hasMatch(s)) {
    return VoiceCommand(
      intent: VoiceIntent.sleep,
      text: text,
      minutes: minutes,
    );
  }

  final millilitres = number(
    RegExp(r'(\d{1,4})\s*(?:мл|ml|мілілитр\w*|миллилитр\w*)'),
  )?.round();
  final isBottle = RegExp(r'бутыл|смес|сүтқоспа|bottle|formula').hasMatch(s);
  if (isBottle || (millilitres != null && millilitres > 0)) {
    return VoiceCommand(
      intent: VoiceIntent.bottle,
      text: text,
      millilitres: millilitres,
      side: FeedingSide.bottle,
    );
  }

  if (RegExp(r'кормл|корми|покорм|груд|емізу|тамақтанд|feed|nurs').hasMatch(s)) {
    // No `\b` around the Cyrillic: Dart's word boundary is ASCII-only, so
    // `\bлев` never matches at all — the space before it is not a boundary
    // when neither side is an ASCII word character.
    final left = RegExp(r'лев|сол |\bleft\b').hasMatch(s);
    final right = RegExp(r'прав|оң |\bright\b').hasMatch(s);
    return VoiceCommand(
      intent: VoiceIntent.feeding,
      text: text,
      minutes: minutes,
      side: left
          ? FeedingSide.left
          : right
          ? FeedingSide.right
          : null,
    );
  }

  // Heard, not understood. It becomes a note in her own words rather than a
  // guess in ours.
  return VoiceCommand(intent: VoiceIntent.note, text: text);
}

/// The entry a confirmed command becomes.
///
/// Deliberately the same shapes the quick sheets already write — same types,
/// same titles, same fields — so a spoken feed and a tapped one are one record
/// on one timeline, and every count in the app keeps working without knowing
/// which of them happened.
DevelopmentLog voiceLog(
  VoiceCommand command, {
  required String childId,
  /// When the entry happened, for a sentence that did not say. Overridden by
  /// [VoiceCommand.at] whenever she named a moment out loud.
  required DateTime at,
}) {
  final note = command.text;
  final when = command.at ?? at;

  return switch (command.intent) {
    VoiceIntent.feeding || VoiceIntent.bottle => DevelopmentLog(
      id: '',
      childId: childId,
      date: when,
      type: LogType.feeding,
      // Titles are what already sits in Firestore, so they stay the model's
      // own wording rather than the language of whoever was speaking.
      title: LogType.feeding.label,
      description: note,
      feedingSide: command.side,
      durationMinutes: command.minutes,
    ),
    VoiceIntent.sleep => DevelopmentLog(
      id: '',
      childId: childId,
      date: when,
      type: LogType.sleep,
      title: LogType.sleep.label,
      description: note,
      durationMinutes: command.minutes,
    ),
    VoiceIntent.nappy => DevelopmentLog(
      id: '',
      childId: childId,
      date: when,
      type: LogType.nappy,
      title: LogType.nappy.label,
      description: note,
      nappyKind: command.nappyKind,
    ),
    VoiceIntent.temperature => DevelopmentLog(
      id: '',
      childId: childId,
      date: when,
      // The same threshold the temperature sheet uses, so a spoken 38.5 lands
      // in the illness history exactly where a typed one does.
      type: command.temperatureC! >= 38.0
          ? LogType.illness
          : LogType.measurement,
      title: '${LogTitles.temperature} '
          '${command.temperatureC!.toStringAsFixed(1)} °C',
      description: note,
      metrics: Metrics(temperatureC: command.temperatureC),
      severity: command.temperatureC! >= 39.0
          ? Severity.severe
          : command.temperatureC! >= 38.0
          ? Severity.moderate
          : null,
    ),
    VoiceIntent.note => DevelopmentLog(
      id: '',
      childId: childId,
      date: when,
      type: LogType.note,
      title: LogType.note.label,
      description: note,
    ),
  };
}

/// The moment a spoken sentence named, or null if it named none.
///
/// «Покормила вчера в девять вечера» used to be filed at the second the
/// microphone stopped — the same sentence typed into the form lands on the
/// right evening, and the difference was the whole reason to correct it by
/// hand afterwards. Anything this cannot place stays null and the entry is
/// stamped now, exactly as before.
///
/// Past-biased on purpose. This writes diary entries, which are records of
/// things that already happened: a bare «в девять» heard at eight in the
/// morning is last night, not tonight. Say «завтра» and it is tomorrow.
DateTime? spokenMoment(String heard, {required DateTime now}) {
  final s = heard.toLowerCase().replaceAll('ё', 'е');

  // "Two hours ago" wins outright: it is the one phrasing that fixes both the
  // day and the time by itself, and it needs no guessing.
  final ago = _minutesAgo(s);
  if (ago != null) return now.subtract(Duration(minutes: ago));

  final day = _spokenDay(s, now);
  final time = _spokenTime(s);
  if (day == null && time == null) return null;

  final base = day ?? DateTime(now.year, now.month, now.day);
  final at = time == null
      // A day without a clock keeps the current time of day: «вчера покормила»
      // said at ten in the morning is about the morning.
      ? DateTime(base.year, base.month, base.day, now.hour, now.minute)
      : DateTime(base.year, base.month, base.day, time.$1, time.$2);

  // A clock time with no day that has not happened yet belongs to yesterday.
  // Only when she named no day at all — «завтра в девять» is not a slip.
  if (day == null && at.isAfter(now)) {
    return at.subtract(const Duration(days: 1));
  }
  return at;
}

/// «час назад», «20 минут назад», «полчаса назад».
int? _minutesAgo(String s) {
  if (!s.contains('назад')) return null;
  if (RegExp(r'полчаса\s+назад').hasMatch(s)) return 30;

  // `[а-я]*` rather than `\w*`: Dart's `\w` is ASCII-only, so «мин\w*» stops
  // dead at «мин» and never reaches the «ут» — the same trap the feeding
  // patterns above document for `\b`. It cost «20 минут назад» entirely.
  final hours = RegExp(
    r'(\d{1,2}|час|полтора|два|две|три|четыре|пять|шесть)\s*'
    r'(?:час[а-я]*)?\s*назад',
  ).firstMatch(s);
  final mins = RegExp(r'(\d{1,3})\s*мин[а-я]*\s*назад').firstMatch(s);

  if (mins != null) return int.tryParse(mins.group(1)!);
  if (hours == null) return null;

  final word = hours.group(1)!;
  final asNumber = int.tryParse(word);
  // Only a number followed by an hour word is hours; a bare «20 назад» is not
  // a duration anybody says, and reading it as 20 hours would be an invention.
  if (asNumber != null) {
    return RegExp(r'час').hasMatch(hours.group(0)!) ? asNumber * 60 : null;
  }
  return switch (word) {
    'час' => 60,
    'полтора' => 90,
    'два' || 'две' => 120,
    'три' => 180,
    'четыре' => 240,
    'пять' => 300,
    'шесть' => 360,
    _ => null,
  };
}

/// The stems of the twelve months, in order, as a parent pronounces them.
const _months = [
  'январ', 'феврал', 'март', 'апрел', 'мая', 'май', 'июн', 'июл',
  'август', 'сентябр', 'октябр', 'ноябр', 'декабр',
];

/// Which month a stem belongs to. «мая» and «май» are both the fifth.
int _monthOf(String stem) {
  final index = _months.indexOf(stem);
  return index <= 4 ? index + 1 : index;
}

/// The calendar day a sentence named, at midnight, or null.
DateTime? _spokenDay(String s, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  if (s.contains('позавчера')) {
    return today.subtract(const Duration(days: 2));
  }
  if (s.contains('послезавтра')) return today.add(const Duration(days: 2));
  if (s.contains('вчера')) return today.subtract(const Duration(days: 1));
  if (s.contains('завтра')) return today.add(const Duration(days: 1));
  if (s.contains('сегодня')) return today;

  // «8 августа», «восьмое августа» is beyond this — the digits are what a
  // recogniser produces for a date, and a written-out ordinal is rare enough
  // not to be worth a second table.
  final named = RegExp(
    '(\\d{1,2})\\s*(?:-?[а-я]{0,2})?\\s*(${_months.join('|')})',
  ).firstMatch(s);
  if (named != null) {
    final dayOfMonth = int.parse(named.group(1)!);
    final month = _monthOf(named.group(2)!);
    if (dayOfMonth >= 1 && dayOfMonth <= 31) {
      final candidate = DateTime(now.year, month, dayOfMonth);
      // A date that has not arrived yet is last year's: a diary records what
      // happened, and «31 декабря» said in January is six weeks ago.
      return candidate.isAfter(today)
          ? DateTime(now.year - 1, month, dayOfMonth)
          : candidate;
    }
  }

  // «08.08» and «08.08.2026», which is what a keyboard dictation produces.
  final numeric = RegExp(
    r'\b(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?\b',
  ).firstMatch(s);
  if (numeric != null) {
    final dayOfMonth = int.parse(numeric.group(1)!);
    final month = int.parse(numeric.group(2)!);
    if (dayOfMonth >= 1 && dayOfMonth <= 31 && month >= 1 && month <= 12) {
      final year = numeric.group(3) == null
          ? now.year
          : _fullYear(int.parse(numeric.group(3)!));
      final candidate = DateTime(year, month, dayOfMonth);
      return numeric.group(3) == null && candidate.isAfter(today)
          ? DateTime(year - 1, month, dayOfMonth)
          : candidate;
    }
  }

  return null;
}

int _fullYear(int spoken) => spoken >= 100 ? spoken : 2000 + spoken;

/// The clock time a sentence named, as (hour, minute), or null.
(int, int)? _spokenTime(String s) {
  // «в 14:30» — the unambiguous one, so it is tried first.
  final exact = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(s);
  if (exact != null) {
    final hour = int.parse(exact.group(1)!);
    final minute = int.parse(exact.group(2)!);
    if (hour < 24 && minute < 60) return (hour, minute);
  }

  if (RegExp(r'в\s+полдень|в\s+обед').hasMatch(s)) return (12, 0);
  if (s.contains('в полночь')) return (0, 0);

  // «в девять вечера», «в 9 утра», «в 2 дня», «в три ночи».
  final spoken = RegExp(
    r'в\s+(\d{1,2}|один|два|две|три|четыре|пять|шесть|семь|восемь|девять|'
    r'десять|одиннадцать|двенадцать)\s*(?:час[а-я]*)?\s*'
    r'(утра|дня|вечера|ночи)?',
  ).firstMatch(s);
  if (spoken == null) return null;

  final word = spoken.group(1)!;
  var hour = int.tryParse(word) ?? _spokenNumbers[word];
  if (hour == null || hour > 24) return null;

  // Half the day is decided by the word after the number, and without one a
  // recogniser's «в 9» is read as the clock face it printed.
  switch (spoken.group(2)) {
    case 'утра':
      if (hour == 12) hour = 0;
    case 'дня':
      if (hour < 12) hour += 12;
    case 'вечера':
      if (hour < 12) hour += 12;
    case 'ночи':
      if (hour == 12) hour = 0;
    case _:
      break;
  }
  return hour >= 24 ? null : (hour, 0);
}

const _spokenNumbers = <String, int>{
  'один': 1,
  'два': 2,
  'две': 2,
  'три': 3,
  'четыре': 4,
  'пять': 5,
  'шесть': 6,
  'семь': 7,
  'восемь': 8,
  'девять': 9,
  'десять': 10,
  'одиннадцать': 11,
  'двенадцать': 12,
};

/// Minutes out of "15 минут", "2 часа", "полтора часа" and their neighbours.
///
/// Hours win over minutes when both are present, and a bare number is not a
/// duration: "90" on its own is far more likely to be millilitres.
int? _minutes(String s) {
  final hours = RegExp(r'(\d{1,2})\s*(?:ч\b|час\w*|сағат|h\b|hour|hr)')
      .firstMatch(s);
  final mins = RegExp(r'(\d{1,3})\s*(?:мин\w*|минут\w*|мин|min|m\b)')
      .firstMatch(s);

  var total = 0;
  if (hours != null) total += (int.tryParse(hours.group(1)!) ?? 0) * 60;
  if (mins != null) total += int.tryParse(mins.group(1)!) ?? 0;
  return total > 0 ? total : null;
}
