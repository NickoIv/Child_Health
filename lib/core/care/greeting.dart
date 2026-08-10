import '../../l10n/app_localizations.dart';
import '../theme/theme_mode.dart';

/// Good morning — to her, by name.
///
/// The card this sits on is entirely about the child: the face, the name, the
/// age, the last feed, the last sleep. The greeting was the one line on it
/// addressed to the person actually holding the phone, and it was addressed
/// to nobody — «Доброе утро», to the room.
///
/// Her name is the cheapest and least repeatable warmth an interface has. It
/// cannot go stale the way a rotating phrase does, because it is not a phrase:
/// it is the app knowing who it is talking to. The app has had the name since
/// she filled in her profile and had never once used it.
///
/// Empty when she has not given one — the plain greeting, never a guess and
/// never «Здравствуйте, пользователь».
String greetingFor(AppLocalizations l, DateTime now, {String name = ''}) {
  final greeting = _byHour(l, now);
  final trimmed = name.trim();
  if (trimmed.isEmpty) return greeting;

  // The first word only. She types «Анна Иванова» into a profile field and
  // being greeted by both names every morning reads as a form letter.
  final first = trimmed.split(RegExp(r'\s+')).first;
  return l.greetingNamed(greeting, first);
}

String _byHour(AppLocalizations l, DateTime now) {
  if (isNightAt(now)) return l.greetingNight;
  if (now.hour < 12) return l.greetingMorning;
  if (now.hour < 18) return l.greetingAfternoon;
  return l.greetingEvening;
}
