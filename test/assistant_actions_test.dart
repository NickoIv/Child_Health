import 'dart:convert';

import 'package:child_health_tracker/ai/actions.dart';
import 'package:child_health_tracker/ai/assistant_service.dart';
import 'package:child_health_tracker/ai/prompt.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/assistant/chat_screen.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/family_member.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` — the type of a ProviderScope override — lives here rather than
// in the main entry point since Riverpod 3.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Step B: the assistant may ask the app to do something, and nothing happens
/// until the parent has read what that is and tapped once.
///
/// The protocol is deliberately paranoid — the model proposes, this layer
/// decides whether the proposal is even representable — so most of what is
/// below is about proposals that must be thrown away.
void main() {
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 7, 14, 30);

  String reply(String tool, Map<String, Object?> args) =>
      'Хорошо, записываю.\n$actionMarker'
      '${jsonEncode({'tool': tool, 'args': args})}';

  group('parsing', () {
    test('an ordinary answer has no action and keeps its text', () {
      final parsed = parseAssistantReply('Кормите по требованию.');
      expect(parsed.action, isNull);
      expect(parsed.text, 'Кормите по требованию.');
    });

    test('the marker never survives into what the parent reads', () {
      final parsed = parseAssistantReply(
        reply('log_sleep', {'minutes': 90}),
        now: now,
      );
      expect(parsed.text, 'Хорошо, записываю.');
      expect(parsed.text, isNot(contains(actionMarker)));
      expect(parsed.text, isNot(contains('log_sleep')));
    });

    test('nor when the JSON is broken', () {
      final parsed = parseAssistantReply(
        'Готово.\n$actionMarker{"tool":"log_sleep","args":{minutes',
        now: now,
      );
      expect(parsed.action, isNull);
      expect(parsed.text, 'Готово.');
    });

    test('nor when the tool does not exist', () {
      final parsed = parseAssistantReply(
        reply('delete_everything', {'confirm': true}),
        now: now,
      );
      expect(parsed.action, isNull);
      expect(parsed.text, 'Хорошо, записываю.');
    });

    test('a feed keeps the minutes and the side', () {
      final action =
          parseAssistantReply(
                reply('log_feeding', {'minutes': 15, 'side': 'left'}),
                now: now,
              ).action
              as LogFeedingAction;
      expect(action.minutes, 15);
      expect(action.side, FeedingSide.left);
    });

    test('a nonsense duration is dropped, the answer is not', () {
      final parsed = parseAssistantReply(
        reply('log_sleep', {'minutes': 100000}),
        now: now,
      );
      expect(parsed.action, isNull);
      expect(parsed.text, isNotEmpty);
    });

    test('an impossible temperature never becomes an entry', () {
      // The one number in this app that must not be waved through.
      for (final value in [0, 12, 33.9, 43.1, 380, -5]) {
        expect(
          parseAssistantReply(
            reply('log_temperature', {'celsius': value}),
            now: now,
          ).action,
          isNull,
          reason: '$value °C must not be proposable',
        );
      }

      final ok =
          parseAssistantReply(
                reply('log_temperature', {'celsius': 38.4}),
                now: now,
              ).action
              as LogTemperatureAction;
      expect(ok.celsius, 38.4);
    });

    test('a reminder is placed relative to today', () {
      final action =
          parseAssistantReply(
                reply('create_reminder', {
                  'title': 'Дать сироп',
                  'type': 'medication',
                  'in_days': 1,
                  'time': '08:30',
                }),
                now: now,
              ).action
              as CreateReminderAction;

      expect(action.at, DateTime(2026, 8, 8, 8, 30));
      expect(action.type, ReminderType.medication);
    });

    test('a reminder a decade out is a misread date, not a plan', () {
      expect(
        parseAssistantReply(
          reply('create_reminder', {'title': 'x', 'in_days': 5000}),
          now: now,
        ).action,
        isNull,
      );
    });

    test('a reminder can never be a vaccination', () {
      // The immunisation plan comes from the national calendar. An invented
      // dose sitting among real ones is a lie a parent cannot spot.
      final action =
          parseAssistantReply(
                reply('create_reminder', {
                  'title': 'БЦЖ',
                  'type': 'vaccination',
                  'in_days': 3,
                }),
                now: now,
              ).action
              as CreateReminderAction;
      expect(action.type, isNot(ReminderType.vaccination));
    });

    test('only whitelisted screens can be opened', () {
      expect(
        parseAssistantReply(
          reply('open_screen', {'path': '/settings'}),
          now: now,
        ).action,
        isNull,
        reason: 'the account is not the child',
      );
      expect(
        parseAssistantReply(
          reply('open_screen', {'path': '/../../etc'}),
          now: now,
        ).action,
        isNull,
      );

      final action =
          parseAssistantReply(
                reply('open_screen', {'path': '/growth'}),
                now: now,
              ).action
              as OpenScreenAction;
      expect(action.path, '/growth');
    });

    test('an article must actually exist', () {
      expect(
        parseAssistantReply(
          reply('open_article', {'id': 'no-such-article'}),
          now: now,
        ).action,
        isNull,
      );
      expect(
        parseAssistantReply(
          reply('open_article', {'id': 'fever'}),
          now: now,
        ).action,
        isA<OpenArticleAction>(),
      );
    });

    test('there is no shape at all for the forbidden things', () {
      for (final tool in const [
        'delete_log',
        'delete_child',
        'edit_medical_record',
        'add_medical_record',
        'invite_family',
        'update_settings',
        'sign_out',
      ]) {
        expect(
          parseAssistantReply(reply(tool, const {}), now: now).action,
          isNull,
          reason: '$tool must not be representable',
        );
      }
    });
  });

  group('the entry a confirmed action becomes', () {
    test('is the same shape the quick sheets write', () {
      final draft = assistantDraft(
        const LogFeedingAction(minutes: 12, side: FeedingSide.bottle),
        childId: 'c1',
        at: now,
      )!;

      expect(draft.type, LogType.feeding);
      expect(draft.title, LogType.feeding.label);
      expect(draft.durationMinutes, 12);
      expect(draft.feedingSide, FeedingSide.bottle);
      expect(draft.id, isEmpty, reason: 'the repository assigns the id');
    });

    test('is marked as the assistant\'s, without a word of any language', () {
      final draft = assistantDraft(
        const LogNappyAction(kind: NappyKind.both),
        childId: 'c1',
        at: now,
      )!;
      expect(draft.tags, contains(assistantTag));
      expect(draft.description, isEmpty);
    });

    test('a fever lands in the illness history, like a typed one', () {
      final fever = assistantDraft(
        const LogTemperatureAction(celsius: 39.2),
        childId: 'c1',
        at: now,
      )!;
      expect(fever.type, LogType.illness);
      expect(fever.severity, Severity.severe);
      expect(fever.metrics.temperatureC, 39.2);

      final normal = assistantDraft(
        const LogTemperatureAction(celsius: 36.8),
        childId: 'c1',
        at: now,
      )!;
      expect(normal.type, LogType.measurement);
      expect(normal.severity, isNull);
    });

    test('an action that opens something writes nothing', () {
      expect(
        assistantDraft(
          const OpenScreenAction(path: '/diary'),
          childId: 'c1',
          at: now,
        ),
        isNull,
      );
      expect(
        assistantDraft(const BuildReportAction(), childId: 'c1', at: now),
        isNull,
      );
    });
  });

  group('the system prompt', () {
    test('names the marker the parser looks for', () {
      expect(systemPrompt, contains(actionMarker));
    });

    test('says the model proposes and the parent confirms', () {
      expect(systemPrompt, contains('родитель'));
      expect(systemPrompt, contains('подтверждает одним нажатием'));
    });

    test('spells out what it may never do', () {
      expect(systemPrompt, contains('Не можешь удалять записи'.substring(3)));
      expect(systemPrompt, contains('медицинскую карту'));
      expect(systemPrompt, contains('настройки аккаунта'));
    });

    test('forbids inventing numbers the parent did not say', () {
      expect(systemPrompt, contains('Не придумывай минуты'));
    });
  });

  group('on the screen', () {
    final child = Child(
      id: 'demo',
      parentUid: 'u',
      name: 'Айгерим',
      birthDate: DateTime(2026, 2, 7),
      gender: Gender.female,
    );

    /// A proxy that answers with one canned reply, action line and all.
    http.Client canned(String text) => MockClient((_) async {
      return http.Response.bytes(
        utf8.encode(jsonEncode({'text': text})),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    Future<void> pump(
      WidgetTester tester,
      String text, {
      List<Override> overrides = const [],
    }) async {
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
            remindersProvider.overrideWith(
              (ref) => Stream.value(const <Reminder>[]),
            ),
            assistantServiceProvider.overrideWith(
              (ref) => GeminiAssistantService(
                client: canned(text),
                endpoint: 'https://example.invalid/ai',
              ),
            ),
            ...overrides,
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
    }

    Future<void> ask(WidgetTester tester, String question) async {
      await tester.enterText(find.byType(TextField), question);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
    }

    testWidgets('a proposal is shown, and nothing is written yet', (
      tester,
    ) async {
      await pump(
        tester,
        'Записываю сон.\n$actionMarker'
        '{"tool":"log_sleep","args":{"minutes":90}}',
      );
      await ask(tester, 'запиши что он поспал полтора часа');

      final l = await AppLocalizations.delegate.load(defaultLocale);
      expect(find.text(l.actionSuggested), findsOneWidget);
      expect(find.text(l.actionConfirm), findsOneWidget);
      // The machinery never reaches the screen.
      expect(find.textContaining(actionMarker), findsNothing);
      expect(find.textContaining('log_sleep'), findsNothing);
    });

    testWidgets('confirming writes the entry once', (tester) async {
      await pump(
        tester,
        'Записываю.\n$actionMarker'
        '{"tool":"log_nappy","args":{"kind":"wet"}}',
      );
      await ask(tester, 'запиши подгузник');

      final l = await AppLocalizations.delegate.load(defaultLocale);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );

      await tester.tap(find.text(l.actionConfirm));
      // Bounded pumps rather than pumpAndSettle: the confirmation strip stays
      // on screen for four seconds by design, and "settled" is not a state a
      // snackbar reaches while it is being read.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // runAsync because the repository's stream delivers on a real
      // microtask, which the widget tester's fake clock never reaches.
      final logs = await tester.runAsync(
        () => container.read(logRepositoryProvider).watchLogs('demo').first,
      );
      expect(logs!.where((log) => log.type == LogType.nappy), hasLength(1));

      // And the card steps aside, so it cannot be tapped twice.
      expect(find.text(l.actionConfirm), findsNothing);
    });

    testWidgets('declining writes nothing', (tester) async {
      await pump(
        tester,
        'Записываю.\n$actionMarker'
        '{"tool":"log_nappy","args":{"kind":"wet"}}',
      );
      await ask(tester, 'запиши подгузник');

      final l = await AppLocalizations.delegate.load(defaultLocale);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );

      await tester.tap(find.text(l.actionDismiss));
      await tester.pumpAndSettle();

      final logs = await tester.runAsync(
        () => container.read(logRepositoryProvider).watchLogs('demo').first,
      );
      expect(logs, isEmpty);
      expect(find.text(l.actionSuggested), findsNothing);
    });

    testWidgets('a viewer sees the proposal and cannot act on it', (
      tester,
    ) async {
      await pump(
        tester,
        'Записываю.\n$actionMarker'
        '{"tool":"log_nappy","args":{"kind":"wet"}}',
        overrides: [
          accessRoleProvider.overrideWithValue(FamilyRole.viewer),
        ],
      );
      await ask(tester, 'запиши подгузник');

      final l = await AppLocalizations.delegate.load(defaultLocale);
      expect(find.text(l.actionSuggested), findsOneWidget);
      expect(find.text(l.actionConfirm), findsNothing);
      expect(find.text(l.actionReadOnly), findsOneWidget);
    });

    testWidgets('an answer without an action shows no card', (tester) async {
      await pump(tester, 'Кормите по требованию, 8-12 раз в сутки.');
      await ask(tester, 'сколько раз кормить');

      final l = await AppLocalizations.delegate.load(defaultLocale);
      expect(find.text(l.actionSuggested), findsNothing);
    });

    testWidgets('a red flag never gets a card, whatever the model wanted', (
      tester,
    ) async {
      // The gate fires before the model is called at all, so there is no
      // reply to carry an action — asserted here because this is the screen
      // where a stray confirm button would be tapped.
      await pump(
        tester,
        'Записываю.\n$actionMarker'
        '{"tool":"log_nappy","args":{"kind":"wet"}}',
      );
      await ask(tester, 'ребёнок не дышит');

      final l = await AppLocalizations.delegate.load(defaultLocale);
      expect(find.text(l.chatEmergency), findsOneWidget);
      expect(find.text(l.actionSuggested), findsNothing);
    });
  });
}
