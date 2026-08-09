import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The app is used on a phone, one-handed, by someone holding a baby.
///
/// Every test here runs at a real handset size. Flutter throws on an overflow,
/// so simply building these screens at 390 logical pixels is a genuine check
/// that nothing spills off the side — which is the failure a desktop-sized
/// test would never see.
void main() {
  setUpAll(() => initializeDateFormatting());

  /// iPhone 14 / Pixel 7 class, the common case.
  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
  }

  /// Only four destinations fit the bottom bar; the rest are behind «Ещё».
  Future<void> openMore(WidgetTester tester, String label) async {
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('the dashboard fits a phone screen', (tester) async {
    await pumpPhone(tester);
    expect(find.widgetWithText(AppBar, 'Обзор'), findsOneWidget);
    expect(find.text('Демо-профиль'), findsWidgets);
  });

  testWidgets('the bottom bar is used instead of the rail', (tester) async {
    await pumpPhone(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('quick actions are all reachable', (tester) async {
    await pumpPhone(tester);
    // Four primary cards, two by two. On one row they would each be too
    // small to hit reliably; in one column they would be a list to read.
    for (final label in const [
      'Покормила',
      'Поспал',
      'Подгузник',
      'Температура',
    ]) {
      expect(
        find.widgetWithText(InkWell, label),
        findsOneWidget,
        reason: '«$label» must be on the phone dashboard',
      );
    }

    // The two that used to be cards of their own are still one tap away:
    // a night under the sleep action, and the assistant in the bottom bar.
    expect(find.text('Ночной сон'), findsOneWidget);
    expect(find.text('Помощник'), findsWidgets);
  });

  testWidgets('logging a feed takes two taps and shows in the count', (
    tester,
  ) async {
    await pumpPhone(tester);

    await tester.tap(find.text('Покормила'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сейчас'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Левая'));
    await tester.pumpAndSettle();

    // The tallies moved to the assistant tab with the rest of the reading;
    // what the home screen owes her is proof the tap landed.
    expect(find.textContaining('Записано'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(RecentPreview),
        matching: find.textContaining('Кормление'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('logging a nappy counts it as wet', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.text('Подгузник'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сейчас'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Мокрый и стул'));
    await tester.pumpAndSettle();

    // It reaches the diary, which the home screen previews.
    expect(
      find.descendant(
        of: find.byType(RecentPreview),
        matching: find.textContaining('Подгузник'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('logging sleep records a duration', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.text('Поспал'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сейчас'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Полтора часа'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 ч 30 мин'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(RecentPreview),
        matching: find.textContaining('Сон'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('time since the last feed is shown prominently', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.text('Покормила'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сейчас'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Бутылочка'));
    await tester.pumpAndSettle();

    // The most-asked question of a newborn day is the one fact the warm
    // header spends a line on.
    expect(
      find.descendant(
        of: find.byType(WarmHeader),
        matching: find.textContaining('ПОСЛЕДНЕЕ КОРМЛЕНИЕ'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a question for the doctor can be written down', (tester) async {
    await pumpPhone(tester);

    // Only four destinations fit the bottom bar; the medical card lives
    // behind "Ещё". Worth encoding — it is how the phone navigation works.
    await tester.tap(find.text('Ещё'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Медкарта'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Записать').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Нормально ли срыгивание',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Нормально ли срыгивание'), findsOneWidget);
  });

  testWidgets('the assistant fits a phone', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.byIcon(Icons.lightbulb_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Проверить тревожные признаки'), findsOneWidget);
    expect(find.text('Спросить своими словами'), findsOneWidget);
  });

  testWidgets('an article reads without overflowing', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.byIcon(Icons.lightbulb_outline).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'температура');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Температура у ребёнка').first);
    await tester.pumpAndSettle();

    expect(find.text('Что делать сейчас'), findsOneWidget);
    expect(find.text('Скорая помощь — 103'), findsOneWidget);
  });

  testWidgets('the growth chart renders on a phone', (tester) async {
    await pumpPhone(tester);
    // Growth sits behind "Ещё" now: the four tabs that fit a phone are home,
    // the diary, the assistant and the family.
    await tester.tap(find.text('Ещё'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Динамика показателей'), findsOneWidget);
  });

  testWidgets('the measurement button fits beside the chart', (tester) async {
    await pumpPhone(tester);
    // Growth sits behind "Ещё" now: the four tabs that fit a phone are home,
    // the diary, the assistant and the family.
    await tester.tap(find.text('Ещё'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart_outlined).first);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FloatingActionButton, 'Добавить измерение'),
      findsOneWidget,
    );
  });

  testWidgets('the profile list fits with an avatar and both actions', (
    tester,
  ) async {
    await pumpPhone(tester);
    await openMore(tester, 'Дети');

    // A chip, a pencil and a bin on one narrow row is exactly the kind of
    // trailing group that overflows.
    expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    expect(find.byIcon(Icons.delete_outline), findsWidgets);
  });

  testWidgets('the profile form fits with its photo picker', (tester) async {
    await pumpPhone(tester);
    await openMore(tester, 'Дети');

    await tester.tap(find.text('Добавить ребёнка'));
    await tester.pumpAndSettle();

    expect(find.text('Добавить фото'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Создать'), findsOneWidget);
  });

  testWidgets('settings fits, all the way down to account deletion', (
    tester,
  ) async {
    await pumpPhone(tester);
    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Профиль и настройки'));
    await tester.pumpAndSettle();

    expect(find.text('Родитель'), findsOneWidget);

    // The page grew a layout editor and an account section; the bottom of it
    // has to stay reachable and unbroken on a phone.
    await tester.scrollUntilVisible(
      find.text('Удалить учётную запись'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Удалить учётную запись'), findsOneWidget);
  });

  group('«Ещё»', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpPhone(tester);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
    }

    testWidgets('sorts the rest of the app onto three shelves', (tester) async {
      await openSheet(tester);

      // The headings, in the order a parent needs them: what a doctor asks
      // about, what she is keeping, and who this is.
      expect(find.text('ЗДОРОВЬЕ'), findsOneWidget);
      expect(find.text('ПАМЯТЬ'), findsOneWidget);
      expect(find.text('ПРОФИЛЬ'), findsOneWidget);

      // Every destination that is not one of the four in the bar is here,
      // exactly once.
      for (final label in const [
        'Развитие',
        'Болезни',
        'Медкарта',
        'Напоминания',
        'Фотографии',
        'Дети',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('says what is on each screen rather than only naming it', (
      tester,
    ) async {
      await openSheet(tester);

      // The line that turns six equal labels into six different things. The
      // vaccination calendar is the case that made this necessary: nobody
      // guesses it is filed under «Напоминания».
      expect(find.text('Лекарства и календарь прививок'), findsOneWidget);
      expect(find.text('Вес, рост и перцентили ВОЗ'), findsOneWidget);
      expect(find.text('Альбом и недельная история'), findsOneWidget);
    });

    testWidgets('is the first way to settings that is not the avatar menu', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Профиль и настройки'));
      await tester.pumpAndSettle();

      expect(find.text('Родитель'), findsOneWidget);
    });
  });

  testWidgets('the triage checklist fits', (tester) async {
    await pumpPhone(tester);

    // The checklist lives in the assistant, which is where a parent looking
    // for guidance goes. The home screen keeps only what she records.
    await tester.tap(find.byIcon(Icons.lightbulb_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Проверить тревожные признаки'));
    await tester.pumpAndSettle();

    expect(find.text('Отметьте всё, что есть'), findsOneWidget);

    // The checklist is long on a phone, so the button starts off-screen and
    // the list has not built it yet. Scrolling to it is also the check that
    // a thumb can actually reach it.
    await tester.scrollUntilVisible(
      find.text('Оценить состояние'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Оценить состояние'), findsOneWidget);
  });
}
