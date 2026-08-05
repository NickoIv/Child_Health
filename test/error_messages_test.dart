import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stand-in for the exceptions cloud_firestore throws; only toString matters.
class _FakeFirestoreError {
  const _FakeFirestoreError(this.text);

  final String text;

  @override
  String toString() => text;
}

void main() {
  // Backend failures are explained in whichever language the parent reads.
  // Russian is the default install, so that is what these assert on.
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(defaultLocale);
  });

  group('friendlyError', () {
    test('recognises an index that is still building', () {
      const error = _FakeFirestoreError(
        '[cloud_firestore/failed-precondition] The query requires an index. '
        'That index is currently building and cannot be used yet.',
      );
      expect(friendlyError(l, error), contains('индексы'));
      expect(friendlyError(l, error), contains('позже'));
    });

    test('recognises a rules rejection', () {
      const error = _FakeFirestoreError(
        '[cloud_firestore/permission-denied] Missing or insufficient '
        'permissions.',
      );
      expect(friendlyError(l, error), contains('Нет доступа'));
    });

    test('recognises being offline', () {
      const error = _FakeFirestoreError(
        '[cloud_firestore/unavailable] The service is currently unavailable.',
      );
      expect(friendlyError(l, error), contains('синхронизируются'));
    });

    test('recognises an expired session', () {
      const error = _FakeFirestoreError(
        '[cloud_firestore/unauthenticated] Request had invalid credentials.',
      );
      expect(friendlyError(l, error), contains('Сессия истекла'));
    });

    test('falls back to a generic message for anything else', () {
      expect(
        friendlyError(l, const _FakeFirestoreError('something odd happened')),
        contains('обновить страницу'),
      );
    });

    test('never leaks the raw English text into the message', () {
      const error = _FakeFirestoreError(
        '[cloud_firestore/failed-precondition] The query requires an index. '
        'See its status here: https://console.firebase.google.com/v1/r/...',
      );
      final message = friendlyError(l, error);
      expect(message, isNot(contains('http')));
      expect(message, isNot(contains('cloud_firestore')));
    });
  });
}
