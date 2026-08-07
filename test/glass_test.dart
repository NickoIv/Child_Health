import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/theme/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The frosted tab bar — his suggestion, taken where it earns its keep.
///
/// Glass only works if the page actually runs underneath it, and that is the
/// part that breaks things: every screen with a floating button is a Scaffold
/// nested inside the shell's, and none of them knows the bar is there. The
/// button on «Дети» landed behind the glass and could not be pressed at all.
void main() {
  setUpAll(initializeDateFormatting);

  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('the tab bar is a pane of glass, not a plank', (tester) async {
    await pumpPhone(tester);

    expect(find.byType(GlassPanel), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );

    // The bar itself paints nothing: the panel behind it is the surface, and
    // a white NavigationBar inside frosted glass is just a white plank with a
    // blur wasted behind it.
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.backgroundColor, Colors.transparent);
  });

  testWidgets('the page runs underneath it', (tester) async {
    await pumpPhone(tester);

    final panel = tester.getRect(find.byType(GlassPanel));
    final scroll = tester.getRect(find.byType(Scrollable).first);

    // Not "stops above it": the whole point is that the list keeps going.
    expect(scroll.bottom, greaterThan(panel.top));
  });

  testWidgets('and the page can still be scrolled clear of it', (tester) async {
    await pumpPhone(tester);

    // PageBody gives the bar's height back as padding, so the last card is
    // reachable rather than permanently parked under the glass.
    final body = tester.widget<ListView>(find.byType(ListView).first);
    final panel = tester.getRect(find.byType(GlassPanel));
    expect(
      (body.padding! as EdgeInsets).bottom,
      greaterThanOrEqualTo(panel.height),
    );
  });

  for (final tab in const ['Дневник', 'Дети']) {
    testWidgets('the button on «$tab» is not behind the glass', (tester) async {
      await pumpPhone(tester);

      if (tab == 'Дети') {
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();

      final fab = tester.getRect(find.byType(FloatingActionButton));
      final panel = tester.getRect(find.byType(GlassPanel));

      expect(
        fab.bottom,
        lessThanOrEqualTo(panel.top),
        reason: 'the $tab button is drawn under the tab bar',
      );
      // And it answers a tap, which is the thing the geometry is a proxy for.
      expect(
        tester.hitTestOnBinding(fab.center).path.any(
          (e) => e.target is RenderBox,
        ),
        isTrue,
      );
    });
  }

  test('the glass is opaque enough to read a label through', () {
    // Below about 0.7 a dark photograph scrolling under the bar takes the
    // unselected labels below 4.5:1.
    expect(GlassPanel.opacity, greaterThanOrEqualTo(0.7));
    expect(GlassPanel.opacity, lessThan(1.0));
    // And blurred enough that the text underneath stops being text.
    expect(GlassPanel.blur, greaterThanOrEqualTo(18));
  });
}
