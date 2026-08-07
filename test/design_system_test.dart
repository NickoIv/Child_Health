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
      expect(Warm.background, const Color(0xFFFAF7F4));
      // White, and the page warm behind it. Cream on cream was the reason
      // three passes of visual work were invisible on a phone.
      expect(Warm.primaryCard, const Color(0xFFFFFFFF));
      expect(Warm.secondaryCard, const Color(0xFFF3EEE9));
      expect(Warm.lavender, const Color(0xFFF3EAFE));
      expect(Warm.accent, const Color(0xFFE67E22));
      expect(Warm.accentSoft, const Color(0xFFE8B899));
      expect(Warm.ink, const Color(0xFF1E1A18));
      expect(Warm.inkSoft, const Color(0xFF6E645F));
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

      // The reading pair is held far above the minimum on purpose: this is
      // read one-eyed, at arm's length, in a room with the curtains shut.
      expect(ratio(Warm.ink, Warm.primaryCard), greaterThan(12));
      expect(ratio(Warm.ink, Warm.background), greaterThan(12));
      expect(ratio(Warm.inkSoft, Warm.primaryCard), greaterThan(3.0));
    });
  });

  group('the tokens', () {
    test('are four radii, three gaps and one shadow', () {
      // Each a step down from what it was: rounding that read as soft on a
      // cream rectangle reads as a bubble on a white one.
      expect(Warm.cardRadius, 22);
      expect(Warm.buttonRadius, 18);
      expect(Warm.chipRadius, 14);
      expect(Warm.dialogRadius, 26);

      expect(Warm.majorGap, 16);
      expect(Warm.cardGap, 14);
      expect(Warm.innerGap, 12);

      // Two layers: a tight one that draws the card's edge and a wide one
      // that lifts it. One wide blur on its own read as fog — everything had
      // a grey halo and nothing had an edge.
      final shadow = Warm.shadow(Brightness.light);
      expect(shadow, hasLength(2));
      expect(shadow.first.blurRadius, lessThan(4));
      expect(shadow.last.blurRadius, 22);
      expect(shadow.last.offset, const Offset(0, 8));
      // Fainter than it was, because the white card now draws its own edge
      // and the shadow only has to say which surface is on top.
      expect(shadow.last.color.a, closeTo(0.07, 0.005));
      // Dark mode gets none: a shadow on a near-black page is a smudge.
      expect(Warm.shadow(Brightness.dark), isEmpty);
    });

    test('are five type sizes and nothing between them', () {
      expect(AppTheme.headerSize, 32);
      expect(AppTheme.sectionSize, 20);
      // The fifth size, and not part of the reading scale: block labels only.
      expect(AppTheme.microSize, 11);
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
      expect(ActionCard.height, 112);
      expect(ActionCard.radius, Warm.cardRadius);
      expect(ActionCard.iconSize, 21);
      expect(ActionCard.titleSize, 17);
      expect(ActionCard.captionSize, 12);

      // Smaller than it was: the height went to the two figures under it,
      // which are what the screen is opened forty times a day to read.
      expect(WarmHeader.photoSize, 64);
      expect(VoiceActionButton.size, 64);
      expect(Warm.accentGradient.colors.last, Warm.accent);
    });

    test('the timer is mm:ss', () {
      expect(voiceTimer(Duration.zero), '00:00');
      expect(voiceTimer(const Duration(seconds: 7)), '00:07');
      expect(voiceTimer(const Duration(seconds: 65)), '01:05');
    });
  });
}
