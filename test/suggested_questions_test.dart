import 'package:child_health_tracker/ai/suggested_questions.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// The panel a parent sees before she has typed anything.
///
/// It used to be five fixed sentences, which is what «не вижу умного ИИ,
/// только заготовленные вопросы» was describing. What is tested here is that
/// the list now moves with the diary — and, just as much, that it stays quiet
/// when the diary says nothing.
void main() {
  final now = DateTime(2026, 8, 7, 11);

  DevelopmentLog log(
    LogType type, {
    Duration ago = const Duration(hours: 2),
    double? temperature,
    int? wakings,
    bool night = false,
  }) => DevelopmentLog(
    id: '$type$ago$temperature$wakings',
    childId: 'demo',
    date: now.subtract(ago),
    type: type,
    title: night ? 'Ночной сон' : 'x',
    durationMinutes: night ? 540 : null,
    nightWakings: wakings,
    metrics: Metrics(temperatureC: temperature),
  );

  /// An ordinary morning: something written down, nothing remarkable in it.
  List<DevelopmentLog> quietDay() => [
    log(LogType.feeding, ago: const Duration(hours: 4)),
    log(LogType.nappy, ago: const Duration(hours: 3)),
    log(LogType.feeding, ago: const Duration(hours: 1)),
  ];

  List<AskTopic> topicsFor(
    List<DevelopmentLog> logs, {
    int? ageMonths,
  }) => suggestedQuestions(logs: logs, now: now, ageMonths: ageMonths)
      .map((s) => s.topic)
      .toList();

  group('what it picks up', () {
    test("today's reading comes first", () {
      final topics = topicsFor([
        ...quietDay(),
        log(LogType.illness, ago: const Duration(hours: 2), temperature: 38.4),
      ], ageMonths: 6);

      expect(topics.first, AskTopic.temperatureToday);
    });

    test('a reading from yesterday is not today', () {
      final topics = topicsFor([
        ...quietDay(),
        log(LogType.illness, ago: const Duration(days: 1), temperature: 38.4),
      ], ageMonths: 6);

      expect(topics, isNot(contains(AskTopic.temperatureToday)));
    });

    test('a normal reading is not a question', () {
      final topics = topicsFor([
        ...quietDay(),
        log(LogType.illness, ago: const Duration(hours: 2), temperature: 36.8),
      ], ageMonths: 6);

      expect(topics, isNot(contains(AskTopic.temperatureToday)));
    });

    test('a night with five wakings in it', () {
      final topics = topicsFor([
        ...quietDay(),
        log(
          LogType.sleep,
          ago: const Duration(hours: 12),
          wakings: 5,
          night: true,
        ),
      ], ageMonths: 6);

      expect(topics, contains(AskTopic.hardNight));
    });

    test('two wakings is a night, not a subject', () {
      final topics = topicsFor([
        ...quietDay(),
        log(
          LogType.sleep,
          ago: const Duration(hours: 12),
          wakings: 2,
          night: true,
        ),
      ], ageMonths: 6);

      expect(topics, isNot(contains(AskTopic.hardNight)));
    });

    test('a day and more without a nappy written down', () {
      final topics = topicsFor([
        log(LogType.nappy, ago: const Duration(hours: 30)),
        log(LogType.feeding, ago: const Duration(hours: 2)),
      ], ageMonths: 6);

      expect(topics, contains(AskTopic.quietNappies));
    });

    test('a diary nobody has touched is not a symptom', () {
      // Everything is a day old here, the nappy included. Reading that as a
      // gap would be the app diagnosing its own silence.
      final topics = topicsFor([
        log(LogType.nappy, ago: const Duration(days: 6)),
        log(LogType.feeding, ago: const Duration(days: 5)),
      ], ageMonths: 6);

      expect(topics, isNot(contains(AskTopic.quietNappies)));
    });
  });

  group('by age', () {
    test('each stage gets its own subject', () {
      expect(topicsFor(quietDay(), ageMonths: 0), contains(
        AskTopic.newbornFeeding,
      ));
      expect(topicsFor(quietDay(), ageMonths: 3), contains(
        AskTopic.sleepNeeds,
      ));
      expect(topicsFor(quietDay(), ageMonths: 5), contains(AskTopic.solids));
      expect(topicsFor(quietDay(), ageMonths: 14), contains(
        AskTopic.milestones,
      ));
    });

    test('with no child chosen it falls back to the general list', () {
      expect(
        topicsFor(const []),
        [AskTopic.commonFever, AskTopic.commonSleep, AskTopic.commonSolids],
      );
    });
  });

  test('never more than three, however much is going on', () {
    final topics = topicsFor([
      log(LogType.nappy, ago: const Duration(hours: 30)),
      log(LogType.feeding, ago: const Duration(hours: 1)),
      log(LogType.illness, ago: const Duration(hours: 2), temperature: 38.9),
      log(
        LogType.sleep,
        ago: const Duration(hours: 12),
        wakings: 6,
        night: true,
      ),
    ], ageMonths: 6);

    expect(topics.length, maxSuggestions);
    // And the specific ones win over the age topic, which wins over the list.
    expect(topics, [
      AskTopic.temperatureToday,
      AskTopic.hardNight,
      AskTopic.quietNappies,
    ]);
  });

  group('what it says', () {
    test('the reason names the figure it was drawn from', () async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      final picks = suggestedQuestions(
        logs: [
          ...quietDay(),
          log(LogType.illness, ago: const Duration(hours: 2), temperature: 38.4),
        ],
        now: now,
        ageMonths: 6,
      );

      expect(picks.first.reason(l), contains('38.4'));
      expect(picks.first.question(l), contains('38.4'));
    });

    test('every topic has a question in every language', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        for (final topic in AskTopic.values) {
          final pick = SuggestedQuestion(topic, temperature: 38.0, wakings: 5);
          expect(
            pick.question(l),
            isNotEmpty,
            reason: '$topic in ${locale.languageCode}',
          );
        }
      }
    });

    test('the general three admit they came from nowhere', () async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      for (final topic in const [
        AskTopic.commonFever,
        AskTopic.commonSleep,
        AskTopic.commonSolids,
      ]) {
        expect(SuggestedQuestion(topic).reason(l), isNull);
      }
    });
  });
}
