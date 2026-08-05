import 'dart:async';

import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/data/repositories.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A brand-new account, before any child exists.
///
/// This is the first thing a real user sees, and it used to be a dead end:
/// the screen said "open the Children section and add a profile" and offered
/// no way to do it. Every screen that can show the placeholder must carry the
/// button itself.
class _EmptyChildRepository implements ChildRepository {
  final _children = <Child>[];
  final _controller = StreamController<List<Child>>.broadcast();

  /// Republishes on every change, the way the real repositories do. A
  /// one-shot `Stream.value` would leave the screen showing the placeholder
  /// after a child was created — a defect in the double, not in the app.
  @override
  Stream<List<Child>> watchChildren(String parentUid) =>
      Stream<List<Child>>.multi((listener) {
        listener.add(List.of(_children));
        final sub = _controller.stream.listen(listener.add);
        listener.onCancel = sub.cancel;
      });

  @override
  Future<Child> add({
    required String parentUid,
    required String name,
    required DateTime birthDate,
    required Gender gender,
  }) async {
    final child = Child(
      id: 'c1',
      parentUid: parentUid,
      name: name,
      birthDate: birthDate,
      gender: gender,
    );
    _children.add(child);
    _controller.add(List.of(_children));
    return child;
  }

  @override
  Future<void> update(Child child) async {}

  @override
  Future<void> delete(String childId) async {}
}

void main() {
  setUpAll(() => initializeDateFormatting());

  Future<void> pumpEmpty(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childRepositoryProvider.overrideWithValue(_EmptyChildRepository()),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the dashboard invites rather than instructs', (tester) async {
    await pumpEmpty(tester);

    expect(find.text('Давайте познакомимся'), findsOneWidget);
    expect(find.text('Добавить ребёнка'), findsOneWidget);
  });

  testWidgets('the button opens the form right there', (tester) async {
    await pumpEmpty(tester);

    await tester.tap(find.text('Добавить ребёнка'));
    await tester.pumpAndSettle();

    expect(find.text('Новый профиль'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Имя'), findsOneWidget);
  });

  testWidgets('every screen with the placeholder offers the button', (
    tester,
  ) async {
    // Reaching the section that has the button is not the user's job; the
    // dead end was the whole complaint. Only four destinations fit the phone
    // bottom bar, so the rest are checked through the "Ещё" sheet.
    for (final (icon, viaMore) in const [
      (Icons.auto_stories_outlined, false), // Дневник
      (Icons.show_chart_outlined, true), // Развитие, behind "Ещё"
    ]) {
      await pumpEmpty(tester);
      if (viaMore) {
        await tester.tap(find.text('Ещё'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(icon).first);
      await tester.pumpAndSettle();

      expect(
        find.text('Добавить ребёнка'),
        findsOneWidget,
        reason: 'the placeholder must carry the button on every screen',
      );
    }

    for (final section in const ['Болезни', 'Медкарта', 'Напоминания']) {
      await pumpEmpty(tester);
      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(section));
      await tester.pumpAndSettle();

      expect(
        find.text('Добавить ребёнка'),
        findsOneWidget,
        reason: '«$section» must carry the button too',
      );
    }
  });

  testWidgets('creating a child replaces the placeholder', (tester) async {
    await pumpEmpty(tester);

    await tester.tap(find.text('Добавить ребёнка'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Имя'),
      'Айгерим',
    );

    // The date field must be filled: a birth date drives the age, the WHO
    // percentiles and the vaccination schedule.
    await tester.tap(find.text('Выберите дату'));
    await tester.pumpAndSettle();
    // Cyrillic О and К: the Russian Material localisation, not the Latin
    // "OK" the English one uses.
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Создать'));
    await tester.pumpAndSettle();

    expect(find.text('Давайте познакомимся'), findsNothing);
    expect(find.text('Айгерим'), findsWidgets);
  });
}
