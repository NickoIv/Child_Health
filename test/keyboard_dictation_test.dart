import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/dashboard/ask_button.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «Микрофон не работает. Делаем к микрофону клавиатуры.»
///
/// The app had a recogniser of its own, reached through the Web Speech API,
/// and it lost sentences on the phone it was meant for: the microphone opens a
/// second or two after it is asked, a browser's recogniser is good for one run
/// per page, the plugin layer above it labels every web result partial and
/// then drops partial results, and on an iPhone opened from the home screen
/// the API is not present at all. Each of those was worked around and it still
/// did not work.
///
/// So there is no microphone in this app any more. The one on the keyboard is
/// the recogniser Apple and Google tuned for Russian and Kazakh, it is one key
/// away from any focused field, and it is already the one she uses to answer
/// messages. What the app owes her is a field with the cursor in it.
void main() {
  setUpAll(initializeDateFormatting);

  final child = Child(
    id: 'c1',
    parentUid: 'demo-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
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

  /// Any microphone the app draws itself. The keyboard's own is not a widget
  /// and cannot be found here — which is the point: it is not ours.
  Finder appMicrophone() => find.byWidgetPredicate(
    (w) =>
        w is Icon &&
        (w.icon == Icons.mic ||
            w.icon == Icons.mic_none ||
            w.icon == Icons.keyboard_voice ||
            w.icon == Icons.mic_rounded),
    description: 'a microphone drawn by the app',
  );

  testWidgets('the home screen offers a field, not a microphone', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await AppLocalizations.delegate.load(const Locale('ru'));

    expect(find.byType(AskButton), findsOneWidget);
    expect(find.text(l.homeSpeak), findsOneWidget);
    expect(appMicrophone(), findsNothing);
  });

  testWidgets('and one tap lands in the assistant with the cursor in it', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byType(AskButton));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    // Focused, so the keyboard is already up and its microphone key is one
    // press away. Two taps to start talking was the old shape and the second
    // of them bought nothing.
    expect(
      tester.widget<TextField>(field).autofocus,
      isTrue,
      reason: 'the keyboard comes up with the window',
    );
    expect(appMicrophone(), findsNothing);
  });

  testWidgets('the note in the quick sheet is a plain field too', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await AppLocalizations.delegate.load(const Locale('ru'));

    await tester.tap(find.widgetWithText(InkWell, l.quickFeed));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.quickTimeChoose));
    await tester.pumpAndSettle();

    expect(find.text(l.quickNoteOptional), findsOneWidget);
    expect(appMicrophone(), findsNothing);

    // And it still takes a note, dictated or typed — nothing downstream knows
    // or cares which.
    await tester.enterText(find.byType(TextField).first, 'Съел половину');
    await tester.pumpAndSettle();
    expect(find.text('Съел половину'), findsOneWidget);
  });
}
