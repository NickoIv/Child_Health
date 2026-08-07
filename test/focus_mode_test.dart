import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/l10n/labels.dart';
import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/core/theme/motion.dart';
import 'package:child_health_tracker/core/voice/voice_commands.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:child_health_tracker/features/dashboard/now_card.dart';
import 'package:child_health_tracker/features/dashboard/pattern_card.dart';
import 'package:child_health_tracker/features/dashboard/reflection_card.dart';
import 'package:child_health_tracker/features/dashboard/smart_card.dart';
import 'package:child_health_tracker/features/dashboard/voice_action_button.dart';
import 'package:child_health_tracker/features/family/weekly_story_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The home screen, after it was emptied.
///
/// Two things are being checked. That what is left is the four things a parent
/// opens the app to do — and that nothing which left the screen left the app:
/// every block that moved is on the assistant tab, one tap away.
void main() {
  setUpAll(initializeDateFormatting);

  final child = Child(
    id: 'c1',
    parentUid: 'demo-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  final feedingSample = DevelopmentLog(
    id: 'sample',
    childId: child.id,
    date: DateTime(2026, 8, 5),
    type: LogType.feeding,
    title: LogType.feeding.label,
  );

  Future<void> pump(
    WidgetTester tester, {
    List<DevelopmentLog>? logs,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
          if (logs != null)
            logsProvider.overrideWith((ref) => Stream.value(logs)),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('what is left on the home screen', () {
    testWidgets('is a header, four actions, three events and one card', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byType(WarmHeader), findsOneWidget);
      expect(find.byType(ActionCard), findsNWidgets(4));
      expect(find.byType(RecentPreview), findsOneWidget);
      // At most one, ever. Three cards competing for the space under the
      // actions was the largest thing wrong with the old dashboard.
      expect(find.byType(SmartCard), findsOneWidget);
    });

    testWidgets('the preview shows three events and no more', (tester) async {
      final now = DateTime.now();
      await pump(
        tester,
        // Tall enough that the preview is inside the viewport: a lazy list
        // does not build what nobody can see.
        size: const Size(390, 1400),
        logs: [
          for (var i = 0; i < 8; i++)
            DevelopmentLog(
              id: 'l$i',
              childId: child.id,
              date: now.subtract(Duration(minutes: i * 30 + 5)),
              type: LogType.feeding,
              title: LogType.feeding.label,
            ),
        ],
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(
        find.descendant(
          of: find.byType(RecentPreview),
          matching: find.text(localizedLogTitle(l, feedingSample)),
        ),
        findsNWidgets(RecentPreview.limit),
      );
    });

    testWidgets('an empty preview says so rather than disappearing', (
      tester,
    ) async {
      await pump(tester, logs: const []);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.homeNothingYet), findsOneWidget);
    });

    testWidgets('every action card is the same 112px card', (tester) async {
      // Kazakh has the longest labels of the three, so if the grid is going
      // to go ragged it goes ragged here.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            localeProvider.overrideWith(
              () => LocaleChoice(const Locale('kk')),
            ),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();

      final sizes = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ActionCard),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.constraints)
          .toList();
      expect(sizes, isNotEmpty);

      for (final card in find.byType(ActionCard).evaluate()) {
        expect(tester.getSize(find.byWidget(card.widget)).height, 112);
      }
      expect(ActionCard.radius, Warm.cardRadius);
      expect(ActionCard.iconSize, 21);
    });
  });

  group('what moved to the assistant tab', () {
    Future<void> openAssistant(WidgetTester tester) async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await tester.tap(find.text(l.navAssistant).last);
      await tester.pumpAndSettle();
      // The tab is two halves now — «Справочник» is what it opens on, and
      // everything that moved off the home screen is behind «Сводка».
      await tester.tap(find.text(l.assistantViewInsights));
      await tester.pumpAndSettle();
    }

    testWidgets('is all still there', (tester) async {
      await pump(tester, size: const Size(900, 2400));
      await openAssistant(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // The switch names the half; the heading that used to repeat it is gone.
      expect(find.text(l.assistantViewInsights), findsOneWidget);
      // Each of these draws nothing when it has nothing to say, so the
      // widgets are what is asserted rather than their contents.
      expect(find.byType(PatternCard), findsOneWidget);
      expect(find.byType(ReflectionCard), findsOneWidget);
      expect(find.byType(WeeklyStoryCard), findsOneWidget);
      expect(find.byType(NowCard), findsOneWidget);
      // And the exports, which used to be reachable only from the medical
      // screen and the old dashboard.
      expect(find.text(l.reportExport), findsWidgets);
    });

    testWidgets('and none of it is on the home screen', (tester) async {
      await pump(tester, size: const Size(900, 2400));

      expect(find.byType(PatternCard), findsNothing);
      expect(find.byType(ReflectionCard), findsNothing);
      expect(find.byType(WeeklyStoryCard), findsNothing);
      expect(find.byType(NowCard), findsNothing);
    });
  });

  group('the warm palette', () {
    test('is the five colours asked for', () {
      // The page kept the warmth; the card gave it up. Everything that has
      // to be read moved as far from the page as the palette allows.
      expect(Warm.background, const Color(0xFFFAF7F4));
      expect(Warm.primaryCard, const Color(0xFFFFFFFF));
      expect(Warm.lavender, const Color(0xFFF3EAFE));
      expect(Warm.accent, const Color(0xFFE67E22));
      expect(Warm.ink, const Color(0xFF1E1A18));
      expect(Warm.inkSoft, const Color(0xFF6E645F));
    });

    test('paints the page and the greeting warm', () {
      // Asserted on the theme rather than through a running app: after nine
      // in the evening the app is in dark mode, where warm is the wrong
      // answer and dim is the right one.
      expect(AppTheme.light().scaffoldBackgroundColor, Warm.background);

      // The greeting used to end in lavender, which put the largest violet
      // surface in the app directly under the child's name.
      final gradient = AppTheme.welcomeGradient(Brightness.light);
      expect(gradient.colors, [Warm.secondaryCard, Warm.primaryCard]);
    });
  });

  group('the microanimations', () {
    test('are the four that were asked for and no others', () {
      expect(Pressable.pressedScale, 0.97);
      expect(Pressable.duration, const Duration(milliseconds: 110));
      expect(Arrival.rise, 8.0);
      expect(Arrival.duration, const Duration(milliseconds: 260));
      expect(SuccessCheck.duration, const Duration(milliseconds: 800));
      expect(MicPulse.duration, const Duration(milliseconds: 900));
    });

    testWidgets('the pulse runs only while the microphone is open', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MicPulse(listening: false, child: Icon(Icons.mic)),
          ),
        ),
      );
      // Nothing scheduled: a still frame settles, which an app with a
      // continuous animation on it never does.
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });

  group('what a parent said', () {
    ({VoiceIntent intent, VoiceCommand c}) parse(String s) {
      final c = parseVoiceCommand(s);
      return (intent: c.intent, c: c);
    }

    test('feed left fifteen minutes', () {
      final c = parseVoiceCommand('покормила левой 15 минут');
      expect(c.intent, VoiceIntent.feeding);
      expect(c.side, FeedingSide.left);
      expect(c.minutes, 15);
    });

    test('feed right twenty minutes', () {
      final c = parseVoiceCommand('feed right 20 minutes');
      expect(c.intent, VoiceIntent.feeding);
      expect(c.side, FeedingSide.right);
      expect(c.minutes, 20);
    });

    test('bottle ninety millilitres', () {
      final c = parseVoiceCommand('бутылочка 90 мл');
      expect(c.intent, VoiceIntent.bottle);
      expect(c.millilitres, 90);
      expect(c.side, FeedingSide.bottle);
    });

    test('sleep two hours', () {
      final c = parseVoiceCommand('спал 2 часа');
      expect(c.intent, VoiceIntent.sleep);
      expect(c.minutes, 120);
    });

    test('nappy wet, and nappy stool', () {
      expect(parse('подгузник мокрый').c.nappyKind, NappyKind.wet);
      expect(parse('подгузник стул').c.nappyKind, NappyKind.dirty);
      expect(parse('diaper wet').intent, VoiceIntent.nappy);
    });

    test('temperature thirty seven eight', () {
      final c = parseVoiceCommand('температура 37.8');
      expect(c.intent, VoiceIntent.temperature);
      expect(c.temperatureC, 37.8);
    });

    test('a reading is never mistaken for a volume', () {
      // "90" is millilitres and can never become 90 degrees.
      expect(parseVoiceCommand('90 мл').intent, VoiceIntent.bottle);
      expect(parseVoiceCommand('температура 90').intent, VoiceIntent.note);
    });

    test('anything else becomes a note in her own words', () {
      final c = parseVoiceCommand('первый раз улыбнулась бабушке');
      expect(c.intent, VoiceIntent.note);
      expect(c.isNote, isTrue);
      expect(c.text, 'первый раз улыбнулась бабушке');
    });

    test('the entry it becomes is the one the sheets already write', () {
      final at = DateTime(2026, 8, 5, 14);
      final feed = voiceLog(
        parseVoiceCommand('покормила левой 15 минут'),
        childId: 'c1',
        at: at,
      );
      expect(feed.type, LogType.feeding);
      expect(feed.title, LogType.feeding.label);
      expect(feed.feedingSide, FeedingSide.left);
      expect(feed.durationMinutes, 15);
      // Her words are kept whatever the reading turned out to be.
      expect(feed.description, 'покормила левой 15 минут');

      // A fever lands in the illness history exactly where a typed one does.
      final fever = voiceLog(
        parseVoiceCommand('температура 38.5'),
        childId: 'c1',
        at: at,
      );
      expect(fever.type, LogType.illness);
      expect(fever.metrics.temperatureC, 38.5);
      expect(fever.severity, Severity.moderate);

      final mild = voiceLog(
        parseVoiceCommand('температура 37.2'),
        childId: 'c1',
        at: at,
      );
      expect(mild.type, LogType.measurement);
      expect(mild.severity, isNull);
    });

    testWidgets('nothing is written until a parent taps save', (tester) async {
      // The microphone is unavailable in a test, which is the point: the
      // button is the only way in, and it opens nothing on its own.
      await pump(tester);
      expect(find.byType(VoiceActionButton), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      // A tap is not how it works, so a tap opens nothing.
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(BottomSheet), findsNothing);
    });
  });
}
