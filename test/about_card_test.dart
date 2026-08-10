import 'package:child_health_tracker/core/app_info.dart';
import 'package:child_health_tracker/features/shared/kazakhstan_flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Who made this and where, and the flag beside it.
void main() {
  group('the developer', () {
    test('is named, and says where he is', () {
      expect(AppInfo.author, isNotEmpty);
      expect(AppInfo.location, 'Алматы, Казахстан');
    });

    test('has a real address for feedback', () {
      expect(AppInfo.feedbackEmail, contains('@'));
    });
  });

  group('the flag', () {
    testWidgets('keeps its own proportions, whatever height it is given', (
      tester,
    ) async {
      // One to two. Anything else is a different flag, and a national flag
      // stretched to fit a row is the kind of detail people notice.
      for (final height in [13.0, 24.0, 60.0]) {
        await tester.pumpWidget(
          Center(child: KazakhstanFlag(height: height)),
        );
        expect(
          tester.getSize(find.byType(KazakhstanFlag)),
          Size(height * KazakhstanFlag.ratio, height),
        );
      }
    });

    testWidgets('paints without complaint at the size it is used', (
      tester,
    ) async {
      // Painted rather than an emoji: Windows ships no glyphs for the
      // regional-indicator pairs, so 🇰🇿 renders as the letters «KZ» in Chrome
      // on Windows — which is the machine this screen gets checked on.
      await tester.pumpWidget(const Center(child: KazakhstanFlag()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('carries the flag\'s own two colours', () {
      expect(KazakhstanFlag.sky, const Color(0xFF00AFCA));
      expect(KazakhstanFlag.gold, const Color(0xFFFEC50C));
    });
  });
}
