import 'package:flutter/material.dart';

/// Colours that carry meaning, kept apart from colours that are decoration.
///
/// The app chrome is free to be warm and colourful — it is for a tired parent
/// who should want to open it. These values are not: they encode state and
/// identity, and they were checked with the data-viz validator rather than
/// chosen by eye. The ordering of [categorical] in particular is a
/// colour-blindness safety mechanism, not an aesthetic choice: an earlier
/// ordering put magenta next to orange and failed the normal-vision floor.
///
/// Verified in both modes: worst adjacent CVD ΔE 9.1 light / 8.4 dark,
/// worst adjacent normal-vision ΔE 19.6 light / 19.3 dark.
abstract final class VizPalette {
  /// Categorical hues in validated order. Assign in order, never cycle.
  static const categorical = <Color>[
    Color(0xFF2A78D6), // blue
    Color(0xFFEB6834), // orange
    Color(0xFF1BAF7A), // aqua
    Color(0xFFEDA100), // yellow
    Color(0xFFE87BA4), // magenta
    Color(0xFF008300), // green
    Color(0xFF4A3AA7), // violet
    Color(0xFFE34948), // red
  ];

  /// The same hues stepped for a dark surface — not a different palette.
  static const categoricalDark = <Color>[
    Color(0xFF3987E5),
    Color(0xFFD95926),
    Color(0xFF199E70),
    Color(0xFFC98500),
    Color(0xFFD55181),
    Color(0xFF008300),
    Color(0xFF9085E9),
    Color(0xFFE66767),
  ];

  static List<Color> categoricalFor(Brightness brightness) =>
      brightness == Brightness.dark ? categoricalDark : categorical;

  /// Slot [index], folded back into range rather than generating a new hue.
  static Color slot(int index, Brightness brightness) {
    final list = categoricalFor(brightness);
    return list[index % list.length];
  }

  // --- Chart chrome. Reference curves are chrome, not a second series. ---

  static const gridLight = Color(0xFFE1E0D9);
  static const gridDark = Color(0xFF2C2C2A);
  static const axisLight = Color(0xFFC3C2B7);
  static const axisDark = Color(0xFF383835);
  static const muted = Color(0xFF898781);

  static Color grid(Brightness b) =>
      b == Brightness.dark ? gridDark : gridLight;

  static Color axis(Brightness b) =>
      b == Brightness.dark ? axisDark : axisLight;
}

/// Status colours — fixed, never themed, never reused for a data series.
///
/// Warning and serious sit below 3:1 on a light surface by design. The
/// mitigation is the icon-plus-label pairing used everywhere they appear:
/// a status colour never carries meaning on its own.
abstract final class StatusColors {
  static const normal = Color(0xFF0CA30C);
  static const warning = Color(0xFFFAB219);
  static const serious = Color(0xFFEC835A);
  static const alert = Color(0xFFD03B3B);
  static const neutral = VizPalette.muted;

  static Color forSeverityIndex(int index) => switch (index) {
    0 => warning,
    1 => serious,
    _ => alert,
  };
}
