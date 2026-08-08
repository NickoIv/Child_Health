import '../../core/l10n/labels.dart';
import '../../core/voice/voice_commands.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import 'widgets.dart';

/// One line saying what a dictated sentence will be written down as.
///
/// Kept out of any widget so a test can read it without building anything, and
/// phrased as the record rather than as a confirmation question. It outlived
/// the microphone card it was written for: the assistant shows the same line
/// now, and an entry spoken to it reads exactly as it used to on the home
/// screen.
///
/// A moment she named out loud is printed here too. It is the one thing on
/// this line she cannot check against the record afterwards without going to
/// look, and a misheard «вчера» would otherwise file a feed on the wrong day
/// in silence.
String voiceSummary(AppLocalizations l, VoiceCommand command) {
  final what = _voiceWhat(l, command);
  if (command.at case final moment?) {
    return '$what · ${dayMonth.format(moment)}, ${timeOfDay.format(moment)}';
  }
  return what;
}

String _voiceWhat(AppLocalizations l, VoiceCommand command) =>
    switch (command.intent) {
      VoiceIntent.temperature =>
        '${l.quickSheetTemperature}: '
            '${command.temperatureC!.toStringAsFixed(1)} °C',
      VoiceIntent.nappy =>
        '${l.quickSheetNappy}: '
            '${command.nappyKind!.localizedLabel(l).toLowerCase()}',
      VoiceIntent.sleep => [
        l.quickSheetSleep,
        if (command.minutes != null) localizedDuration(l, command.minutes!),
      ].join(': '),
      VoiceIntent.bottle => [
        '${l.quickSheetFeeding}: '
            '${FeedingSide.bottle.localizedLabel(l).toLowerCase()}',
        if (command.millilitres != null) '${command.millilitres} ${l.voiceMl}',
      ].join(', '),
      VoiceIntent.feeding => [
        l.quickSheetFeeding,
        if (command.side != null) command.side!.localizedLabel(l).toLowerCase(),
        if (command.minutes != null) localizedDuration(l, command.minutes!),
      ].join(', '),
      VoiceIntent.note => l.voiceAsNote,
    };