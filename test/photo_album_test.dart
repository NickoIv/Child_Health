import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/photos/photo_album.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Нужна отдельная карусель с фотографиями ребенка из записей в приложении и
/// самостоятельное добавление фотографий с датой и описанием.»
///
/// The album is not a second collection. Every photo already hangs off a diary
/// entry, and that entry already holds the day and the words — so what is
/// tested here is mostly that nothing was duplicated to make the carousel
/// work.
void main() {
  DevelopmentLog log(
    String id, {
    required DateTime date,
    List<String> photos = const [],
    LogType type = LogType.note,
    String title = 'x',
    String description = '',
  }) => DevelopmentLog(
    id: id,
    childId: 'demo',
    date: date,
    type: type,
    title: title,
    description: description,
    photos: photos,
  );

  group('what is in it', () {
    test('every photo of every entry, newest first', () {
      final album = buildAlbum([
        log('a', date: DateTime(2026, 8, 1), photos: ['p1']),
        log('c', date: DateTime(2026, 8, 5), photos: ['p3', 'p4']),
        log('b', date: DateTime(2026, 8, 3), photos: ['p2']),
      ]);

      expect(
        album.map((p) => p.photoId).toList(),
        ['p3', 'p4', 'p2', 'p1'],
      );
    });

    test('entries with no photo contribute nothing', () {
      final album = buildAlbum([
        log('a', date: DateTime(2026, 8, 1)),
        log('b', date: DateTime(2026, 8, 2), photos: ['p1']),
      ]);

      expect(album, hasLength(1));
    });

    test('a picture is dated by its entry, not by its upload', () {
      // Taken on Sunday, added on Wednesday: it belongs to Sunday, which is
      // the whole reason the sheet asks for a date.
      final sunday = DateTime(2026, 8, 2, 15, 30);
      final album = buildAlbum([
        log('a', date: sunday, photos: ['p1']),
      ]);

      expect(album.single.date, sunday);
    });

    test('it carries the words the entry already had', () {
      final album = buildAlbum([
        log(
          'a',
          date: DateTime(2026, 8, 2),
          photos: ['p1'],
          description: '  первый раз сел сам  ',
        ),
      ]);

      expect(album.single.caption, 'первый раз сел сам');
    });

    test('and the set the picture arrived in', () {
      final album = buildAlbum([
        log('a', date: DateTime(2026, 8, 2), photos: ['p1', 'p2', 'p3']),
      ]);

      // The viewer pages through the entry's own photos rather than the whole
      // album, which would put an unrelated Tuesday next to a first tooth.
      expect(album.first.album, ['p1', 'p2', 'p3']);
    });
  });

  group('a photograph added for its own sake', () {
    test('is an ordinary entry on the timeline', () {
      final entry = photoLog(
        childId: 'demo',
        date: DateTime(2026, 8, 2, 15),
        description: 'у бабушки',
        photoIds: ['p1'],
      );

      expect(entry.type, LogType.note);
      expect(entry.title, LogTitles.photo);
      expect(entry.description, 'у бабушки');
      expect(entry.photos, ['p1']);
      // Empty id: storage assigns the real one, exactly as everywhere else.
      expect(entry.id, isEmpty);
    });

    test('and only it may be deleted from the album', () {
      final own = buildAlbum([
        log(
          'a',
          date: DateTime(2026, 8, 2),
          photos: ['p1'],
          title: LogTitles.photo,
        ),
      ]).single;
      final onAFeed = buildAlbum([
        log(
          'b',
          date: DateTime(2026, 8, 2),
          photos: ['p2'],
          type: LogType.feeding,
          title: 'Кормление',
        ),
      ]).single;

      expect(own.isStandalone, isTrue);
      // Deleting a feed because you did not like the picture on it would be
      // the album deciding what the diary says.
      expect(onAFeed.isStandalone, isFalse);
    });
  });

  group('an edit', () {
    final original = DevelopmentLog(
      id: 'a',
      childId: 'demo',
      date: DateTime(2026, 8, 2),
      type: LogType.feeding,
      title: 'Кормление',
      description: 'до',
      photos: const ['p1'],
      feedingSide: FeedingSide.left,
      durationMinutes: 15,
    );

    test('replaces the three things the sheet asks about', () {
      final edited = editedPhotoLog(
        original,
        date: DateTime(2026, 8, 3, 9),
        description: '  после  ',
        photoIds: const ['p1', 'p2'],
      );

      expect(edited.date, DateTime(2026, 8, 3, 9));
      expect(edited.description, 'после');
      expect(edited.photos, ['p1', 'p2']);
    });

    test('and leaves the rest of somebody else\'s record alone', () {
      final edited = editedPhotoLog(
        original,
        date: original.date,
        description: original.description,
        photoIds: original.photos,
      );

      // The album is looking at a feeding. Correcting a caption must not lose
      // which side it was or how long it took.
      expect(edited.id, 'a');
      expect(edited.type, LogType.feeding);
      expect(edited.title, 'Кормление');
      expect(edited.feedingSide, FeedingSide.left);
      expect(edited.durationMinutes, 15);
    });

    test('it is the same entry, not a new one beside it', () {
      final edited = editedPhotoLog(
        original,
        date: original.date,
        description: 'иначе',
        photoIds: original.photos,
      );

      expect(edited.id, original.id);
    });
  });

  test('the screen is named in every language', () async {
    for (final locale in supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      expect(l.navPhotos, isNotEmpty, reason: locale.languageCode);
      expect(l.photosAdd, isNotEmpty, reason: locale.languageCode);
      expect(l.photosCount(3), contains('3'), reason: locale.languageCode);
    }
  });
}
