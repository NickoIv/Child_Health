import '../../models/app_user.dart';

/// Display units, per requirement 2.1.
///
/// One rule governs everything here: **stored values are always metric.**
/// Kilograms and centimetres are what the WHO tables are indexed by, what the
/// PDF report states, and what a doctor reads. The imperial system exists only
/// at the edges — on screen and in the input field — and is converted on the
/// way in and out.
///
/// Storing whatever the parent happened to have selected would mean a child's
/// history silently changing meaning when the setting is flipped, and a z-score
/// computed against the wrong scale. That failure would be invisible.
abstract final class Units {
  static const _kgPerLb = 0.45359237;
  static const _cmPerIn = 2.54;

  static double kgToLb(double kg) => kg / _kgPerLb;

  static double lbToKg(double lb) => lb * _kgPerLb;

  static double cmToIn(double cm) => cm / _cmPerIn;

  static double inToCm(double inches) => inches * _cmPerIn;

  /// Label for the weight field, e.g. "кг" or "lb".
  static String weightUnit(UnitSystem system) =>
      system == UnitSystem.imperial ? 'lb' : 'кг';

  static String heightUnit(UnitSystem system) =>
      system == UnitSystem.imperial ? 'in' : 'см';

  /// Converts a stored (metric) weight into the number to display.
  static double weightToDisplay(double kg, UnitSystem system) =>
      system == UnitSystem.imperial ? kgToLb(kg) : kg;

  static double heightToDisplay(double cm, UnitSystem system) =>
      system == UnitSystem.imperial ? cmToIn(cm) : cm;

  /// Converts a number the parent typed into the metric value to store.
  static double weightToStorage(double entered, UnitSystem system) =>
      system == UnitSystem.imperial ? lbToKg(entered) : entered;

  static double heightToStorage(double entered, UnitSystem system) =>
      system == UnitSystem.imperial ? inToCm(entered) : entered;

  /// "9.6 кг" / "21.2 lb".
  static String formatWeight(
    double kg,
    UnitSystem system, {
    int decimals = 1,
  }) =>
      '${weightToDisplay(kg, system).toStringAsFixed(decimals)} '
      '${weightUnit(system)}';

  static String formatHeight(
    double cm,
    UnitSystem system, {
    int decimals = 1,
  }) =>
      '${heightToDisplay(cm, system).toStringAsFixed(decimals)} '
      '${heightUnit(system)}';

  /// Temperature stays Celsius in both systems.
  ///
  /// Deliberate: every threshold in the knowledge base, the triage rules and
  /// the WHO material is stated in Celsius, and a converted number beside an
  /// unconverted rule is how a parent misreads a fever.
  static String formatTemperature(double celsius) =>
      '${celsius.toStringAsFixed(1)} °C';
}
