import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/diary/diary_screen.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nine chips over two rows became four bundles on one line. The risk that
/// swap introduces is a type falling between two bundles and quietly becoming
/// unreachable from every filter but «Все» — which is what this holds down.
void main() {
  test('every kind of entry belongs to exactly one bundle', () {
    for (final type in LogType.values) {
      final owners = DiaryFilter.values
          .where((f) => f.types.contains(type))
          .toList();

      expect(
        owners.length,
        1,
        reason: '$type is in ${owners.length} bundles, not 1',
      );
    }
  });

  test('the bundles between them hold nothing invented', () {
    for (final filter in DiaryFilter.values) {
      expect(filter.types, isNotEmpty, reason: '$filter is empty');
      for (final type in filter.types) {
        expect(LogType.values, contains(type));
      }
    }
  });

  test('matching goes by the bundle, not by one type', () {
    DevelopmentLog entry(LogType type) => DevelopmentLog(
      id: '$type',
      childId: 'demo',
      date: DateTime(2026, 8, 7),
      type: type,
      title: 'x',
    );

    // The whole point of the grouping: one tap on «Уход» keeps the feeds, the
    // nappies and the naps, which used to take three separate chips.
    expect(DiaryFilter.care.matches(entry(LogType.feeding)), isTrue);
    expect(DiaryFilter.care.matches(entry(LogType.nappy)), isTrue);
    expect(DiaryFilter.care.matches(entry(LogType.sleep)), isTrue);
    expect(DiaryFilter.care.matches(entry(LogType.illness)), isFalse);
  });

  test('each bundle is named in every language', () async {
    for (final locale in supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      final names = DiaryFilter.values.map((f) => f.localizedLabel(l)).toList();

      for (final name in names) {
        expect(name, isNotEmpty, reason: locale.languageCode);
      }
      // Four labels sitting side by side on one row have to be four different
      // words, or the row is a puzzle.
      expect(names.toSet().length, DiaryFilter.values.length,
          reason: locale.languageCode);
    }
  });
}
