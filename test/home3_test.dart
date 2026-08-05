import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/core/theme/motion.dart';
import 'package:child_health_tracker/core/voice/dictation.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:child_health_tracker/features/dashboard/voice_action_button.dart';
import 'package:child_health_tracker/features/family/family_screen.dart';
import 'package:child_health_tracker/features/shared/photo_widgets.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/photo.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Home 3.0: the shape of the screen, and the microphone you have to hold.
void main() {
  setUpAll(initializeDateFormatting);

  const pixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  final child = Child(
    id: 'c1',
    parentUid: 'demo-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  late _FakeDictation dictation;

  setUp(() => dictation = _FakeDictation());

  Future<void> pump(
    WidgetTester tester, {
    List<DevelopmentLog>? logs,
    Size size = const Size(390, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
          dictationProvider.overrideWithValue(dictation),
          photoProvider.overrideWith(
            (ref, id) async => Photo(
              id: id,
              childId: child.id,
              base64Data: pixel,
              width: 1,
              height: 1,
              createdAt: DateTime(2026),
            ),
          ),
          if (logs != null)
            logsProvider.overrideWith((ref) => Stream.value(logs)),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the top of the screen', () {
    testWidgets('the header carries the child and a single subtitle', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);
      final header = find.byType(WarmHeader);

      expect(header, findsOneWidget);
      expect(
        find.descendant(of: header, matching: find.text(child.name)),
        findsOneWidget,
      );
      // Age on its own line, and one warm line under it — no more.
      expect(
        find.descendant(of: header, matching: find.byType(Text)),
        findsNWidgets(3),
      );
      expect(
        find.descendant(
          of: header,
          matching: find.text(warmSubtitle(l, child, DateTime.now(), null)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the actions are a two by two square of 104px cards', (
      tester,
    ) async {
      await pump(tester);

      final cards = find.byType(ActionCard);
      expect(cards, findsNWidgets(4));

      final boxes = [
        for (final e in cards.evaluate()) tester.getRect(find.byWidget(e.widget)),
      ];
      for (final box in boxes) {
        expect(box.height, ActionCard.height);
      }
      expect(ActionCard.height, 104);
      expect(ActionCard.radius, 24);
      expect(ActionCard.iconSize, 28);
      expect(ActionCard.titleSize, 16);
      expect(ActionCard.captionSize, 11.5);

      // Two rows of two: the first two share a top, and the third starts
      // lower than the first.
      expect(boxes[0].top, boxes[1].top);
      expect(boxes[2].top, boxes[3].top);
      expect(boxes[2].top, greaterThan(boxes[0].top));
    });
  });

  group('the recent events', () {
    testWidgets('are a rail of at most three, with a photograph where there '
        'is one', (tester) async {
      final now = DateTime.now();
      await pump(
        tester,
        logs: [
          DevelopmentLog(
            id: 'p',
            childId: child.id,
            date: now.subtract(const Duration(minutes: 5)),
            type: LogType.milestone,
            title: 'Первая улыбка',
            photos: const ['a'],
          ),
          for (var i = 0; i < 5; i++)
            DevelopmentLog(
              id: 'f$i',
              childId: child.id,
              date: now.subtract(Duration(minutes: 30 * i + 30)),
              type: LogType.feeding,
              title: LogType.feeding.label,
              feedingSide: FeedingSide.left,
              durationMinutes: 15,
            ),
        ],
      );

      final rail = find.byType(RecentPreview);
      // Three events, and the photograph rides along with the entry it
      // belongs to rather than with the row that happens to be first.
      expect(
        find.descendant(of: rail, matching: find.byType(PhotoThumb)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rail, matching: find.text('Первая улыбка')),
        findsOneWidget,
      );
      // Time, title and the short detail under it.
      expect(
        find.descendant(of: rail, matching: find.textContaining('Левая')),
        findsWidgets,
      );
    });
  });

  group('the microphone', () {
    testWidgets('is 72 across and opens nothing on a tap', (tester) async {
      await pump(tester);

      expect(find.byType(VoiceActionButton), findsOneWidget);
      expect(VoiceActionButton.size, 72);

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump(const Duration(milliseconds: 300));
      expect(dictation.prepared, 0, reason: 'a tap must not open the mic');
    });

    testWidgets('opens while held and closes when released', (tester) async {
      await pump(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.mic)),
      );
      // Past the long-press threshold, which is what "hold" means here.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(dictation.prepared, 1);
      expect(dictation.listening, isTrue);
      // The panel with the waveform and the timer is only up while listening.
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text(voiceTimer(Duration.zero)), findsOneWidget);
      expect(voiceTimer(const Duration(seconds: 65)), '01:05');

      await gesture.up();
      await tester.pump();
      expect(dictation.listening, isFalse);
      expect(dictation.stopped, 1);
    });

    testWidgets('the waveform follows the room and stops with it', (
      tester,
    ) async {
      await pump(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.mic)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      dictation.speakAt(0.8);
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text(voiceTimer(Duration.zero)), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
      // Released: nothing left animating, which is what "no idle animation"
      // has to mean in practice.
      await tester.pumpAndSettle();
      expect(find.textContaining(':0'), findsNothing);
    });

    testWidgets('a heard sentence is shown back before anything is written', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.mic)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      dictation.say('покормила левой 15 минут');
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text(l.voiceHeard), findsOneWidget);
      expect(find.text('покормила левой 15 минут'), findsOneWidget);
      // Her words and the reading of them, and a button she has to press.
      expect(find.widgetWithText(FilledButton, l.commonSave), findsOneWidget);
    });
  });

  group('the tabs', () {
    testWidgets('are home, history, assistant and family', (tester) async {
      await pump(tester, size: const Size(390, 900));
      final l = await AppLocalizations.delegate.load(defaultLocale);

      final bar = find.byType(NavigationBar);
      expect(bar, findsOneWidget);
      for (final label in [
        l.navDashboard,
        l.navDiary,
        l.navAssistant,
        l.navFamily,
      ]) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets('the family tab is where the family lives', (tester) async {
      await pump(tester, size: const Size(390, 900));
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(l.navFamily),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FamilyScreen), findsOneWidget);
      // Scoped: the tab is called the same thing the card is, which is the
      // point of moving it out of settings.
      expect(
        find.descendant(
          of: find.byType(FamilyScreen),
          matching: find.text(l.familyTitle),
        ),
        findsOneWidget,
      );
    });
  });

  group('the motion', () {
    test('is one curve and four durations', () {
      expect(Motion.curve, Curves.easeOutCubic);
      expect(Pressable.pressedScale, 0.97);
      expect(Pressable.duration, const Duration(milliseconds: 110));
      expect(Arrival.rise, 8.0);
      expect(Arrival.duration, const Duration(milliseconds: 260));
    });

    test('the palette is the one asked for', () {
      expect(Warm.background, const Color(0xFFFFF8F2));
      expect(Warm.primaryCard, const Color(0xFFFFF1E6));
      expect(Warm.accent, const Color(0xFFE67E22));
      expect(Warm.lavender, const Color(0xFFF7EFFF));
      expect(Warm.ink, const Color(0xFF3B2B23));
      expect(Warm.inkSoft, const Color(0xFF8A6B5C));
      // Soft rather than absent: a cream page with a hard shadow reads as
      // dirty, and one with none reads as a wireframe.
      // Blur 24 at eight percent, offset down by eight — the one shadow
      // every raised surface in the app gets.
      final shadow = Warm.shadow(Brightness.light).single;
      expect(shadow.blurRadius, 24);
      expect(shadow.offset, const Offset(0, 8));
      expect(shadow.color.a, closeTo(0.08, 0.005));
      expect(Warm.shadow(Brightness.dark), isEmpty);
    });
  });
}

/// A recogniser that never touches a microphone.
class _FakeDictation implements Dictation {
  bool allowed = true;
  bool listening = false;
  int prepared = 0;
  int stopped = 0;

  ValueChanged<String>? _onResult;
  ValueChanged<double>? _onLevel;

  void say(String text) => _onResult?.call(text);
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
    _onResult = onResult;
    _onLevel = onLevel;
  }

  @override
  Future<void> stop() async {
    if (listening) stopped++;
    listening = false;
  }
}
