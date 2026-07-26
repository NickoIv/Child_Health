import 'package:flutter/material.dart';

export 'palette.dart';

/// Visual language of the app.
///
/// Two rules shape everything here.
///
/// The app should feel warm enough that a tired parent wants to open it — so
/// generous rounding, soft tints, gradients on the welcoming surfaces, and a
/// colour per section of the knowledge base.
///
/// And the alarm must stay louder than the decoration. The primary hue is
/// deliberately violet and nowhere near red or orange, so that a red element
/// on screen can only mean one thing. Emergency surfaces get none of the
/// softening applied elsewhere: no gradient, full-strength colour, heaviest
/// weight available.
abstract final class AppTheme {
  /// Warm violet. Chosen as much for what it is not — the alert colours must
  /// remain unmistakable beside it.
  static const seed = Color(0xFF6750E8);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final text = _typography(base.textTheme, scheme);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: text,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F0E14)
          : const Color(0xFFF7F5FB),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          // A hairline instead of a shadow: cards sit on a tinted page, and
          // stacked shadows there read as grime rather than depth.
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
          borderSide: BorderSide(color: scheme.primary, width: 2),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    );
  }

  static TextTheme _typography(TextTheme base, ColorScheme scheme) {
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
      bodySmall: base.bodySmall?.copyWith(height: 1.4),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Gradient for welcoming surfaces. Never used on an alert.
  static LinearGradient welcomeGradient(ColorScheme scheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      scheme.primary,
      Color.lerp(scheme.primary, scheme.tertiary, 0.55) ?? scheme.primary,
    ],
  );
}
