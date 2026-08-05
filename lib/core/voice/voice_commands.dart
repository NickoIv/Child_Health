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

  /// Nothing matched, so it becomes a note in her own words.
  bool get isNote => intent == VoiceIntent.note;
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
VoiceCommand parseVoiceCommand(String heard) {
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
  required DateTime at,
}) {
  final note = command.text;

  return switch (command.intent) {
    VoiceIntent.feeding || VoiceIntent.bottle => DevelopmentLog(
      id: '',
      childId: childId,
      date: at,
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
      date: at,
      type: LogType.sleep,
      title: LogType.sleep.label,
      description: note,
      durationMinutes: command.minutes,
    ),
    VoiceIntent.nappy => DevelopmentLog(
      id: '',
      childId: childId,
      date: at,
      type: LogType.nappy,
      title: LogType.nappy.label,
      description: note,
      nappyKind: command.nappyKind,
    ),
    VoiceIntent.temperature => DevelopmentLog(
      id: '',
      childId: childId,
      date: at,
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
      date: at,
      type: LogType.note,
      title: LogType.note.label,
      description: note,
    ),
  };
}

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
