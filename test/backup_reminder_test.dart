import 'package:child_health_tracker/core/care/backup_reminder.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/dashboard/backup_reminder_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Выгрузка должна перестать быть кнопкой и стать привычкой.»
///
/// The export has lived in settings, which means it has been used by the
/// people who already knew they wanted it. That is survivable while the diary
/// also sits on a server; it stops being survivable the moment the phone is
/// the only place it lives, and that is the direction being considered.
///
/// Most of what is tested here is the asking that must *not* happen. A card
/// that appears too early, or again the next morning, is a card that teaches
/// people to dismiss it without reading — and the time this one matters is a
/// year from now.
void main() {
  final at = DateTime(2026, 8, 13, 21);

  group('when it asks', () {
    test('never before there is something to lose', () {
      // «Save a copy» of an empty diary is a prompt whose honest answer is
      // «of what».
      expect(backupDue(entries: 0, now: at), isFalse);
      expect(backupDue(entries: backupMinEntries - 1, now: at), isFalse);
      expect(backupDue(entries: backupMinEntries, now: at), isTrue);
    });

    test('once there is, and no copy has ever been made', () {
      expect(backupDue(entries: 60, now: at, lastBackup: null), isTrue);
    });

    test('and a month after the last one, not a day', () {
      final saved = at.subtract(const Duration(days: 3));
      expect(backupDue(entries: 60, now: at, lastBackup: saved), isFalse);

      final old = at.subtract(backupInterval);
      expect(backupDue(entries: 60, now: at, lastBackup: old), isTrue);
    });

    test('a copy made just now silences it immediately', () {
      // The export records the moment it succeeds, so the card is gone on the
      // next build without anybody telling it.
      expect(backupDue(entries: 500, now: at, lastBackup: at), isFalse);
    });
  });

  group('«позже»', () {
    test('holds for a week, not until tomorrow', () {
      final until = at.add(backupSnooze);
      expect(
        backupDue(entries: 60, now: at.add(const Duration(days: 1)),
            snoozedUntil: until),
        isFalse,
      );
      expect(
        backupDue(entries: 60, now: at.add(const Duration(days: 6)),
            snoozedUntil: until),
        isFalse,
      );
      expect(
        backupDue(entries: 60, now: at.add(const Duration(days: 8)),
            snoozedUntil: until),
        isTrue,
      );
    });

    test('and a week is long enough to be a decision, not a reflex', () {
      expect(backupSnooze.inDays, greaterThanOrEqualTo(7));
      expect(backupInterval.inDays, greaterThanOrEqualTo(28));
    });
  });

  group('the wording', () {
    test('exists in all three languages', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        for (final s in [l.backupRemindTitle, l.backupRemindBody]) {
          expect(s.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('says where the copy goes, because that is the worry', () async {
      // A prompt to «save your data» in a health app reads as an upload
      // unless it says otherwise. Nothing leaves the phone.
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(ru.backupRemindBody, contains('никуда не отправляется'));
    });

    test('and does not count anything at the parent', () async {
      // No streaks, no «you have not saved for 47 days». See the tone the
      // rest of the app keeps.
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(RegExp(r'\d').hasMatch(ru.backupRemindTitle), isFalse);
    });
  });

  test('the card is exported for the home screen to pick', () {
    // A compile-time check that the widget the picker names is the one this
    // file is about.
    expect(const BackupReminderCard().now, isNull);
  });
}
