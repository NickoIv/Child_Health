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
  peach(Color(0xFFFBE0D0), Color(0xFF7A4225), Color(0xFF3A2A22), Color(0xFFEBB999)),
  lavender(Color(0xFFEDE3FA), Color(0xFF4E3F8A), Color(0xFF292338), Color(0xFFC4B8F0)),
  mint(Color(0xFFD3EFE0), Color(0xFF27614E), Color(0xFF1D302A), Color(0xFF9FD6C0)),
  rose(Color(0xFFFBDCE7), Color(0xFF853A52), Color(0xFF37232B), Color(0xFFEFAABE)),
  sky(Color(0xFFDCEAF9), Color(0xFF33587A), Color(0xFF1F2A37), Color(0xFFA8C8E6)),
  sand(Color(0xFFF7EFCC), Color(0xFF6B542C), Color(0xFF332C20), Color(0xFFDFC79E));

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
  ///
  /// Still warm, but two steps back from the cream it was: the page's job is
  /// to be the thing a card is *not*, and at #FFF8F2 it was the same colour
  /// as the card with a different name. Every card edge in the app exists
  /// because of this one value.
  static const background = Color(0xFFFAF7F4);

  /// The surface of a card. White, and white on purpose: cream on cream is
  /// what made three passes of visual work invisible. The warmth stayed in
  /// the page, where it is the largest surface and costs nothing to read.
  static const primaryCard = Color(0xFFFFFFFF);

  /// Kept for the surfaces that sit *on* a card and need to separate from it —
  /// a text field, a chip, a filter. Warm grey rather than deeper cream: on
  /// white, cream reads as a stain rather than as a second level.
  static const secondaryCard = Color(0xFFF3EEE9);

  /// The one cool note left, and the only place violet is still allowed on a
  /// warm screen — under ten percent of what is visible, by design.
  static const lavender = Color(0xFFF3EAFE);

  /// The one saturated colour: the microphone, an active icon, a live count.
  ///
  /// Strong enough to be read as a control rather than as decoration, which
  /// the old sand tint was not — and still nowhere near the red the alert
  /// surfaces own.
  static const accent = Color(0xFFE67E22);

  /// The pale version of it, for a fill behind an accent icon.
  static const accentSoft = Color(0xFFE8B899);

  /// The same orange, taken down until it can be read.
  ///
  /// [accent] against white is 2.85:1 — below the 4.5:1 a sentence needs and
  /// below even the 3:1 an icon needs. That was true in both directions: white
  /// on the «Сохранить» button, and the orange label of the selected tab on a
  /// white bar. Both are the same measurement, because both are a contrast
  /// against white, so one darker orange fixes both.
  ///
  /// Taken down far enough to clear 4.5:1 on all three light surfaces, not
  /// just on white: the page and the soft card are warm, and an orange that
  /// passes on white alone fails by the width of a hair on the page it is
  /// actually printed on.
  ///
  /// Same hue as [accent] to within a degree, so nothing changes colour —
  /// only the pale end of it is gone from anything carrying meaning. [accent]
  /// keeps the fills, the washes and the halos, where there is nothing to read.
  static const accentInk = Color(0xFFA8570B);

  /// The accent to paint text or a glyph in, given the surface under it.
  ///
  /// Light needs [accentInk]; in the dark the pale one is already 5.9:1 on the
  /// card and the dark one would disappear into it.
  static Color accentOn(Brightness b) => b == Brightness.dark ? accent : accentInk;

  /// Reading colour on any of the above.
  ///
  /// Near-black with a grain of warmth left in it. The old #3B2B23 was brown,
  /// and brown text sat at 9:1 where this sits at 15:1 — the difference is
  /// whether a sentence can be read at arm's length with one eye open.
  static const ink = Color(0xFF1E1A18);

  /// The second line. Warm grey rather than the old brown #75574A: on white
  /// a brown second line competes with the accent for attention it does not
  /// want, and this one simply steps back.
  static const inkSoft = Color(0xFF6E645F);

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
          // Two, not one. A single wide blur at eight percent read as fog
          // rather than as lift: everything on the page had a soft grey halo
          // and nothing had an edge. The tight one draws the edge, the wide
          // one does the lifting.
          //
          // Both moved closer and darker with the white card: on cream the
          // shadow was the only thing separating card from page and had to
          // spread to be seen at all; on white the edge does that work, and
          // the shadow only has to say which of the two is on top.
          BoxShadow(
            color: Color(0x0F1E1A18),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x121E1A18),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ];

  /// The four radii. Nothing in the app rounds to a number off this list.
  ///
  /// All four came down a step when the cards went white: rounding that read
  /// as soft on a cream rectangle reads as a bubble on a white one.
  static const cardRadius = 22.0;
  static const buttonRadius = 18.0;
  static const chipRadius = 14.0;
  static const dialogRadius = 26.0;

  /// The three gaps: between blocks, between cards, inside one.
  static const majorGap = 16.0;
  static const cardGap = 14.0;
  static const innerGap = 12.0;

  /// The face of the microphone, and of anything else that is the one thing
  /// to press on its screen.
  /// It runs from the accent into [accentInk] rather than from a pale peach
  /// into the accent: the disc carries a white glyph, and on the old light end
  /// that glyph sat at 2.1:1. It now crosses the middle of the disc at about
  /// 3.5:1, which is the bar for a shape rather than for a sentence.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentInk],
  );

  /// The dark-mode counterpart of each surface, so a widget can ask for a
  /// warm colour without branching on brightness itself.
  static Color surface(Brightness b, Color light, Color dark) =>
      b == Brightness.dark ? dark : light;

  static Color card(Brightness b) =>
      surface(b, primaryCard, const Color(0xFF1E1C1B));

  /// Lighter than the card in the dark, darker than it in the light. A field
  /// sits *in* a card, and in an unlit room "in" is drawn by going up.
  static Color soft(Brightness b) =>
      surface(b, secondaryCard, const Color(0xFF2A2724));

  static Color onCard(Brightness b) =>
      surface(b, ink, const Color(0xFFEDE9E5));

  static Color onCardSoft(Brightness b) =>
      surface(b, inkSoft, const Color(0xFFA69E97));

  /// The line between two rows of the same list.
  ///
  /// Not a divider between blocks — those are drawn by space. This is what
  /// keeps eight events in one card from reading as one paragraph.
  static Color hairline(Brightness b) =>
      onCard(b).withValues(alpha: b == Brightness.dark ? 0.10 : 0.07);
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
          ? const Color(0xFF121110)
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
        // Not zero, and not transparent. Both were, which meant every bare
        // [Card] in the app — the chat bubbles, the article tiles, the triage
        // card, nine of them — drew a white rectangle on a nearly white page
        // with nothing between the two. [Warm.shadow] was reaching only the
        // surfaces that build their own Container.
        //
        // [SectionCard] paints the tuned two-layer shadow itself; this is what
        // everything else gets, and it is deliberately the same weight. In the
        // dark there is no shadow at all — a shadow under a dark card on a
        // darker page is invisible, and the card colour does the separating.
        // Zero, and it has to stay zero. Material's elevation shadow on a
        // 22px radius draws a hard grey ring rather than a lift — tried at
        // three and at seven, and both read as a border round every card on a
        // cream page. What raises a surface here is [AppCard], which paints
        // [Warm.shadow] itself; a bare [Card] draws nothing, which is why the
        // feature code no longer contains one and a test keeps it that way.
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
          borderSide: BorderSide(color: Warm.accentOn(brightness), width: 2),
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
          // The deep orange, not the bright one: white on the bright accent
          // was 2.85:1, and this button is where a record is saved.
          backgroundColor: isDark ? null : Warm.accentInk,
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
      // A filter that is on has to be legible from a metre away, and a pale
      // orange wash was not it: on a bright screen the selected chip and the
      // eleven beside it were the same rectangle. Selected is now the ink
      // itself, which is the strongest thing the palette owns short of the
      // alert colours.
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: Warm.soft(brightness),
        selectedColor: isDark ? Warm.accent : Warm.ink,
        checkmarkColor: isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Warm.chipRadius),
        ),
        // A [WidgetStateTextStyle] here was the black-on-black bug he reported
        // twice. A chip merges the theme's label style into its own defaults as
        // an ordinary [TextStyle] and then resolves the *colour* alone — so a
        // style whose state-dependence lives in `resolve()` is flattened to its
        // base, which for `resolveWith` carries no colour at all. The label
        // then fell back to the dark ink meant for an unselected chip and was
        // painted on the near-black fill meant to carry white.
        //
        // The state has to live in the colour itself, which is the one thing a
        // chip does resolve. Selectable controls are [ChoicePill] now and none
        // of this is load-bearing, but the next chip added should not have to
        // rediscover it.
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (isDark ? Colors.black : Colors.white)
                : Warm.onCard(brightness),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1A1817)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        // The accent, not the violet container. The tab bar is the one piece
        // of chrome visible on every screen, and a violet pill under an
        // orange app was the last thing left over from the old palette.
        indicatorColor: Warm.accent.withValues(alpha: isDark ? 0.22 : 0.14),
        elevation: 0,
        height: 68,
        // Selected reads as selected in weight and colour as well as by the
        // pill behind it: at 11px the pill alone is doing all the work, and
        // in a dark room it is the first thing to disappear.
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  // Eleven pixels of orange on a white bar: the pale accent
                  // read at 2.85:1 here, which is the label a parent uses to
                  // know where in the app she is.
                  color: isDark ? const Color(0xFFF2A25C) : Warm.accentInk,
                )
              : TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Warm.onCardSoft(brightness),
                ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1A1817)
            : Colors.white,
        indicatorColor: Warm.accent.withValues(alpha: isDark ? 0.22 : 0.14),
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
      // A confirmation has to be seen from across a room by someone who is
      // not looking at the phone. On a cream page the Material default was a
      // slightly darker cream rectangle; this is the one dark surface in the
      // light theme, and that is the whole reason it registers.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B2623),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: Color(0xFFF7F2EE),
        ),
        actionTextColor: const Color(0xFFF2A25C),
        actionBackgroundColor: Colors.transparent,
        elevation: 8,
        insetPadding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
  static const headerSize = 32.0;
  static const sectionSize = 20.0;
  static const titleSize = 17.0;
  static const bodySize = 16.0;
  static const secondarySize = 13.0;

  /// The fifth, and it is not part of the reading scale.
  ///
  /// Small caps over a block — «ПОСЛЕДНИЕ СОБЫТИЯ» — and nothing else. It is
  /// a sign that says where a block starts, which is the one job the section
  /// headings inside the cards could not do: a heading printed on the card it
  /// belongs to cannot mark the card's edge.
  static const microSize = 11.0;

  /// Digits that line up in a column.
  ///
  /// Times, weights and durations are read down a list rather than along a
  /// line, and proportional digits make a column of them wobble. Applied at
  /// every number the app prints beside another number.
  static const tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// The style small-caps labels are set in, so there is one of them.
  static TextStyle microLabel(Brightness brightness) => TextStyle(
    fontFamily: fontFamily,
    fontSize: microSize,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.3,
    color: Warm.onCardSoft(brightness),
  );

  static TextTheme _typography(TextTheme base, ColorScheme scheme) {
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: headerSize,
        fontWeight: FontWeight.w700,
        // Tighter as it got bigger: at 32 the default tracking opens gaps
        // between letters that read as a logo rather than as a name.
        letterSpacing: -0.9,
        height: 1.08,
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
      // The two label sizes are where the app prints a time or a date beside
      // another one, so they carry the tabular figures by default rather than
      // by each caller remembering to ask.
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: tabular,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: tabular,
      ),
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
