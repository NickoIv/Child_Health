import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:child_health_tracker/features/dashboard/voice_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The design system, asserted once rather than screen by screen.
///
/// Every surface in the app is themed rather than styled in place, so these
/// are the values the whole app is redrawn from: change one here and the
/// diary, the medical card, a dialog and a bottom sheet all move together.
/// That is the point of the redesign — not that each screen was repainted,
/// but that there is now only one place to repaint them from.
void main() {
  group('the palette', () {
    test('is the eleven colours of the system', () {
      expect(Warm.background, const Color(0xFFFFF8F2));
      expect(Warm.primaryCard, const Color(0xFFFFF1E6));
      expect(Warm.secondaryCard, const Color(0xFFFFE8DA));
      expect(Warm.lavender, const Color(0xFFF7EFFF));
      expect(Warm.accent, const Color(0xFFE67E22));
      expect(Warm.accentSoft, const Color(0xFFE8B899));
      expect(Warm.ink, const Color(0xFF3B2B23));
      expect(Warm.inkSoft, const Color(0xFF8A6B5C));
      expect(Warm.success, const Color(0xFF4E8B6B));
      expect(Warm.warning, const Color(0xFFD18B2F));
      expect(Warm.danger, const Color(0xFFC96B5A));
    });

    test('reads on its own surfaces', () {
      // A warm palette is worth nothing if the text on it cannot be read.
      // 4.5:1 on the two pairs the whole app is written in.
      double luminance(Color c) => c.computeLuminance();
      double ratio(Color a, Color b) {
        final hi = luminance(a) > luminance(b) ? a : b;
        final lo = identical(hi, a) ? b : a;
        return (luminance(hi) + 0.05) / (luminance(lo) + 0.05);
      }

      expect(ratio(Warm.ink, Warm.primaryCard), greaterThan(4.5));
      expect(ratio(Warm.ink, Warm.background), greaterThan(4.5));
      expect(ratio(Warm.inkSoft, Warm.primaryCard), greaterThan(3.0));
    });
  });

  group('the tokens', () {
    test('are four radii, three gaps and one shadow', () {
      expect(Warm.cardRadius, 24);
      expect(Warm.buttonRadius, 22);
      expect(Warm.chipRadius, 16);
      expect(Warm.dialogRadius, 28);

      expect(Warm.majorGap, 16);
      expect(Warm.cardGap, 14);
      expect(Warm.innerGap, 12);

      final shadow = Warm.shadow(Brightness.light).single;
      expect(shadow.blurRadius, 24);
      expect(shadow.offset, const Offset(0, 8));
      expect(shadow.color.a, closeTo(0.08, 0.005));
      // Dark mode gets none: a shadow on a near-black page is a smudge.
      expect(Warm.shadow(Brightness.dark), isEmpty);
    });

    test('are five type sizes and nothing between them', () {
      expect(AppTheme.headerSize, 30);
      expect(AppTheme.sectionSize, 22);
      expect(AppTheme.titleSize, 17);
      expect(AppTheme.bodySize, 16);
      expect(AppTheme.secondarySize, 13);

      final text = AppTheme.light().textTheme;
      expect(text.headlineSmall!.fontWeight, FontWeight.w700);
      expect(text.titleLarge!.fontSize, AppTheme.sectionSize);
      expect(text.titleLarge!.fontWeight, FontWeight.w700);
      expect(text.titleMedium!.fontSize, AppTheme.titleSize);
      expect(text.titleMedium!.fontWeight, FontWeight.w600);
      expect(text.bodyMedium!.fontSize, AppTheme.bodySize);
      expect(text.bodySmall!.fontSize, AppTheme.secondarySize);
    });
  });

  group('every themed surface', () {
    final light = AppTheme.light();

    test('is cream and round, on every screen at once', () {
      expect(light.scaffoldBackgroundColor, Warm.background);

      final card = light.cardTheme.shape! as RoundedRectangleBorder;
      expect(light.cardTheme.color, Warm.primaryCard);
      expect(card.borderRadius, BorderRadius.circular(Warm.cardRadius));
      // No outline: the hairline was the last grey line in the app.
      expect(card.side, BorderSide.none);

      final dialog = light.dialogTheme.shape! as RoundedRectangleBorder;
      expect(light.dialogTheme.backgroundColor, Warm.primaryCard);
      expect(dialog.borderRadius, BorderRadius.circular(Warm.dialogRadius));

      expect(light.bottomSheetTheme.backgroundColor, Warm.primaryCard);
      final sheet = light.bottomSheetTheme.shape! as RoundedRectangleBorder;
      expect(
        sheet.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(Warm.dialogRadius)),
      );

      final chip = light.chipTheme.shape! as RoundedRectangleBorder;
      expect(chip.borderRadius, BorderRadius.circular(Warm.chipRadius));
      expect(light.chipTheme.backgroundColor, Warm.secondaryCard);
    });

    test('the one button style is the accent', () {
      final style = light.filledButtonTheme.style!;
      expect(
        style.backgroundColor!.resolve(const <WidgetState>{}),
        Warm.accent,
      );
      final shape =
          style.shape!.resolve(const <WidgetState>{})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(Warm.buttonRadius));
    });

    test('a divider hints rather than rules', () {
      expect(light.dividerTheme.thickness, lessThan(1));
      expect(light.dividerTheme.color!.a, lessThan(0.25));
    });
  });

  group('the pieces built on the tokens', () {
    test('agree with them', () {
      // The action cards and the microphone are the two surfaces that carry
      // their own measurements; both are drawn from the same list.
      expect(ActionCard.height, 104);
      expect(ActionCard.radius, Warm.cardRadius);
      expect(ActionCard.iconSize, 28);
      expect(ActionCard.titleSize, 16);
      expect(ActionCard.captionSize, 11.5);

      expect(WarmHeader.photoSize, 96);
      expect(VoiceActionButton.size, 72);
      expect(Warm.accentGradient.colors.last, Warm.accent);
    });

    test('the timer is mm:ss', () {
      expect(voiceTimer(Duration.zero), '00:00');
      expect(voiceTimer(const Duration(seconds: 7)), '00:07');
      expect(voiceTimer(const Duration(seconds: 65)), '01:05');
    });
  });
}
