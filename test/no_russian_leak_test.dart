import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/assistant/assistant_nav_icon.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/core/vaccination/national_calendar.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The half-translated app gave itself away in the content, not the chrome:
/// menus in Kazakh over a diary that still said «Кормление». This walks the
/// real widget tree on each screen and fails on any word that leaked through
/// from a model, an enum or a stored document title.
void main() {
  setUpAll(initializeDateFormatting);

  /// Words a Kazakh or English screen must never contain. All of them come
  /// from data the app writes into Firestore in Russian.
  const russianLeaks = [
    'Кормление',
    'Сон',
    'Подгузник',
    'Температура',
    'ревакцинация',
    'Календарь прививок РК',
    'Левая',
    'Правая',
    'Бутылочка',
    'Мокрый',
    'Стул',
    'Лекарство',
    'Ночной сон',
    'первая доза',
    'вторая доза',
    'Тяжёлая',
    'Средняя',
    'Лёгкая',
    // The fourth way food arrives, and the note a reaction is filed as. Both
    // are stored in Russian like every other enum code and title.
    'Прикорм',
    'Реакция',
    'Сцеживание',
  ];

  /// The one Russian word on these screens that is allowed to stay: «Кабачок»
  /// is what the mother typed, and translating a mother's word for her child's
  /// first food would be rewriting her diary rather than localizing the app.
  const herOwnWords = 'Кабачок';

  /// And the Kazakh ones an English screen must not borrow.
  const kazakhLeaks = ['Сол жақ', 'Оң жақ', 'Жаялық', 'Ұйқы'];

  final today = DateTime(2026, 8, 2, 15);

  DevelopmentLog log(
    LogType type, {
    required String title,
    Duration ago = const Duration(hours: 2),
    int? minutes,
    int? wakings,
    FeedingSide? side,
    NappyKind? nappy,
    double? temperature,
    Severity? severity,
    String? food,
    int? milkMl,
  }) => DevelopmentLog(
    id: '$title$ago',
    childId: 'demo',
    date: today.subtract(ago),
    type: type,
    title: title,
    durationMinutes: minutes,
    nightWakings: wakings,
    feedingSide: side,
    nappyKind: nappy,
    severity: severity,
    food: food,
    milkMl: milkMl,
    metrics: Metrics(temperatureC: temperature),
  );

  /// Exactly what the app itself writes: Russian titles, Russian enum codes.
  final entries = <DevelopmentLog>[
    log(LogType.feeding, title: 'Кормление', side: FeedingSide.left,
        ago: const Duration(minutes: 40)),
    log(LogType.feeding, title: 'Кормление', side: FeedingSide.bottle,
        ago: const Duration(hours: 4)),
    log(LogType.nappy, title: 'Подгузник', nappy: NappyKind.both,
        ago: const Duration(hours: 1)),
    log(LogType.nappy, title: 'Подгузник', nappy: NappyKind.wet,
        ago: const Duration(hours: 3)),
    log(LogType.sleep, title: 'Сон', minutes: 90,
        ago: const Duration(hours: 5)),
    log(LogType.sleep, title: 'Сон', minutes: 540, wakings: 3,
        ago: const Duration(hours: 18)),
    log(LogType.illness, title: 'Температура 38.5 °C', temperature: 38.5,
        severity: Severity.moderate, ago: const Duration(hours: 6)),
    log(LogType.note, title: LogTitles.medicine,
        ago: const Duration(hours: 7)),
    log(LogType.feeding, title: 'Кормление', side: FeedingSide.solid,
        food: herOwnWords, ago: const Duration(hours: 2)),
    log(LogType.note, title: LogTitles.reaction, food: herOwnWords,
        ago: const Duration(hours: 1, minutes: 30)),
    log(LogType.note, title: LogTitles.pumping, milkMl: 120,
        ago: const Duration(hours: 5)),
  ];

  final child = Child(
    id: 'demo',
    parentUid: 'u',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  /// A plan straight out of the national schedule, stored the way it is
  /// stored in Firestore.
  final vaccinations = buildVaccinationPlan(child, now: today);

  Future<void> pump(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith(() => LocaleChoice(locale)),
          childrenProvider.overrideWith((ref) => Stream.value([child])),
          logsProvider.overrideWith((ref) => Stream.value(entries)),
          remindersProvider.overrideWith((ref) => Stream.value(vaccinations)),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The wide layout puts every destination in the rail, so screens are
  /// reached by their own localized label rather than by an icon that also
  /// appears three times inside the cards.
  Future<void> openScreen(
    WidgetTester tester,
    String Function(AppLocalizations) label,
  ) async {
    final l = await AppLocalizations.delegate.load(
      Localizations.localeOf(tester.element(find.byType(Scaffold).first)),
    );
    await tester.tap(find.text(label(l)).last);
    await tester.pumpAndSettle();
  }

  /// Every string the tree is actually drawing.
  List<String> visibleText(WidgetTester tester) => [
    for (final widget in tester.allWidgets)
      if (widget is Text && widget.data != null)
        widget.data!
      else if (widget is RichText)
        widget.text.toPlainText(),
  ];

  void expectNoLeaks(
    WidgetTester tester,
    Locale locale,
    String screen,
  ) {
    final forbidden = [
      ...russianLeaks,
      if (locale.languageCode == 'en') ...kazakhLeaks,
    ];
    final shown = visibleText(tester);

    for (final word in forbidden) {
      final offenders = shown.where((t) => t.contains(word)).toList();
      expect(
        offenders,
        isEmpty,
        reason:
            '«$word» leaked onto $screen in ${locale.languageCode}: $offenders',
      );
    }
  }

  for (final locale in [const Locale('kk'), const Locale('en')]) {
    final code = locale.languageCode;

    testWidgets('$code — the dashboard is clean', (tester) async {
      await pump(tester, locale);
      expectNoLeaks(tester, locale, 'the dashboard');
    });

    testWidgets('$code — the diary timeline is clean', (tester) async {
      await pump(tester, locale);
      await openScreen(tester, (l) => l.navDiary);

      expectNoLeaks(tester, locale, 'the diary');
    });

    testWidgets('$code — the quick log sheet is clean', (tester) async {
      await pump(tester, locale);

      // Every branch of it: the options are enum labels, which is exactly
      // where the Russian used to come from.
      final l = await AppLocalizations.delegate.load(locale);
      await tester.tap(find.widgetWithText(InkWell, l.quickFeed));
      await tester.pumpAndSettle();
      // Scoped to the sheet: the suggestion card on the dashboard behind it
      // offers a button with the same word.
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(l.quickTimeNow),
        ),
      );
      await tester.pumpAndSettle();

      expectNoLeaks(tester, locale, 'the feeding sheet');
    });

    testWidgets('$code — the illness screen is clean', (tester) async {
      await pump(tester, locale);
      await openScreen(tester, (l) => l.navIllness);

      expectNoLeaks(tester, locale, 'the illness screen');
    });

    testWidgets('$code — the reminders screen is clean', (tester) async {
      await pump(tester, locale);
      await openScreen(tester, (l) => l.navReminders);

      expectNoLeaks(tester, locale, 'the reminders screen');
    });

    testWidgets('$code — the chat window is clean', (tester) async {
      await pump(tester, locale);
      await tester.tap(find.byType(AssistantNavIcon));
      await tester.pumpAndSettle();

      // Nothing but the conversation is on this screen now — the five facts
      // about the child that used to be printed above it reach the model in
      // the prompt instead. So this is the frame: title, placeholder, the
      // opening line.
      expectNoLeaks(tester, locale, 'the chat window');
    });
  }

  testWidgets('a title the parent typed herself is never translated', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith(() => LocaleChoice(const Locale('en'))),
          childrenProvider.overrideWith((ref) => Stream.value([child])),
          logsProvider.overrideWith(
            (ref) => Stream.value([
              log(LogType.milestone, title: 'Первое слово'),
            ]),
          ),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
    await tester.pumpAndSettle();

    // Her diary, her words — the app translates its own vocabulary, not hers.
    expect(find.text('Первое слово'), findsWidgets);
  });
}
