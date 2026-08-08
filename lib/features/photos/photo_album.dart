import '../../models/development_log.dart';

/// One photograph, with the entry it belongs to.
///
/// The album is not a second collection. Every photo in this app already hangs
/// off a diary entry — the first tooth, the rash somebody wanted to show a
/// doctor, the Tuesday afternoon — and that entry is where its date and its
/// words already live. Building the album from the diary rather than beside it
/// means a caption corrected here is corrected there, and a photo added here
/// appears in the feed the way every other record does.
class AlbumPhoto {
  const AlbumPhoto({required this.photoId, required this.log});

  final String photoId;

  /// The entry that carries it. Its date is when the picture is from, and its
  /// description is what she wrote about it.
  final DevelopmentLog log;

  DateTime get date => log.date;

  String get caption => log.description.trim();

  /// True for an entry made *of* the photograph rather than one that happens
  /// to have a photograph on it. Only these can be deleted from the album
  /// outright — removing a feed because you did not like the picture would be
  /// the album deciding what the diary says.
  bool get isStandalone =>
      log.type == LogType.note && log.title == LogTitles.photo;

  /// All the photos on that entry, so the viewer can page through the set the
  /// picture came in rather than through the whole album.
  List<String> get album => log.photos;
}

/// Every photograph in the diary, newest first.
///
/// Ordered by the entry's date rather than by upload time: a picture taken on
/// Sunday and added on Wednesday belongs to Sunday, which is the whole reason
/// the sheet asks for a date at all.
List<AlbumPhoto> buildAlbum(List<DevelopmentLog> logs) {
  final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
  return [
    for (final log in sorted)
      for (final id in log.photos) AlbumPhoto(photoId: id, log: log),
  ];
}

/// The entry an edit produces, from the one that was there.
///
/// Only the three things the sheet asks about are replaced. Everything else
/// the entry was — a feeding side, a temperature, a milestone's title — is
/// carried through untouched, because the album is looking at somebody else's
/// record and has no business rewriting the rest of it.
///
/// Lifted out of the widget so what gets written can be read without building
/// a screen.
DevelopmentLog editedPhotoLog(
  DevelopmentLog original, {
  required DateTime date,
  required String description,
  required List<String> photoIds,
}) => original.copyWith(
  date: date,
  description: description.trim(),
  photos: List.of(photoIds),
);

/// The entry a standalone photograph becomes.
///
/// Deliberately an ordinary [LogType.note], the same shape the diary form
/// writes, so the timeline, the counts and the exports all keep working
/// without knowing the album exists.
DevelopmentLog photoLog({
  required String childId,
  required DateTime date,
  required String description,
  required List<String> photoIds,
  String id = '',
}) => DevelopmentLog(
  id: id,
  childId: childId,
  date: date,
  type: LogType.note,
  title: LogTitles.photo,
  description: description.trim(),
  photos: photoIds,
);
