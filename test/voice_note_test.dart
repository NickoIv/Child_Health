import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/voice/dictation.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A microphone that types for you, and does nothing else.
///
/// What is tested here is mostly what the button refuses to do: save on its
/// own, overwrite what was already typed, keep listening for ever, or leave
/// the parent stuck when the microphone is refused.
void main() {
  setUpAll(initializeDateFormatting);

  Future<void> openNoteStep(
    WidgetTester tester, {
    required Dictation dictation,
    Locale? locale,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictationProvider.overrideWithValue(dictation),
          if (locale != null)
            localeProvider.overrideWith(() => LocaleChoice(locale)),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(locale ?? defaultLocale);

    // The note field lives on the "choose a time" branch of the quick sheet,
    // which is the only place in the app that has one.
    await tester.tap(find.widgetWithText(InkWell, l.quickFeed));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.quickTimeChoose));
    await tester.pumpAndSettle();
  }

  testWidgets('the microphone sits beside the note field', (tester) async {
    final fake = _FakeDictation();
    await openNoteStep(tester, dictation: fake);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    expect(find.text(l.quickNoteOptional), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    // Nothing is announced until it is asked for.
    expect(find.text(l.voiceListening), findsNothing);
  });

  testWidgets('a tap asks permission, says it is listening, and pulses', (
    tester,
  ) async {
    final fake = _FakeDictation();
    await openNoteStep(tester, dictation: fake);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump();

    expect(fake.prepared, 1, reason: 'permission is asked at the tap');
    expect(fake.listening, isTrue);
    expect(find.text(l.voiceListening), findsOneWidget);
    expect(find.text(l.voiceSpeakNow), findsOneWidget);

    // The mic turned into a stop control, and the halo is animating: pumping
    // a fixed span rather than settling, because a pulse never settles.
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 450));

    // Wound down by hand so the test does not end mid-animation.
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pumpAndSettle();
  });

  testWidgets('what was said lands in the field and nothing is saved', (
    tester,
  ) async {
    final fake = _FakeDictation();
    await openNoteStep(tester, dictation: fake);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump();

    fake.say('Съел половину бутылочки');
    await tester.pumpAndSettle();

    // In the field, and only in the field: the sheet is still open, the save
    // buttons are still untouched, and no entry exists yet.
    expect(find.text('Съел половину бутылочки'), findsOneWidget);
    expect(find.text(l.quickNoteOptional), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TextField).first),
    );
    final logs = container.read(logsProvider).value ?? const <DevelopmentLog>[];
    expect(
      logs.where((log) => log.description.contains('бутылочки')),
      isEmpty,
      reason: 'dictating is not saving',
    );
  });

  testWidgets('dictation adds to what was typed rather than replacing it', (
    tester,
  ) async {
    final fake = _FakeDictation();
    await openNoteStep(tester, dictation: fake);

    await tester.enterText(find.byType(TextField).first, 'Ночью');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump();
    fake.say('плакал');
    await tester.pumpAndSettle();

    expect(find.text('Ночью плакал'), findsOneWidget);
  });

  testWidgets('tapping again stops the recording', (tester) async {
    final fake = _FakeDictation();
    await openNoteStep(tester, dictation: fake);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump();
    expect(fake.listening, isTrue);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pumpAndSettle();

    expect(fake.listening, isFalse);
    expect(fake.stopped, 1);
    // Stopping on purpose is not a failure, so nothing is complained about.
    expect(find.text(l.voiceListening), findsNothing);
    expect(find.text(l.voiceFailed), findsNothing);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });

  testWidgets('it gives up on its own after thirty seconds', (tester) async {
    final fake = _FakeDictation();
    await openNoteStep(tester, dictation: fake);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump();

    // A phone left face-down on a bed does not listen for ever.
    await tester.pump(DictationSession.maxDuration);
    await tester.pumpAndSettle();

    expect(fake.stopped, greaterThanOrEqualTo(1));
    expect(find.text(l.voiceListening), findsNothing);
  });

  testWidgets('silence says so and leaves the field alone', (tester) async {
    final fake = _FakeDictation();
    await openNoteStep(tester, dictation: fake);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump();

    fake.hearNothing();
    await tester.pumpAndSettle();

    expect(find.text(l.voiceFailed), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });

  testWidgets('a refused microphone leaves the keyboard working', (
    tester,
  ) async {
    final fake = _FakeDictation(allowed: false);
    await openNoteStep(tester, dictation: fake);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();

    // Soft, once, and no dead end: the field is still there and still takes
    // typing.
    expect(find.text(l.voiceUnavailable), findsOneWidget);
    expect(fake.listening, isFalse);

    await tester.enterText(find.byType(TextField).first, 'Написала руками');
    await tester.pumpAndSettle();
    expect(find.text('Написала руками'), findsOneWidget);
  });

  group('the wiring', () {
    test('a build without a microphone declines rather than crashes', () async {
      const nothing = UnavailableDictation();
      expect(await nothing.prepare(), isFalse);
      // And every other call is a no-op, so a caller that ignores prepare()
      // still cannot get itself into a bad state.
      await nothing.start(
        localeId: 'ru_RU',
        onResult: (_) => fail('nothing to hear'),
        onSilence: () => fail('nothing to hear'),
      );
      await nothing.stop();
    });

    test('the session is the half minute it promised', () {
      expect(DictationSession.maxDuration, const Duration(seconds: 30));
      expect(DictationSession.pause.inSeconds, lessThan(30));
    });

    test('each interface language asks for its own recogniser', () {
      expect(dictationLocale('ru'), 'ru_RU');
      expect(dictationLocale('kk'), 'kk_KZ');
      expect(dictationLocale('en'), 'en_US');
      // Anything unexpected falls back rather than passing a bad tag down.
      expect(dictationLocale('zz'), 'en_US');
    });

    test('every voice string exists in all three languages', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        for (final s in [
          l.voiceListening,
          l.voiceSpeakNow,
          l.voiceFailed,
          l.voiceUnavailable,
          l.voiceDictate,
          l.voiceStop,
        ]) {
          expect(s.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('the wording asked for is the wording shipped', () async {
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(ru.voiceListening, 'Слушаю…');
      expect(ru.voiceSpeakNow, 'Говорите');
      expect(ru.voiceFailed, 'Не удалось распознать речь');

      final kk = await AppLocalizations.delegate.load(const Locale('kk'));
      expect(kk.voiceListening, 'Тыңдап тұрмын…');
      expect(kk.voiceSpeakNow, 'Сөйлей беріңіз');
      expect(kk.voiceFailed, 'Сөйлеуді тану мүмкін болмады');

      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.voiceListening, 'Listening…');
      expect(en.voiceSpeakNow, 'Speak now');
      expect(en.voiceFailed, 'Could not recognize speech');
    });
  });
}

/// A recogniser with a script instead of a microphone.
class _FakeDictation implements Dictation {
  _FakeDictation({this.allowed = true});

  final bool allowed;

  int prepared = 0;
  int stopped = 0;
  bool listening = false;
  String? localeAskedFor;

  ValueChanged<String>? _onResult;
  VoidCallback? _onSilence;
  ValueChanged<double>? _onLevel;

  /// Lets a test drive the waveform without a room to make noise in.
  void speakAt(double level) => _onLevel?.call(level);

  @override
  Future<bool> prepare() async {
    prepared++;
    return allowed;
  }

  @override
  Future<void> start({
    required String localeId,
    required ValueChanged<String> onResult,
    required VoidCallback onSilence,
    ValueChanged<double>? onLevel,
  }) async {
    listening = true;
    _onLevel = onLevel;
    localeAskedFor = localeId;
    _onResult = onResult;
    _onSilence = onSilence;
  }

  @override
  Future<void> stop() async {
    if (listening) stopped++;
    listening = false;
  }

  /// The recogniser comes back with words.
  void say(String words) {
    listening = false;
    _onResult?.call(words);
  }

  /// The recogniser comes back with nothing.
  void hearNothing() {
    listening = false;
    _onSilence?.call();
  }
}
