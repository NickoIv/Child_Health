import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/router/app_router.dart';
import 'package:child_health_tracker/features/shell/app_shell.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «Свайпа экрана не хватает влево и вправо.»
///
/// A bottom bar is a set of targets to aim at. A swipe is what a thumb does
/// without aiming, which on a phone held in one hand with a child in the
/// other is most of the difference between using the app and putting it down.
///
/// Half of what is tested here is the swipes that must *not* happen: past the
/// ends, on the screens behind «Ещё», and — the one that would make the diary
/// unusable — on content that scrolls sideways under the finger.
void main() {
  setUpAll(initializeDateFormatting);

  final child = Child(
    id: 'c1',
    parentUid: 'demo-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  Future<void> pump(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  String locationOf(WidgetTester tester) =>
      tester.widget<AppShell>(find.byType(AppShell)).location;

  /// A flick across the middle of the page, well clear of the bars.
  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.fling(
      find.byType(SwipeBetweenTabs),
      Offset(dx, 0),
      600,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a flick left moves to the next tab, and right comes back', (
    tester,
  ) async {
    await pump(tester);
    expect(locationOf(tester), '/');

    await swipe(tester, -300);
    expect(locationOf(tester), '/diary');

    await swipe(tester, -300);
    expect(locationOf(tester), '/assistant');

    await swipe(tester, 300);
    expect(locationOf(tester), '/diary');
  });

  testWidgets('it stops at both ends instead of wrapping round', (
    tester,
  ) async {
    // Running out of tabs is how a person learns where the ends are.
    await pump(tester);
    await swipe(tester, 300);
    expect(locationOf(tester), '/', reason: 'nothing before the first');

    for (var i = 0; i < 5; i++) {
      await swipe(tester, -300);
    }
    expect(
      locationOf(tester),
      appDestinations[3].path,
      reason: 'nothing after the fourth',
    );
  });

  testWidgets('a small nudge is not a swipe', (tester) async {
    // A page moved sideways while reaching for something must not change tab.
    await pump(tester);
    await tester.drag(find.byType(SwipeBetweenTabs), const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(locationOf(tester), '/');
  });

  testWidgets('the filter row still scrolls sideways without changing tab', (
    tester,
  ) async {
    // The gesture that would have broken the diary. Flutter's arena gives a
    // horizontal drag to the innermost recogniser that wants it, so a drag
    // starting on the chips belongs to the chips.
    await pump(tester);
    await swipe(tester, -300);
    expect(locationOf(tester), '/diary');
    final l = await AppLocalizations.delegate.load(defaultLocale);

    final chips = find.ancestor(
      of: find.text(l.commonAll),
      matching: find.byType(ListView),
    );
    expect(chips, findsWidgets);
    await tester.fling(chips.first, const Offset(-200, 0), 600);
    await tester.pumpAndSettle();

    expect(locationOf(tester), '/diary', reason: 'the chips took the drag');
  });

  testWidgets('and a screen from «Ещё» has nothing to swipe between', (
    tester,
  ) async {
    await pump(tester);
    final router = goOf(tester);
    router('/growth');
    await tester.pumpAndSettle();
    expect(locationOf(tester), '/growth');

    // It is still in the tree — it wraps the whole body — but it is inert
    // there: past the four in the bar there is no next tab to go to, and a
    // swipe should do nothing rather than something surprising.
    await swipe(tester, -300);
    expect(locationOf(tester), '/growth');
    await swipe(tester, 300);
    expect(locationOf(tester), '/growth');
  });

  testWidgets('a wide window keeps the rail and no swipe', (tester) async {
    // On a laptop the destinations are a rail and a drag across the page is
    // not a navigation anybody expects.
    await pump(tester, size: const Size(1200, 900));
    expect(find.byType(SwipeBetweenTabs), findsNothing);
  });
}

/// `go` on the router the shell is actually using.
void Function(String) goOf(WidgetTester tester) {
  final context = tester.element(find.byType(AppShell));
  final container = ProviderScope.containerOf(context);
  return container.read(routerProvider).go;
}
