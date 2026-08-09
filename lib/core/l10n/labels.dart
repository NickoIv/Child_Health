import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/reminder.dart';
import '../growth/who_standards.dart';
import '../vaccination/national_calendar.dart';
import '../photos/compression.dart';
import '../theme/theme_mode.dart';

/// Localized names for the enums the interface shows.
///
/// Extensions rather than new fields on the enums: the codes those enums carry
/// are written to Firestore and must not move, and a model that had to be
/// handed an [AppLocalizations] to describe itself would drag the widget layer
/// into places that have no business knowing about it.
///
/// Every enum a parent can see has an entry here. The `label` fields still on
/// the models are what gets stored in a document title; they are never what is
/// drawn on screen.

/// "2 ч 15 мин" in whichever language the parent reads.
String localizedDuration(AppLocalizations l, int minutes) {
  if (minutes <= 0) return '—';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l.durationM(rest);
  if (rest == 0) return l.durationH(hours);
  return l.durationHM(hours, rest);
}

/// "1 год 3 месяца" — the first thing on the dashboard, and the line that gave
/// the app away as half-translated for longest.
String localizedAge(AppLocalizations l, Child child) {
  final months = child.ageInMonths;
  final years = months ~/ 12;
  final rest = months % 12;
  if (years == 0) return l.ageMonths(rest);
  if (rest == 0) return l.ageYears(years);
  return '${l.ageYears(years)} ${l.ageMonths(rest)}';
}

extension ThemePreferenceL10n on ThemePreference {
  String localizedLabel(AppLocalizations l) => switch (this) {
    ThemePreference.auto => l.themeAuto,
    ThemePreference.light => l.themeLight,
    ThemePreference.dark => l.themeDark,
  };

  /// With the explanation of what "automatic" means, where there is room.
  String menuLabel(AppLocalizations l) => this == ThemePreference.auto
      ? '${l.themeAuto} · ${l.themeAutoHint}'
      : localizedLabel(l);
}

extension ReminderTypeL10n on ReminderType {
  String localizedLabel(AppLocalizations l) => switch (this) {
    ReminderType.vaccination => l.reminderTypeVaccination,
    ReminderType.medication => l.reminderTypeMedication,
    ReminderType.appointment => l.reminderTypeAppointment,
  };

  /// Heading of the planner section this type gets.
  String sectionTitle(AppLocalizations l) => switch (this) {
    ReminderType.vaccination => l.remindersVaccinations,
    ReminderType.medication => l.remindersMedications,
    ReminderType.appointment => l.remindersAppointments,
  };
}

extension RecurrenceL10n on Recurrence {
  String localizedLabel(AppLocalizations l) => switch (this) {
    Recurrence.none => l.recurrenceNone,
    Recurrence.daily => l.recurrenceDaily,
    Recurrence.twiceDaily => l.recurrenceTwiceDaily,
    Recurrence.weekly => l.recurrenceWeekly,
  };
}

extension LogTypeL10n on LogType {
  String localizedLabel(AppLocalizations l) => switch (this) {
    LogType.milestone => l.logTypeMilestone,
    LogType.measurement => l.logTypeMeasurement,
    LogType.illness => l.logTypeIllness,
    LogType.feeding => l.logTypeFeeding,
    LogType.nappy => l.logTypeNappy,
    LogType.sleep => l.logTypeSleep,
    LogType.question => l.logTypeQuestion,
    LogType.note => l.logTypeNote,
  };
}

extension FeedingSideL10n on FeedingSide {
  String localizedLabel(AppLocalizations l) => switch (this) {
    FeedingSide.left => l.feedingLeft,
    FeedingSide.right => l.feedingRight,
    FeedingSide.bottle => l.feedingBottle,
    FeedingSide.solid => l.feedingSolid,
  };
}

extension NappyKindL10n on NappyKind {
  String localizedLabel(AppLocalizations l) => switch (this) {
    NappyKind.wet => l.nappyWet,
    NappyKind.dirty => l.nappyDirty,
    NappyKind.both => l.nappyBoth,
  };
}

extension SeverityL10n on Severity {
  String localizedLabel(AppLocalizations l) => switch (this) {
    Severity.mild => l.severityMild,
    Severity.moderate => l.severityModerate,
    Severity.severe => l.severitySevere,
  };
}

extension GenderL10n on Gender {
  String localizedLabel(AppLocalizations l) =>
      this == Gender.male ? l.genderMale : l.genderFemale;
}

extension UnitSystemL10n on UnitSystem {
  String localizedLabel(AppLocalizations l) =>
      this == UnitSystem.metric ? l.unitsMetric : l.unitsImperial;
}

/// The one-line recap under a routine entry: "Левая · 15 мин".
///
/// Built here rather than on the model so that the wording follows the
/// interface language instead of the language the document was written in.
String routineSummary(AppLocalizations l, DevelopmentLog log) => [
  if (log.feedingSide != null) log.feedingSide!.localizedLabel(l),
  // Her own word for it, never translated: «кабачок» is what she typed, and
  // a diary that renames a mother's food is a diary that is not hers.
  if ((log.food ?? '').trim().isNotEmpty) log.food!.trim(),
  if (log.milkMl != null) l.pumpMl(log.milkMl!),
  if (log.nappyKind != null) log.nappyKind!.localizedLabel(l),
  if (log.durationMinutes != null) localizedDuration(l, log.durationMinutes!),
  if ((log.nightWakings ?? 0) > 0) l.nightWakingsCount(log.nightWakings!),
  if ((log.nightFeeds ?? 0) > 0) l.nightFeedsCount(log.nightFeeds!),
].join(' · ');

extension GrowthMetricL10n on GrowthMetric {
  String localizedLabel(AppLocalizations l) =>
      this == GrowthMetric.weight ? l.growthWeight : l.growthHeight;
}

extension GrowthVerdictL10n on GrowthVerdict {
  String localizedLabel(AppLocalizations l) => switch (this) {
    GrowthVerdict.severelyLow => l.growthVerdictSeverelyLow,
    GrowthVerdict.low => l.growthVerdictLow,
    GrowthVerdict.normal => l.growthVerdictNormal,
    GrowthVerdict.high => l.growthVerdictHigh,
    GrowthVerdict.severelyHigh => l.growthVerdictSeverelyHigh,
  };
}

String photoProblemText(AppLocalizations l, PhotoProblem problem) =>
    problem == PhotoProblem.notAnImage
    ? l.photoNotAnImage
    : l.photoStillTooLarge;

/// What an entry is called on screen.
///
/// Titles are written into Firestore in Russian and read back from documents
/// saved years ago, so they cannot be translated in place. Everything the app
/// itself writes is recognisable — it matches the model's own wording — and
/// gets the interface language instead. Anything else is a sentence the parent
/// typed, and is shown exactly as she typed it: translating «Первое слово»
/// would be rewriting her diary.
String localizedLogTitle(AppLocalizations l, DevelopmentLog log) {
  final title = log.title.trim();

  if (title == LogTitles.medicine) return l.reminderTypeMedication;
  if (title == LogTitles.reaction) return l.logReaction;
  if (title == LogTitles.pumping) return l.pumpTitle;
  if (log.isNightSleep && title == LogType.sleep.label) {
    return l.quickNightSleep;
  }
  // "Температура 38.5 °C" — the reading is the point, the noun is not.
  if (title.startsWith(LogTitles.temperature)) {
    final value = title.substring(LogTitles.temperature.length).trim();
    return value.isEmpty
        ? l.quickSheetTemperature
        : '${l.quickSheetTemperature} $value';
  }
  if (title == log.type.label) return log.type.localizedLabel(l);

  return title;
}

/// The name of a scheduled dose.
///
/// Looked up by the slot it came from rather than by the words stored on the
/// reminder, so a plan built last year still reads in this year's language.
/// A reminder the parent wrote herself matches nothing and is left alone.
String localizedVaccinationName(AppLocalizations l, String storedName) {
  final code = vaccinationCodeFor(storedName);
  return code == null ? storedName : _vaccineName(l, code);
}

/// The note under it, with the source line the schedule appends.
String localizedVaccinationDetails(AppLocalizations l, String storedDetails) {
  if (!storedDetails.contains(vaccinationSourceMarker)) return storedDetails;

  final note = storedDetails
      .replaceAll(vaccinationSourceMarker, '')
      .replaceAll('·', '')
      .trim();
  if (note.isEmpty) return l.vaccineSource;

  final code = vaccinationCodeForNote(note);
  final localizedNote = code == null ? note : _vaccineNote(l, code) ?? note;
  return '$localizedNote · ${l.vaccineSource}';
}

String _vaccineName(AppLocalizations l, String code) => switch (code) {
  'hepB1' => l.vaccineHepB1,
  'bcg' => l.vaccineBcg,
  'penta1' => l.vaccinePenta1,
  'pcv1' => l.vaccinePcv1,
  'penta2' => l.vaccinePenta2,
  'penta3' => l.vaccinePenta3,
  'pcv2' => l.vaccinePcv2,
  'mmr1' => l.vaccineMmr1,
  'pcvBooster' => l.vaccinePcvBooster,
  'opv' => l.vaccineOpv,
  'pentaBooster' => l.vaccinePentaBooster,
  'hepA1' => l.vaccineHepA1,
  'hepA2' => l.vaccineHepA2,
  'dtapBooster' => l.vaccineDtapBooster,
  'mmr2' => l.vaccineMmr2,
  'hpv1' => l.vaccineHpv1,
  'hpv2' => l.vaccineHpv2,
  _ => l.vaccineTdBooster,
};

String? _vaccineNote(AppLocalizations l, String code) => switch (code) {
  'hepB1' => l.vaccineNoteHepB1,
  'bcg' => l.vaccineNoteBcg,
  'penta1' => l.vaccineNotePenta1,
  'mmr1' => l.vaccineNoteMmr1,
  'pentaBooster' => l.vaccineNotePentaBooster,
  'hepA1' => l.vaccineNoteHepA1,
  'hepA2' => l.vaccineNoteHepA2,
  'dtapBooster' => l.vaccineNoteDtapBooster,
  'hpv1' => l.vaccineNoteHpv1,
  'hpv2' => l.vaccineNoteHpv2,
  'tdBooster' => l.vaccineNoteTdBooster,
  _ => null,
};
