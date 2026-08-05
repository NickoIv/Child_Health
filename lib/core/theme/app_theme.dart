import 'package:flutter/material.dart';

export 'palette.dart';

/// The six pastel tones the warm surfaces are built from.
///
/// Not six tints of the primary: a wall of violet in six strengths is harder
/// to tell apart than six hues, and the point of the colour on a quick action
/// is that a hand reaches for the peach one without stopping to read. They are
/// pastels rather than the categorical hues in [VizPalette] because these
/// carry no meaning — a chart series must be distinguishable, but a button
/// only has to be inviting, and saturated colour at 3am is not.
///
/// Each tone is a pair stated per mode rather than an alpha overlay: a tinted
/// white at 10% goes muddy on a dark surface, and the ink is the one thing
/// here that has to stay readable. A test holds every pair at 4.5:1.
enum SoftTone {
  peach(Color(0xFFFDEBE0), Color(0xFF8B5136), Color(0xFF3A2A22), Color(0xFFEBB999)),
  lavender(Color(0xFFEFE9FB), Color(0xFF5B4C97), Color(0xFF292338), Color(0xFFC4B8F0)),
  mint(Color(0xFFE2F4EC), Color(0xFF35705C), Color(0xFF1D302A), Color(0xFF9FD6C0)),
  rose(Color(0xFFFCE7EC), Color(0xFF94485F), Color(0xFF37232B), Color(0xFFEFAABE)),
  sky(Color(0xFFE4EFFA), Color(0xFF3D6588), Color(0xFF1F2A37), Color(0xFFA8C8E6)),
  sand(Color(0xFFF7EFE0), Color(0xFF7D6339), Color(0xFF332C20), Color(0xFFDFC79E));

  const SoftTone(this._lightFill, this._lightInk, this._darkFill, this._darkInk);

  final Color _lightFill;
  final Color _lightInk;
  final Color _darkFill;
  final Color _darkInk;

  /// The surface the tone paints.
  Color fill(Brightness b) =>
      b == Brightness.dark ? _darkFill : _lightFill;

  /// The icon and the label on top of it.
  Color ink(Brightness b) => b == Brightness.dark ? _darkInk : _lightInk;
}

/// The warm set the focus screens are built from.
///
/// Five colours, stated once. The app used to be violet with warm accents;
/// this turns that round. Violet now survives only where it means something —
/// a focused field, a selected tab — and the surfaces a parent actually looks
/// at are the colour of a lit room rather than of a product.
///
/// Light values only, deliberately: at night the app is not warm, it is dim,
/// and a peach card at 3am is the thing this palette exists to avoid.
abstract final class Warm {
  /// The page behind everything.
  static const background = Color(0xFFFFF8F2);

  /// The surface of a card. One tint for all of them: two shades of cream a
  /// few points apart read as a mistake rather than as a hierarchy, and the
  /// hierarchy on this screen is carried by size and air instead.
  static const primaryCard = Color(0xFFFFF1E6);

  /// Kept for the surfaces that sit *on* a card and need to separate from it.
  static const secondaryCard = Color(0xFFFFE8DA);

  /// The one cool note left, and the only place violet is still allowed on a
  /// warm screen — under ten percent of what is visible, by design.
  static const lavender = Color(0xFFF7EFFF);

  /// The one saturated colour: the microphone, an active icon, a live count.
  ///
  /// Strong enough to be read as a control rather than as decoration, which
  /// the old sand tint was not — and still nowhere near the red the alert
  /// surfaces own.
  static const accent = Color(0xFFE67E22);

  /// The pale version of it, for a fill behind an accent icon.
  static const accentSoft = Color(0xFFE8B899);

  /// Reading colour on any of the above.
  static const ink = Color(0xFF3B2B23);
  static const inkSoft = Color(0xFF8A6B5C);

  /// The three colours that mean something.
  ///
  /// Warm versions of the old signal set: on a cream page a pure green reads
  /// as a notification badge from a different application.
  static const success = Color(0xFF4E8B6B);
  static const warning = Color(0xFFD18B2F);
  static const danger = Color(0xFFC96B5A);

  /// The shadow every raised surface gets instead of a border.
  ///
  /// One, wide, and almost invisible - blur 24 at eight percent. On a cream
  /// page a visible shadow reads as dirt; this is only the difference between
  /// a card that sits on the page and one that is drawn on it.
  static List<BoxShadow> shadow(Brightness b) => b == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x143B2B23),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ];

  /// The four radii. Nothing in the app rounds to a number off this list.
  static const cardRadius = 24.0;
  static const buttonRadius = 22.0;
  static const chipRadius = 16.0;
  static const dialogRadius = 28.0;

  /// The three gaps: between blocks, between cards, inside one.
  static const majorGap = 16.0;
  static const cardGap = 14.0;
  static const innerGap = 12.0;

  /// The face of the microphone, and of anything else that is the one thing
  /// to press on its screen.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2A25C), accent],
  );

  /// The dark-mode counterpart of each surface, so a widget can ask for a
  /// warm colour without branching on brightness itself.
  static Color surface(Brightness b, Color light, Color dark) =>
      b == Brightness.dark ? dark : light;

  static Color card(Brightness b) =>
      surface(b, primaryCard, const Color(0xFF2A2320));

  static Color soft(Brightness b) =>
      surface(b, secondaryCard, const Color(0xFF221D1B));

  static Color onCard(Brightness b) =>
      surface(b, ink, const Color(0xFFF0E4DC));

  static Color onCardSoft(Brightness b) =>
      surface(b, inkSoft, const Color(0xFFBCA79A));
}

/// Visual language of the app.
///
/// Three rules shape everything here.
///
/// The app should feel warm enough that a tired parent wants to open it — so
/// generous rounding, pastel fills, a gradient on the surface that greets her,
/// and a colour per section of the knowledge base.
///
/// It should also feel light. Every size here is chosen against the same
/// question: does this screen ask to be read, or can it be glanced at? Hence
/// one step of type scale rather than four, twelve-pixel gaps rather than
/// sixteen, and colour that tints rather than fills.
///
/// And the alarm must stay louder than the decoration. The primary hue is
/// deliberately violet and nowhere near red or orange, so that a red element
/// on screen can only mean one thing. Emergency surfaces get none of the
/// softening applied elsewhere: no gradient, full-strength colour, heaviest
/// weight available.
abstract final class AppTheme {
  /// Soft lavender. Gentle on purpose — this is opened at 3am by someone who
  /// has not slept, and a vivid interface at that hour is an assault.
  ///
  /// Still chosen as much for what it is not: far enough from red and orange
  /// in hue that the alert colours remain unmistakable beside it. A test
  /// enforces that distance.
  static const seed = Color(0xFF9E86D8);

  /// Rounded and warm rather than the clinical default, with full Cyrillic.
  static const fontFamily = 'Nunito';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    // Applied last, and not left to ThemeData.fontFamily alone: the styles
    // below start from the default text theme, which names Roboto outright,
    // and an explicit family on a style beats the theme-wide one. Without
    // this every heading would quietly stay Roboto.
    final text = _typography(
      base.textTheme,
      scheme,
    ).apply(fontFamily: fontFamily);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: text,
      // Not white: a faint warm tint lets the cards read as raised without
      // any shadow, and is easier on the eye during a night feed.
      // Warm rather than the old violet-tinted white: the page is the largest
      // surface in the app, so it is where most of the purple used to live.
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF141110)
          : Warm.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      // Cream, round, and lifted by a shadow rather than outlined by a rule.
      // The hairline this replaces was the last grey line in the app, and
      // grey on cream is what makes a warm palette look accidental.
      cardTheme: CardThemeData(
        elevation: 0,
        color: Warm.card(brightness),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Warm.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Warm.soft(brightness),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Warm.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Tall enough to hit one-handed while holding a child.
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: isDark ? null : Warm.accent,
          foregroundColor: isDark ? null : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Warm.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: Warm.soft(brightness),
        selectedColor: Warm.accent.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Warm.chipRadius),
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Warm.onCard(brightness),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF16151C)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark
            ? const Color(0xFF16151C)
            : Colors.white,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Warm.card(brightness),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Warm.dialogRadius),
        ),
      ),
      // Sheets are where half of this app's decisions are taken, and they
      // were the last surface still painting itself the Material default.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Warm.card(brightness),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: Warm.onCardSoft(brightness).withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Warm.dialogRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      // Softer and thinner than a hair: on cream a divider hints that two
      // things are separate rather than ruling them apart.
      dividerTheme: DividerThemeData(
        color: Warm.onCardSoft(brightness).withValues(alpha: 0.18),
        space: 1,
        thickness: 0.6,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Warm.chipRadius)),
        ),
      ),
    );
  }

  /// Four sizes, and nothing between them.
  ///
  /// A screen with seven type sizes on it reads as busy however soft the
  /// colours are, because the eye has to rank them before it can read. These
  /// are the four the app actually needs: 28 for the one heading that greets,
  /// 20 for a section, 16 to read, 13 for the caption under it.
  static const headerSize = 30.0;
  static const sectionSize = 22.0;
  static const titleSize = 17.0;
  static const bodySize = 16.0;
  static const secondarySize = 13.0;

  static TextTheme _typography(TextTheme base, ColorScheme scheme) {
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: headerSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: scheme.onSurface,
      ),
      // Down from the Material 22, not up: a section heading should name the
      // block, not compete with the child's own name at the top of the page.
      titleLarge: base.titleLarge?.copyWith(
        fontSize: sectionSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: titleSize,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: titleSize,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: bodySize, height: 1.4),
      // The Material default is 14. Sixteen is the size a sentence is read at
      // rather than scanned, and most of the text in this app is a sentence
      // someone wrote about their own child.
      bodyMedium: base.bodyMedium?.copyWith(fontSize: bodySize, height: 1.4),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: secondarySize,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Gradient for welcoming surfaces. Never used on an alert.
  ///
  /// Peach into lavender, both barely there. It replaced a full-strength
  /// violet-to-tertiary ramp: that one announced itself, and what a parent
  /// opening this at 4am wants from the top of the screen is not to be
  /// announced at. The dark version is the same two hues taken down to
  /// something the eye can rest on in an unlit room.
  static LinearGradient welcomeGradient(Brightness brightness) =>
      brightness == Brightness.dark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF33262A), Color(0xFF272338)],
        )
      // Warm to warm. The old gradient ended in lavender, which put the
      // largest violet surface in the app directly under the child's name.
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Warm.secondaryCard, Warm.primaryCard],
        );

  /// Reading colour for anything sitting on [welcomeGradient].
  ///
  /// The old gradient was saturated enough to carry white text. This one is
  /// not, and white on peach is the single easiest way to make a soft palette
  /// look broken.
  static Color onWelcome(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFFF2ECEA)
      : Warm.ink;

  /// The shadow warm surfaces get instead of a border.
  ///
  /// One shadow, wide and almost invisible. Cards elsewhere use a hairline
  /// because stacked shadows on a tinted page read as grime; the greeting is
  /// the one surface allowed to lift off it.
  static List<BoxShadow> softShadow(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.35)
          : const Color(0xFF7A6A86).withValues(alpha: 0.13),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// The gap between two things that belong together.
  ///
  /// Twelve, not sixteen. Four pixels a dozen times down a scrolling page is
  /// most of the difference between a screen that feels calm and one that
  /// feels like a form.
  static const gap = 12.0;
}
