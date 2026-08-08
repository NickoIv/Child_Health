import 'dart:convert';

import 'package:child_health_tracker/ai/assistant_service.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/voice/voice_commands.dart';
import 'package:child_health_tracker/features/assistant/chat_record.dart';
import 'package:child_health_tracker/features/assistant/chat_screen.dart';
import 'package:child_health_tracker/features/shared/voice_summary.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «На странице Обзор убери микрофон и отдай эти функции ИИ.»
///
/// One field now does what two did: the assistant writes down a sentence that
/// is a record and answers one that is a question. This is the line between
/// them, and it is the only thing standing between a question and a wrong
/// number in a medical record — so it is drawn on the device, before anything
/// is sent anywhere, and everything it is unsure about is a question.
void main() {
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 8, 15, 30);

  VoiceCommand? read(String message) => recordIn(message, now: now);

  group('what gets written down', () {
    test('a feed, with the side and the minutes', () {
      final c = read('покормила левой 15 минут')!;
      expect(c.intent, VoiceIntent.feeding);
      expect(c.side, FeedingSide.left);
      expect(c.minutes, 15);
    });

    test('a sleep, a nappy, a bottle and a temperature', () {
      expect(read('спал 2 часа')?.intent, VoiceIntent.sleep);
      expect(read('подгузник мокрый')?.intent, VoiceIntent.nappy);
      expect(read('бутылочка 90 мл')?.intent, VoiceIntent.bottle);
      expect(read('температура 37.8')?.temperatureC, 37.8);
    });

    test('and the moment she named out loud comes with it', () {
      // The whole reason for saying the time: «покормила вчера в девять
      // вечера» is a record of yesterday evening, not of the second the
      // message was sent.
      final c = read('покормила вчера в девять вечера')!;
      expect(c.at, DateTime(2026, 8, 7, 21));
    });
  });

  group('what goes to the assistant instead', () {
    test('anything with a question mark', () {
      expect(read('покормила левой 15 минут?'), isNull);
    });

    test('a question that happens to contain a feed', () {
      // The trap this exists for: «сколько раз кормить» carries the same stem
      // the parser reads a feeding from, and answering it is right while
      // filing it is a fabricated entry in a diary.
      expect(read('сколько раз кормить в три месяца'), isNull);
      expect(read('когда он должен спать всю ночь'), isNull);
      expect(read('можно ли сбивать температуру 37.5'), isNull);
    });

    test('and a request meant for the assistant to answer', () {
      expect(read('напиши поздравление бабушке на юбилей'), isNull);
      expect(read('составь список покупок на неделю'), isNull);
      expect(read('расскажи сказку про козу'), isNull);
    });

    test('a sentence it cannot place is a question, not a guess', () {
      // It used to become a note, because a microphone had nothing else to do
      // with it. There is something on the other side of this field now that
      // can answer «он третий день плохо ест», and «запиши…» is how to say
      // the words were meant for the diary.
      expect(read('он третий день капризничает'), isNull);
    });
  });

  group('asked to write, in so many words', () {
    test('«запиши, что…» is a note in her own words', () {
      final c = read('Запиши, что сегодня улыбнулся бабушке')!;
      expect(c.intent, VoiceIntent.note);
      expect(c.text, 'сегодня улыбнулся бабушке');
    });

    test('it outranks the question words inside it', () {
      // «что» is how a question starts and also how this sentence carries on.
      // An explicit instruction to write something down wins.
      expect(read('отметь что зуб прорезался'), isNotNull);
      expect(read('запись: первый раз сел сам'), isNotNull);
    });

    test('and a shape it recognises is still read as that shape', () {
      final c = read('запиши температуру 38.2')!;
      expect(c.intent, VoiceIntent.temperature);
      expect(c.temperatureC, 38.2);
    });

    test('but «запиши» in the middle of a question is not an instruction', () {
      expect(read('как запиши температуру правильно'), isNull);
    });

    test('«запиши» with nothing after it writes nothing', () {
      expect(read('запиши'), isNull);
    });
  });

  test('a nappy is not mistaken for a question', () {
    // «кака» and «как» differ by one letter, and a substring search cannot
    // tell them apart — which would send a nappy to the model and leave a
    // parent wondering why nothing was written down.
    expect(read('подгузник кака')?.nappyKind, NappyKind.dirty);
  });

  test('nothing at all is nothing', () {
    expect(read(''), isNull);
    expect(read('   '), isNull);
  });

  group('in the conversation', () {
    final child = Child(
      id: 'demo',
      parentUid: 'u',
      name: 'Айгерим',
      birthDate: DateTime(2026, 2, 7),
      gender: Gender.female,
    );

    /// Counts every request that reaches the model, and answers plainly.
    ///
    /// A record must not cost a round trip: it is written on the device, at
    /// four in the morning, on a phone that may have no network at all.
    late int calls;

    setUp(() => calls = 0);

    http.Client counting() => MockClient((_) async {
      calls++;
      return http.Response.bytes(
        utf8.encode(jsonEncode({'text': 'Отвечаю.'})),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    Future<ProviderContainer> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith(
              (ref) => Stream.value(const <DevelopmentLog>[]),
            ),
            assistantServiceProvider.overrideWith(
              (ref) => GeminiAssistantService(
                client: counting(),
                endpoint: 'https://example.invalid/ai',
              ),
            ),
          ],
          child: MaterialApp(
            locale: defaultLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ChatScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(ChatScreen)));
    }

    Future<void> say(WidgetTester tester, String words) async {
      await tester.enterText(find.byType(TextField), words);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
    }

    Future<List<DevelopmentLog>> logsIn(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      // runAsync because the repository's stream delivers on a real
      // microtask, which the widget tester's fake clock never reaches.
      final logs = await tester.runAsync(
        () => container.read(logRepositoryProvider).watchLogs(child.id).first,
      );
      return logs!;
    }

    testWidgets('a dictated feed is written, and the model is not called', (
      tester,
    ) async {
      final container = await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await say(tester, 'покормила левой 15 минут');

      final logs = await logsIn(tester, container);
      expect(logs, hasLength(1));
      expect(logs.single.type, LogType.feeding);
      expect(logs.single.feedingSide, FeedingSide.left);
      expect(logs.single.durationMinutes, 15);
      // Her own words are kept on the entry, whatever the reading was.
      expect(logs.single.description, 'покормила левой 15 минут');

      expect(calls, 0, reason: 'a record costs no round trip');

      // And she is told what was written, in the same words the diary will
      // use for it.
      final command = parseVoiceCommand('покормила левой 15 минут');
      expect(
        find.text(l.quickSaved(voiceSummary(l, command))),
        findsOneWidget,
      );
    });

    testWidgets('the undo stays in the thread and takes it back', (
      tester,
    ) async {
      final container = await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await say(tester, 'подгузник мокрый');
      expect(await logsIn(tester, container), hasLength(1));

      await tester.tap(find.widgetWithText(TextButton, l.commonUndo));
      await tester.pumpAndSettle();

      expect(await logsIn(tester, container), isEmpty);
      // The line stays, saying what happened to it. A snackbar would have
      // been gone four seconds after she looked away.
      expect(find.text(l.chatRecordUndone), findsOneWidget);
      expect(find.widgetWithText(TextButton, l.commonUndo), findsNothing);
    });

    testWidgets('a question is answered rather than filed', (tester) async {
      final container = await pump(tester);

      await say(tester, 'сколько раз кормить в три месяца?');

      expect(await logsIn(tester, container), isEmpty);
      expect(calls, 1);
      expect(find.text('Отвечаю.'), findsOneWidget);
    });

    testWidgets('the field says it writes as well as answers', (tester) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // The one thing about this field nobody would guess, and the microphone
      // that used to say it is gone from the home screen.
      expect(find.text(l.chatOrRecord), findsOneWidget);
    });
  });
}
