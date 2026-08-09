import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/theme/night_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The deep red screen, for feeds that happen in the dark.
///
/// What is tested is that it really is red — that the green and blue channels
/// are gone rather than merely reduced, which is the whole physical claim —
/// that it covers everything the app draws rather than a list of screens
/// someone remembered, and that it is off until she asks for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  group('the filter', () {
    test('removes green and blue rather than dimming them', () {
      final m = nightMatrix(dim: 1);
      expect(m, hasLength(20));

      // The red row carries the standard luminance weights, so a colour keeps
      // the brightness it had rather than whatever its red channel was.
      expect(m.sublist(0, 3), [0.2126, 0.7152, 0.0722]);

      // The green and blue rows are zero outright. Halving them would look
      // gentler and defeat the purpose — short wavelengths are what wake a
      // child and what costs a parent her night vision.
      expect(m.sublist(5, 10), everyElement(0.0));
      expect(m.sublist(10, 15), everyElement(0.0));

      // Alpha passes through untouched, or nothing would be visible at all.
      expect(m.sublist(15), [0.0, 0.0, 0.0, 1.0, 0.0]);
    });

    test('takes a quarter of the brightness with it', () {
      // Brightness is the other half of what wakes a baby.
      expect(nightDim, 0.75);
      final dimmed = nightMatrix();
      expect(dimmed[0], closeTo(0.2126 * 0.75, 1e-9));
      expect(dimmed[1], closeTo(0.7152 * 0.75, 1e-9));
      expect(nightFilter(), isA<ColorFilter>());
    });

    test('a white pixel comes out pure red', () {
      // The arithmetic the matrix does, run by hand on white: R gets the sum
      // of the weights, G and B get nothing.
      final m = nightMatrix(dim: 1);
      final red = m[0] + m[1] + m[2];
      final green = m[5] + m[6] + m[7];
      final blue = m[10] + m[11] + m[12];
      expect(red, closeTo(1.0, 1e-9));
      expect(green, 0);
      expect(blue, 0);
    });
  });

  group('when it is on', () {
    test('off is off, on is on, and automatic follows the clock', () {
      final night = DateTime(2026, 8, 9, 3);
      final afternoon = DateTime(2026, 8, 9, 15);

      expect(nightModeActive(NightPreference.off, now: night), isFalse);
      expect(nightModeActive(NightPreference.on, now: afternoon), isTrue);
      expect(nightModeActive(NightPreference.auto, now: night), isTrue);
      expect(nightModeActive(NightPreference.auto, now: afternoon), isFalse);

      // The window is the one the dark theme already uses: there is no second
      // definition of night in this app.
      expect(
        nightModeActive(NightPreference.auto, now: DateTime(2026, 8, 9, 21)),
        isTrue,
      );
      expect(
        nightModeActive(NightPreference.auto, now: DateTime(2026, 8, 9, 7)),
        isFalse,
      );
    });

    test('is off until she asks for it', () {
      // Automatic would be the kind guess and the wrong default: a screen that
      // turns dark red on its own reads as a fault.
      expect(defaultNight, NightPreference.off);
    });
  });

  group('the setting', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is remembered, and read back on the next run', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      await c.read(nightPreferenceProvider.notifier).set(NightPreference.on);
      expect(c.read(nightModeProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('night_mode'), 'on');

      // A second container is what a reload looks like from here.
      final reloaded = ProviderContainer();
      addTearDown(reloaded.dispose);
      reloaded.read(nightPreferenceProvider);
      await Future<void>.delayed(Duration.zero);
      expect(reloaded.read(nightPreferenceProvider), NightPreference.on);
    });
  });

  group('on the screen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(ChildHealthApp)),
      );
    }

    testWidgets('paints nothing through a filter until it is turned on', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      expect(find.byType(NightScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NightScreen),
          matching: find.byType(ColorFiltered),
        ),
        findsNothing,
      );

      await container
          .read(nightPreferenceProvider.notifier)
          .set(NightPreference.on);
      await tester.pumpAndSettle();

      // Above the router, so every sheet, dialog and photograph goes through
      // it — including the ones written after today.
      expect(
        find.descendant(
          of: find.byType(NightScreen),
          matching: find.byType(ColorFiltered),
        ),
        findsWidgets,
      );
    });

    testWidgets('takes the light theme with it', (tester) async {
      final container = await pumpApp(tester);
      await container
          .read(nightPreferenceProvider.notifier)
          .set(NightPreference.on);
      await tester.pumpAndSettle();

      // Red type on a dark page, not a red page: the filter needs dark pixels
      // under it, whatever the appearance setting says.
      final app = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('is two taps away from any screen', (tester) async {
      final container = await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ночной режим'));
      await tester.pumpAndSettle();

      expect(container.read(nightModeProvider), isTrue);
    });
  });
}
