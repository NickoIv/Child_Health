import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_info.dart';

/// Errors, written down on her own phone and going nowhere until she sends
/// them.
///
/// The alternative was Crashlytics or Sentry, and for this app it is the wrong
/// trade. A crash reporter uploads a stack trace off the device the moment it
/// happens, and this is a record of a child's health — the one kind of data
/// that should not travel because a widget threw. Here nothing leaves at all:
/// the log sits in local storage, the settings screen shows it in full, and
/// copying it is a deliberate act with the text already on screen.
///
/// Which also makes it honest. She can read every character before she sends
/// it, which is not true of any reporter that posts in the background.
class LoggedError {
  const LoggedError({
    required this.at,
    required this.message,
    required this.where,
    this.doing = '',
  });

  final DateTime at;
  final String message;

  /// The first line of the stack that belongs to this app, or the library
  /// that threw. Enough to find the place; not the whole trace, which on the
  /// web is minified into uselessness anyway.
  final String where;

  /// What the framework was doing, in its own words — «building NowCard»,
  /// «during layout».
  ///
  /// The one part of a web crash report that survives minification, and it
  /// was being thrown away. A log that says only `Null check operator used on
  /// a null value` and `main.dart.js:56208:147` cannot be acted on at all:
  /// the line number belongs to a build that no longer exists by the time
  /// anyone reads it, and the message is the most common exception in Dart.
  /// The widget's name is not renamed by dart2js.
  final String doing;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'message': message,
    'where': where,
    'doing': doing,
  };

  static LoggedError? fromJson(Map<String, Object?> map) {
    final at = DateTime.tryParse(map['at'] as String? ?? '');
    if (at == null) return null;
    return LoggedError(
      at: at,
      message: map['message'] as String? ?? '',
      where: map['where'] as String? ?? '',
      doing: map['doing'] as String? ?? '',
    );
  }
}

/// How many are kept. The last twenty are the ones that explain a phone that
/// is misbehaving now; a hundred is a file nobody reads and a preference key
/// that grows without end.
const errorLogLimit = 20;

/// And how long one entry may be. A Flutter assertion can run to several
/// hundred lines of widget tree, which is neither readable in a chat nor
/// useful past its first sentences.
const errorLogMessageMax = 400;

const _key = 'error_log';

/// Anything in an error message that could be a person.
///
/// Messages are framework text almost every time — but «almost» is not a
/// guarantee, and a message that quotes a field she typed could carry an
/// address or a number into a copy-paste. These two go out before it is
/// stored, so there is nothing to leak later.
String scrubbed(String text) => text
    .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'), '<адрес>')
    .replaceAll(RegExp(r'\+?\d[\d\s()-]{8,}\d'), '<номер>');

class ErrorLog extends Notifier<List<LoggedError>> {
  @override
  List<LoggedError> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    // Anything recorded in this run is newer than the disk: a slow read must
    // not swallow the error that was just caught.
    if (state.isNotEmpty) return;

    final raw = prefs?.getString(_key);
    if (raw == null || raw.isEmpty) return;
    state = _decode(raw);
  }

  /// Writes one down. Never throws and never awaits at the call site: this
  /// runs inside an error handler, and an error handler that can fail is a
  /// crash on top of a crash.
  void record(Object error, StackTrace? stack, {String doing = ''}) {
    final entry = LoggedError(
      at: DateTime.now(),
      message: _trim(scrubbed(error.toString())),
      where: _firstFrame(stack),
      doing: _trim(scrubbed(doing)),
    );

    state = [entry, ...state].take(errorLogLimit).toList();
    _save();
  }

  Future<void> clear() async {
    state = const [];
    final prefs = await _prefs();
    await prefs?.remove(_key);
  }

  /// The log as the text she pastes into a message.
  ///
  /// The build is the first line because it is the first thing to ask about
  /// and the thing she is least likely to know.
  String asText() {
    if (state.isEmpty) return '';
    final buffer = StringBuffer()
      ..writeln('Дневник ребёнка ${AppInfo.version}')
      ..writeln('Ошибок: ${state.length}')
      ..writeln();

    for (final e in state) {
      buffer
        ..writeln('— ${e.at.toIso8601String()}')
        ..writeln(e.message);
      // Before the stack line, because it is the one of the two that is
      // still readable a week and three builds later.
      if (e.doing.isNotEmpty) buffer.writeln(e.doing);
      if (e.where.isNotEmpty) buffer.writeln(e.where);
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  Future<void> _save() async {
    final prefs = await _prefs();
    await prefs?.setString(
      _key,
      jsonEncode([for (final e in state) e.toJson()]),
    );
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No storage here. The log still works for this run, which is the run
      // she is complaining about.
      return null;
    }
  }
}

List<LoggedError> _decode(String raw) {
  try {
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        ?LoggedError.fromJson(item as Map<String, Object?>),
    ].take(errorLogLimit).toList();
  } catch (_) {
    // A key written by an older build, or half-written. Not worth a crash in
    // the thing that exists to survive crashes.
    return const [];
  }
}

String _trim(String text) {
  final flat = text.trim();
  return flat.length <= errorLogMessageMax
      ? flat
      : '${flat.substring(0, errorLogMessageMax)}…';
}

/// The first frame worth naming.
///
/// Prefers a line mentioning this package, because that is where the bug is;
/// falls back to the top frame, which at least names the framework that
/// complained.
String _firstFrame(StackTrace? stack) {
  if (stack == null) return '';
  final lines = stack
      .toString()
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return '';

  for (final line in lines) {
    if (line.contains('child_health_tracker')) return _trim(scrubbed(line));
  }
  return _trim(scrubbed(lines.first));
}

final errorLogProvider = NotifierProvider<ErrorLog, List<LoggedError>>(
  ErrorLog.new,
);

/// Points Flutter's two error channels at [log].
///
/// Both, because they catch different things: [FlutterError.onError] is a
/// widget or a build failing, and [PlatformDispatcher.onError] is everything
/// that escaped an async gap. Neither is swallowed — the framework still
/// prints what it always printed, so nothing about debugging gets worse.
void installErrorLogging(ErrorLog log) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    // `context` is the framework's own sentence about what it was doing —
    // «building NowCard», «during layout» — and `library` names which part of
    // it complained. Both are plain strings that dart2js does not rename,
    // which makes them the only durable part of a crash report on the web.
    final doing = [
      details.context?.toDescription() ?? '',
      details.library ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');
    log.record(details.exception, details.stack, doing: doing);
    previous?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log.record(error, stack);
    // False: not handled here. This only writes it down.
    return false;
  };
}
