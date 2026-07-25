import 'package:child_health_tracker/core/growth/who_standards.dart';
import 'package:child_health_tracker/features/reports/medical_report.dart';
import 'package:child_health_tracker/features/reports/report_data.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/medical_record.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 7, 25);

Child _child({int ageMonths = 12}) => Child(
  id: 'c1',
  parentUid: 'p1',
  name: 'Тест',
  birthDate: DateTime(_now.year, _now.month - ageMonths, _now.day),
  gender: Gender.male,
);

DevelopmentLog _log(
  LogType type,
  DateTime date, {
  Metrics metrics = const Metrics(),
  String title = 'Запись',
}) => DevelopmentLog(
  id: '${type.code}-${date.millisecondsSinceEpoch}',
  childId: 'c1',
  date: date,
  type: type,
  title: title,
  metrics: metrics,
);

Reminder _vaccination(String title, DateTime when, {bool done = false}) =>
    Reminder(
      id: title,
      childId: 'c1',
      type: ReminderType.vaccination,
      title: title,
      scheduledTime: when,
      isCompleted: done,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the rendered document', () {
    test('produces a valid PDF with the Cyrillic font embedded', () async {
      // The built-in PDF fonts have no Cyrillic glyphs, so a missing asset
      // would silently yield a blank report rather than an error.
      final data = buildReportData(
        child: _child(),
        logs: [
          _log(
            LogType.measurement,
            _now,
            metrics: const Metrics(weightKg: 9.6, heightCm: 75.7),
          ),
          _log(LogType.illness, DateTime(2026, 7, 20), title: 'ОРВИ'),
          _log(LogType.milestone, DateTime(2026, 6, 1), title: 'Первое слово'),
        ],
        records: [
          MedicalRecord(
            id: 'm1',
            childId: 'c1',
            date: DateTime(2026, 6, 1),
            diagnosis: 'ОРВИ, неосложнённое течение',
            prescriptions: 'Обильное питьё',
            labResults: const [
              LabResult(
                name: 'Гемоглобин',
                value: 95,
                unit: 'г/л',
                referenceMin: 110,
                referenceMax: 140,
              ),
            ],
          ),
        ],
        reminders: [_vaccination('АбКДС', DateTime(2026, 5, 1))],
        now: _now,
      );

      final bytes = await buildMedicalReport(data);

      // %PDF- magic.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

      // Assert the font itself, not the file size. Only the glyphs actually
      // used get embedded, so a Russian report is far smaller than a naive
      // size threshold would suggest — an earlier version of this test failed
      // on a perfectly good 19 KB document. The font descriptor names the
      // face in clear text, which is the thing worth checking: without it the
      // built-in fonts take over and every Cyrillic character renders blank.
      final asLatin1 = String.fromCharCodes(bytes);
      expect(
        asLatin1,
        contains('Roboto'),
        reason: 'the Cyrillic-capable font must be embedded',
      );
      expect(bytes.length, greaterThan(10000));
    });

    test('renders when there is almost nothing to report', () async {
      final bytes = await buildMedicalReport(
        buildReportData(
          child: _child(),
          logs: const [],
          records: const [],
          reminders: const [],
          now: _now,
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('countEpisodes', () {
    test('an empty set has no episodes', () {
      expect(countEpisodes({}), 0);
    });

    test('consecutive days are one episode', () {
      expect(
        countEpisodes({
          DateTime(2026, 7, 1),
          DateTime(2026, 7, 2),
          DateTime(2026, 7, 3),
        }),
        1,
      );
    });

    test('a gap of more than two clear days starts a new episode', () {
      expect(
        countEpisodes({
          DateTime(2026, 7, 1),
          DateTime(2026, 7, 2),
          DateTime(2026, 7, 20),
        }),
        2,
      );
    });

    test('a two-day gap is still the same episode', () {
      // Matches the illness screen exactly, so the report never contradicts
      // what the app shows.
      expect(
        countEpisodes({DateTime(2026, 7, 1), DateTime(2026, 7, 3)}),
        1,
      );
    });
  });

  group('buildReportData', () {
    test('counts distinct illness days, not entries', () {
      // Two entries on the same day is one sick day.
      final data = buildReportData(
        child: _child(),
        logs: [
          _log(LogType.illness, DateTime(2026, 7, 20, 9)),
          _log(LogType.illness, DateTime(2026, 7, 20, 21)),
          _log(LogType.illness, DateTime(2026, 7, 21)),
        ],
        records: const [],
        reminders: const [],
        now: _now,
      );
      expect(data.illnessDays, 2);
      expect(data.illnessEpisodes, 1);
    });

    test('measurements come out oldest first', () {
      final data = buildReportData(
        child: _child(),
        logs: [
          _log(
            LogType.measurement,
            DateTime(2026, 7, 20),
            metrics: const Metrics(weightKg: 10),
          ),
          _log(
            LogType.measurement,
            DateTime(2026, 1, 10),
            metrics: const Metrics(weightKg: 8),
          ),
        ],
        records: const [],
        reminders: const [],
        now: _now,
      );
      expect(data.measurements.first.date, DateTime(2026, 1, 10));
      expect(data.measurements.last.date, DateTime(2026, 7, 20));
    });

    test('measurements with no metrics are excluded', () {
      final data = buildReportData(
        child: _child(),
        logs: [_log(LogType.measurement, DateTime(2026, 7, 20))],
        records: const [],
        reminders: const [],
        now: _now,
      );
      expect(data.measurements, isEmpty);
      expect(data.hasGrowthData, isFalse);
    });

    test('splits vaccinations into overdue and upcoming', () {
      final data = buildReportData(
        child: _child(),
        logs: const [],
        records: const [],
        reminders: [
          _vaccination('просрочена', DateTime(2026, 5, 1)),
          _vaccination('предстоит', DateTime(2026, 9, 1)),
          _vaccination('сделана', DateTime(2026, 4, 1), done: true),
        ],
        now: _now,
      );
      expect(data.overdueVaccinations.map((r) => r.title), ['просрочена']);
      expect(data.upcomingVaccinations.map((r) => r.title), ['предстоит']);
    });

    test('collects lab results that fall outside their reference', () {
      final data = buildReportData(
        child: _child(),
        logs: const [],
        records: [
          MedicalRecord(
            id: 'm1',
            childId: 'c1',
            date: DateTime(2026, 6, 1),
            diagnosis: 'ОРВИ',
            labResults: const [
              LabResult(
                name: 'Гемоглобин',
                value: 95,
                unit: 'г/л',
                referenceMin: 110,
                referenceMax: 140,
              ),
              LabResult(
                name: 'Лейкоциты',
                value: 8,
                unit: '',
                referenceMin: 6,
                referenceMax: 12,
              ),
            ],
          ),
        ],
        reminders: const [],
        now: _now,
      );
      expect(data.abnormalLabResults, hasLength(1));
      expect(data.abnormalLabResults.first.result.name, 'Гемоглобин');
    });
  });

  group('growth assessment in the report', () {
    test('assesses the latest weight and height', () {
      final child = _child(ageMonths: 12);
      final data = buildReportData(
        child: child,
        logs: [
          _log(
            LogType.measurement,
            _now,
            metrics: const Metrics(weightKg: 9.6, heightCm: 75.7),
          ),
        ],
        records: const [],
        reminders: const [],
        now: _now,
      );

      expect(data.latestAssessments, hasLength(2));
      final weight = data.latestAssessments.firstWhere(
        (a) => a.metric == GrowthMetric.weight,
      );
      // Almost exactly the WHO median for a 12-month-old boy.
      expect(weight.zScore, closeTo(0, 0.1));
      expect(weight.verdict, GrowthVerdict.normal);
    });

    test('a weight-only entry does not hide the last recorded height', () {
      // The most recent entry has no height; the assessment must fall back
      // to the previous one rather than dropping height entirely.
      final child = _child(ageMonths: 12);
      final data = buildReportData(
        child: child,
        logs: [
          _log(
            LogType.measurement,
            _now.subtract(const Duration(days: 60)),
            metrics: const Metrics(heightCm: 72.0),
          ),
          _log(
            LogType.measurement,
            _now,
            metrics: const Metrics(weightKg: 9.6),
          ),
        ],
        records: const [],
        reminders: const [],
        now: _now,
      );

      expect(
        data.latestAssessments.map((a) => a.metric),
        containsAll(GrowthMetric.values),
      );
    });

    test('a child past the reference range is not assessed', () {
      final child = _child(ageMonths: 96);
      final data = buildReportData(
        child: child,
        logs: [
          _log(
            LogType.measurement,
            _now,
            metrics: const Metrics(weightKg: 26, heightCm: 128),
          ),
        ],
        records: const [],
        reminders: const [],
        now: _now,
      );
      expect(
        data.latestAssessments,
        isEmpty,
        reason: 'the WHO tables stop at 60 months and must not be extrapolated',
      );
      expect(data.measurements, isNotEmpty, reason: 'the data is still shown');
    });
  });
}
