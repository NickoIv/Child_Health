import '../../models/development_log.dart';

/// Reading a table exported by another baby tracker.
///
/// «Дневник малыша» and the rest of them all export the same shape — one row
/// per event, with a date, a time, a kind and sometimes a length or a note —
/// but no two agree on the column names, the separator or the date format. So
/// nothing here is written against one app's file. It reads the header, works
/// out what each column is for, and says what it understood before anything
/// is written.
///
/// The one rule this obeys everywhere: a row it is not sure about is skipped
/// and reported, never guessed at. An import that quietly invents a feed is
/// worse than an import that leaves twenty rows behind — the parent can see
/// twenty rows, and cannot see a wrong one.

/// What a column turned out to hold.
enum ColumnRole { date, time, kind, duration, amount, note, ignored }

/// One row that could not be used, and why — shown before the import runs.
typedef SkippedRow = ({int line, String reason});

class ImportPreview {
  const ImportPreview({
    required this.entries,
    required this.skipped,
    required this.roles,
    required this.headers,
  });

  /// Ready to write, in the order they appeared.
  final List<DevelopmentLog> entries;
  final List<SkippedRow> skipped;

  /// What each column was taken to be — shown so a wrong guess is visible
  /// rather than merely wrong.
  final List<ColumnRole> roles;
  final List<String> headers;

  bool get isEmpty => entries.isEmpty;

  int countOf(LogType type) => entries.where((e) => e.type == type).length;

  /// The span the file covers, or null when nothing parsed.
  ({DateTime from, DateTime to})? get range {
    if (entries.isEmpty) return null;
    var from = entries.first.date;
    var to = entries.first.date;
    for (final entry in entries) {
      if (entry.date.isBefore(from)) from = entry.date;
      if (entry.date.isAfter(to)) to = entry.date;
    }
    return (from: from, to: to);
  }
}

/// Splits a delimited file into rows, tolerating what these exports actually
/// contain: a BOM, CRLF endings, quoted fields with the separator inside, and
/// doubled quotes for a literal one.
List<List<String>> parseDelimited(String text) {
  if (text.isEmpty) return const [];
  final body = text.startsWith('﻿') ? text.substring(1) : text;
  final separator = _separatorOf(body);

  final rows = <List<String>>[];
  var field = StringBuffer();
  var row = <String>[];
  var quoted = false;

  for (var i = 0; i < body.length; i++) {
    final char = body[i];

    if (quoted) {
      if (char == '"') {
        // A doubled quote inside a quoted field is one quote.
        if (i + 1 < body.length && body[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }

    if (char == '"') {
      quoted = true;
    } else if (char == separator) {
      row.add(field.toString().trim());
      field = StringBuffer();
    } else if (char == '\n') {
      row.add(field.toString().trim());
      field = StringBuffer();
      if (row.any((cell) => cell.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else if (char != '\r') {
      field.write(char);
    }
  }

  row.add(field.toString().trim());
  if (row.any((cell) => cell.isNotEmpty)) rows.add(row);
  return rows;
}

/// Whichever of the usual four appears most often outside quotes.
///
/// Guessed rather than configured: a parent exporting from another app has no
/// idea what a delimiter is, and a Russian locale Excel writes semicolons
/// while everything else writes commas.
String _separatorOf(String text) {
  const candidates = [';', ',', '\t', '|'];
  final counts = {for (final c in candidates) c: 0};
  var quoted = false;
  for (final char in text.split('')) {
    if (char == '"') quoted = !quoted;
    if (quoted) continue;
    if (counts.containsKey(char)) counts[char] = counts[char]! + 1;
  }
  var best = ',';
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}

/// Words that give a column away, in the three languages these files come in.
const _dateWords = ['дата', 'date', 'күн', 'день', 'when'];
const _timeWords = ['время', 'time', 'уақыт', 'начало', 'start'];
const _kindWords = ['тип', 'событие', 'вид', 'категория', 'type', 'event', 'kind', 'түр'];
const _durationWords = ['длит', 'продолж', 'duration', 'минут', 'ұзақ'];
const _amountWords = ['объ', 'кол-во', 'количество', 'amount', 'volume', 'мл', 'ml'];
const _noteWords = ['коммент', 'заметк', 'примеч', 'note', 'comment', 'ескерт', 'описание'];

ColumnRole _roleOf(String header) {
  final name = header.toLowerCase().trim();
  if (name.isEmpty) return ColumnRole.ignored;
  bool has(List<String> words) => words.any(name.contains);

  // Order matters: «дата и время» is a date column that also holds a time,
  // and the date parser reads both, so date wins.
  if (has(_dateWords)) return ColumnRole.date;
  if (has(_timeWords)) return ColumnRole.time;
  if (has(_kindWords)) return ColumnRole.kind;
  if (has(_durationWords)) return ColumnRole.duration;
  if (has(_amountWords)) return ColumnRole.amount;
  if (has(_noteWords)) return ColumnRole.note;
  return ColumnRole.ignored;
}

/// What each column is for.
///
/// The header is read first, and then the values are, because a file with no
/// header at all is common and «Когда;Что» names nothing this recognises.
/// Judging by content is what makes those files readable instead of empty.
List<ColumnRole> rolesFor(List<String> headers, List<List<String>> rows) {
  final roles = headers.map(_roleOf).toList();

  List<String> sampleOf(int column) => rows
      .take(8)
      .map((r) => column < r.length ? r[column] : '')
      .where((v) => v.isNotEmpty)
      .toList();

  // No named date column: take the first whose values all parse as dates.
  // All of them, not most — a date column with prose in it is not one.
  if (!roles.contains(ColumnRole.date)) {
    for (var i = 0; i < roles.length; i++) {
      final sample = sampleOf(i);
      if (sample.isNotEmpty && sample.every((v) => parseWhen(v) != null)) {
        roles[i] = ColumnRole.date;
        break;
      }
    }
  }

  // And no named kind column: take the first spare one where most values are
  // kinds this app knows. Most rather than all, because a column of kinds
  // contains «Прогулка» too; and a majority rather than any, because a note
  // column will mention sleep in a sentence sooner or later.
  if (!roles.contains(ColumnRole.kind)) {
    for (var i = 0; i < roles.length; i++) {
      if (roles[i] != ColumnRole.ignored) continue;
      final sample = sampleOf(i);
      if (sample.isEmpty) continue;
      final known = sample.where((v) => readKind(v) != null).length;
      if (known * 2 >= sample.length) {
        roles[i] = ColumnRole.kind;
        break;
      }
    }
  }

  // Still nothing that says what a row is about: keep the first spare column
  // as the note, so the words a parent wrote survive the trip even when the
  // app cannot classify them.
  if (!roles.contains(ColumnRole.kind) && !roles.contains(ColumnRole.note)) {
    for (var i = 0; i < roles.length; i++) {
      if (roles[i] == ColumnRole.ignored && sampleOf(i).isNotEmpty) {
        roles[i] = ColumnRole.note;
        break;
      }
    }
  }

  return roles;
}

/// A date, with a time in it if the cell carried one.
///
/// Accepts what these files actually hold: `12.08.2026`, `2026-08-12`,
/// `12/08/2026`, any of them followed by `14:30` or `14:30:00`. Two-digit
/// years are read as 20xx — these are exports from baby diaries, not from the
/// nineties.
DateTime? parseWhen(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final match = RegExp(
    r'^(\d{1,4})[.\-/](\d{1,2})[.\-/](\d{1,4})'
    r'(?:[ T]+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
  ).firstMatch(value);
  if (match == null) return null;

  final first = int.parse(match.group(1)!);
  final second = int.parse(match.group(2)!);
  final third = int.parse(match.group(3)!);

  int year;
  int month;
  int day;
  if (first > 31) {
    // 2026-08-12
    year = first;
    month = second;
    day = third;
  } else {
    // 12.08.2026 — day first, which is what every Russian export writes.
    day = first;
    month = second;
    year = third < 100 ? 2000 + third : third;
  }

  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  final hour = int.tryParse(match.group(4) ?? '') ?? 0;
  final minute = int.tryParse(match.group(5) ?? '') ?? 0;
  if (hour > 23 || minute > 59) return null;

  final result = DateTime(year, month, day, hour, minute);
  // Rejects 31 February, which DateTime would roll over into March.
  if (result.month != month || result.day != day) return null;
  return result;
}

/// `14:30`, `14:30:00`, or nothing.
({int hour, int minute})? parseClock(String raw) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return (hour: hour, minute: minute);
}

/// Minutes, from whichever way the file writes a length: `25`, `25 мин`,
/// `1 ч 20 мин`, `1:20`, `0:45:00`.
int? parseMinutes(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) return null;

  final clock = RegExp(r'^(\d{1,3}):(\d{2})(?::(\d{2}))?$').firstMatch(value);
  if (clock != null) {
    return int.parse(clock.group(1)!) * 60 + int.parse(clock.group(2)!);
  }

  var minutes = 0;
  var matched = false;
  final hours = RegExp(r'(\d+)\s*(?:ч|h|сағ)').firstMatch(value);
  if (hours != null) {
    minutes += int.parse(hours.group(1)!) * 60;
    matched = true;
  }
  final mins = RegExp(r'(\d+)\s*(?:мин|м\b|min|m\b)').firstMatch(value);
  if (mins != null) {
    minutes += int.parse(mins.group(1)!);
    matched = true;
  }
  if (matched) return minutes;

  final bare = int.tryParse(value);
  return bare != null && bare >= 0 ? bare : null;
}

int? parseAmount(String raw) {
  final match = RegExp(r'(\d+)').firstMatch(raw.replaceAll(',', '.'));
  return match == null ? null : int.parse(match.group(1)!);
}

double? parseDecimal(String raw) {
  final match = RegExp(r'(\d+[.,]?\d*)').firstMatch(raw);
  return match == null ? null : double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

/// What kind of event a row describes.
///
/// Matched on words rather than on codes: every one of these files writes the
/// kind in the parent's own language, and there is no shared vocabulary to
/// map. Anything unrecognised becomes a note, which keeps the row and its
/// words rather than throwing them away.
({LogType type, FeedingSide? side, NappyKind? nappy})? readKind(String raw) {
  final value = raw.toLowerCase();
  if (value.trim().isEmpty) return null;

  bool has(List<String> words) => words.any(value.contains);

  if (has(['подгуз', 'nappy', 'diaper', 'жаялық', 'пелен'])) {
    final wet = has(['мокр', 'пис', 'моч', 'wet', 'pee']);
    final dirty = has(['стул', 'как', 'кал', 'dirty', 'poo', 'нәжіс']);
    return (
      type: LogType.nappy,
      side: null,
      nappy: wet && dirty
          ? NappyKind.both
          : dirty
              ? NappyKind.dirty
              : NappyKind.wet,
    );
  }

  if (has(['сон', 'спал', 'сна', 'sleep', 'nap', 'ұйқы'])) {
    return (type: LogType.sleep, side: null, nappy: null);
  }

  if (has(['температ', 'temperature', 'дене қызу'])) {
    return (type: LogType.illness, side: null, nappy: null);
  }

  if (has(['вес', 'рост', 'weight', 'height', 'салмақ', 'бой'])) {
    return (type: LogType.measurement, side: null, nappy: null);
  }

  if (has(['корм', 'еда', 'груд', 'смес', 'бутыл', 'feed', 'milk', 'тамақ'])) {
    final side = has(['лев', 'left', 'сол'])
        ? FeedingSide.left
        : has(['прав', 'right', 'оң'])
            ? FeedingSide.right
            : has(['бутыл', 'смес', 'bottle', 'formula'])
                ? FeedingSide.bottle
                : has(['прикорм', 'solid', 'пюре', 'каша'])
                    ? FeedingSide.solid
                    : null;
    return (type: LogType.feeding, side: side, nappy: null);
  }

  return null;
}

/// Reads the whole file and says what it would create.
///
/// Nothing is written here. The screen shows the counts, the range and the
/// rows that were skipped, and only then offers a button.
ImportPreview previewImport(String text, {required String childId}) {
  final rows = parseDelimited(text);
  if (rows.isEmpty) {
    return const ImportPreview(
      entries: [],
      skipped: [],
      roles: [],
      headers: [],
    );
  }

  // A header is a first row where no cell parses as a date. Files without one
  // exist, and reading their first event as a header would drop it silently.
  final first = rows.first;
  final looksLikeHeader = !first.any((cell) => parseWhen(cell) != null);
  final headers = looksLikeHeader
      ? first
      : List.generate(first.length, (i) => '');
  final body = looksLikeHeader ? rows.skip(1).toList() : rows;

  final roles = rolesFor(headers, body);
  final entries = <DevelopmentLog>[];
  final skipped = <SkippedRow>[];

  String cell(List<String> row, ColumnRole role) {
    final index = roles.indexOf(role);
    if (index < 0 || index >= row.length) return '';
    return row[index];
  }

  for (var i = 0; i < body.length; i++) {
    final row = body[i];
    // +1 for the header, +1 because people count lines from one.
    final line = looksLikeHeader ? i + 2 : i + 1;

    final when = parseWhen(cell(row, ColumnRole.date));
    if (when == null) {
      skipped.add((line: line, reason: 'date'));
      continue;
    }

    final clock = parseClock(cell(row, ColumnRole.time));
    final at = clock == null
        ? when
        : DateTime(when.year, when.month, when.day, clock.hour, clock.minute);

    final kindText = cell(row, ColumnRole.kind);
    final note = cell(row, ColumnRole.note);
    final kind = readKind(kindText) ?? readKind(note);
    final minutes = parseMinutes(cell(row, ColumnRole.duration));

    if (kind == null) {
      // Not a kind this app has, but it is still a dated thing the parent
      // wrote. Kept as a note rather than dropped.
      final text = [kindText, note].where((s) => s.isNotEmpty).join(' — ');
      if (text.isEmpty) {
        skipped.add((line: line, reason: 'empty'));
        continue;
      }
      entries.add(DevelopmentLog(
        id: '',
        childId: childId,
        date: at,
        type: LogType.note,
        title: text.length > 60 ? text.substring(0, 60) : text,
        description: text,
      ));
      continue;
    }

    final metrics = kind.type == LogType.illness
        ? Metrics(temperatureC: parseDecimal(note.isEmpty ? kindText : note))
        : kind.type == LogType.measurement
            ? _measurementFrom(kindText, note)
            : const Metrics();

    entries.add(DevelopmentLog(
      id: '',
      childId: childId,
      date: at,
      type: kind.type,
      // The model's own wording, because it is what sits in Firestore and
      // what the rest of the app matches on.
      title: kind.type.label,
      description: note,
      feedingSide: kind.side,
      nappyKind: kind.nappy,
      durationMinutes:
          kind.type == LogType.sleep || kind.type == LogType.feeding
              ? minutes
              : null,
      metrics: metrics,
      milkMl: parseAmount(cell(row, ColumnRole.amount)),
    ));
  }

  return ImportPreview(
    entries: entries,
    skipped: skipped,
    roles: roles,
    headers: headers,
  );
}

/// A weight or a height, whichever the row is about.
Metrics _measurementFrom(String kindText, String note) {
  final value = parseDecimal(note.isEmpty ? kindText : note);
  if (value == null) return const Metrics();
  final text = '$kindText $note'.toLowerCase();
  final isHeight = text.contains('рост') ||
      text.contains('height') ||
      text.contains('бой') ||
      value > 30;
  return isHeight ? Metrics(heightCm: value) : Metrics(weightKg: value);
}
