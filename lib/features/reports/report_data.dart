import '../../core/analytics/illness_stats.dart';
import '../../core/growth/who_standards.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../models/medical_record.dart';
import '../../models/reminder.dart';

/// Everything the doctor's report needs, gathered and computed before any
/// rendering happens.
///
/// Split from the PDF layout on purpose: the arithmetic — which measurements
/// count, how many illness days, which vaccinations are overdue — is the part
/// that can be wrong in a way that matters, and it is testable without
/// producing a document.
class ReportData {
  const ReportData({
    required this.child,
    required this.generatedAt,
    required this.measurements,
    required this.illnessDays,
    required this.illnessEpisodes,
    required this.records,
    required this.overdueVaccinations,
    required this.upcomingVaccinations,
    required this.milestones,
    required this.latestAssessments,
  });

  final Child child;
  final DateTime generatedAt;

  /// Measurement entries, oldest first.
  final List<DevelopmentLog> measurements;

  final int illnessDays;
  final int illnessEpisodes;
  final List<MedicalRecord> records;
  final List<Reminder> overdueVaccinations;
  final List<Reminder> upcomingVaccinations;
  final List<DevelopmentLog> milestones;

  /// WHO verdict on the most recent weight and height, where the age is
  /// inside the reference range.
  final List<GrowthAssessment> latestAssessments;

  bool get hasGrowthData => measurements.isNotEmpty;

  /// Lab results outside their reference interval, newest record first.
  List<({MedicalRecord record, LabResult result})> get abnormalLabResults => [
    for (final r in records)
      for (final l in r.labResults)
        if (l.isWithinReference == false) (record: r, result: l),
  ];
}

/// One metric assessed against the WHO reference.
class GrowthAssessment {
  const GrowthAssessment({
    required this.metric,
    required this.value,
    required this.ageMonths,
    required this.zScore,
    required this.percentile,
    required this.verdict,
    required this.measuredAt,
  });

  final GrowthMetric metric;
  final double value;
  final int ageMonths;
  final double zScore;
  final double percentile;
  final GrowthVerdict verdict;
  final DateTime measuredAt;
}

/// Assembles the report.
///
/// [now] is injectable so tests do not depend on the clock.
ReportData buildReportData({
  required Child child,
  required List<DevelopmentLog> logs,
  required List<MedicalRecord> records,
  required List<Reminder> reminders,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();

  final measurements =
      logs
          .where((l) => l.type == LogType.measurement && !l.metrics.isEmpty)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  final illnessDates = <DateTime>{
    for (final l in logs)
      if (l.type == LogType.illness) dateOnly(l.date),
  };

  final milestones =
      logs.where((l) => l.type == LogType.milestone).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  final vaccinations = reminders
      .where((r) => r.type == ReminderType.vaccination && !r.isCompleted)
      .toList();
  final overdue =
      vaccinations.where((r) => r.scheduledTime.isBefore(today)).toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  final upcoming =
      vaccinations.where((r) => !r.scheduledTime.isBefore(today)).toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

  return ReportData(
    child: child,
    generatedAt: today,
    measurements: measurements,
    illnessDays: illnessDates.length,
    illnessEpisodes: countEpisodes(illnessDates),
    records: records.toList()..sort((a, b) => b.date.compareTo(a.date)),
    overdueVaccinations: overdue,
    upcomingVaccinations: upcoming.take(5).toList(),
    milestones: milestones,
    latestAssessments: _assess(child, measurements),
  );
}

/// Delegates to the shared rule rather than restating it. The report and the
/// illness screen showing different episode counts in front of a doctor is
/// exactly the failure this prevents.
int countEpisodes(Set<DateTime> days) => countIllnessEpisodes(days);

List<GrowthAssessment> _assess(Child child, List<DevelopmentLog> measurements) {
  final result = <GrowthAssessment>[];
  for (final metric in GrowthMetric.values) {
    // Walk backwards to the most recent entry that actually carries this
    // metric — a weight-only entry must not hide the last recorded height.
    for (final log in measurements.reversed) {
      final value = switch (metric) {
        GrowthMetric.weight => log.metrics.weightKg,
        GrowthMetric.height => log.metrics.heightCm,
      };
      if (value == null) continue;

      final ageMonths = child.ageInMonthsAt(log.date);
      final z = zScore(metric, child.gender, ageMonths, value);
      // Null past 60 months: the tables stop there and extrapolating would
      // score a schoolchild against toddler norms.
      if (z == null) break;

      result.add(
        GrowthAssessment(
          metric: metric,
          value: value,
          ageMonths: ageMonths,
          zScore: z,
          percentile: percentileFromZ(z),
          verdict: verdictFromZ(z),
          measuredAt: log.date,
        ),
      );
      break;
    }
  }
  return result;
}
