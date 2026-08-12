import 'dart:convert';

import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/medical_record.dart';
import '../../models/reminder.dart';
import '../app_info.dart';

/// Everything she wrote, in a file she keeps.
///
/// The app could import a diary from somebody else's app and could not hand
/// hers back. That is the wrong way round for a record of a child's health:
/// the data has to be leaveable, and a service you cannot walk out of with
/// your own years of entries is a service you are stuck in rather than one
/// you chose.
///
/// It is also the backup. Firestore already keeps a full copy on the device
/// and another on the server, which covers a lost phone and a broken one —
/// but not an account closed, a service shut down, or the day this app stops
/// being maintained. A file on her own disk survives all three.
///
/// JSON rather than CSV: a feed carries a side, a duration, a food and a
/// note, and flattening that into columns loses the shape and then the
/// meaning. Every model already writes itself as a map for Firestore, and
/// this uses the same maps — one format, so an export cannot drift away from
/// what is actually stored.
///
/// Photographs are not in it. They are files rather than records, they are
/// megabytes each, and a backup nobody can email is a backup nobody keeps.
/// The entries that carry them keep their links.
const backupFormatVersion = 1;

/// The whole of one family's data, ready to be written out.
Map<String, Object?> buildBackup({
  required List<Child> children,
  required Map<String, List<DevelopmentLog>> logsByChild,
  required Map<String, List<MedicalRecord>> recordsByChild,
  required Map<String, List<Reminder>> remindersByChild,
  required DateTime at,
}) => {
  'format': backupFormatVersion,
  'app': AppInfo.appName,
  'app_version': AppInfo.version,
  'exported_at': at.toIso8601String(),
  'children': [
    for (final child in children)
      {
        ...child.toMap(),
        'id': child.id,
        'logs': [
          for (final log in logsByChild[child.id] ?? const <DevelopmentLog>[])
            {...log.toMap(), 'id': log.id},
        ],
        'medical_records': [
          for (final record
              in recordsByChild[child.id] ?? const <MedicalRecord>[])
            {...record.toMap(), 'id': record.id},
        ],
        'reminders': [
          for (final reminder
              in remindersByChild[child.id] ?? const <Reminder>[])
            {...reminder.toMap(), 'id': reminder.id},
        ],
      },
  ],
};

/// Indented on purpose. This is a file a person may open to see what is in
/// it, and a single line of JSON answers that question with a wall.
String encodeBackup(Map<String, Object?> backup) =>
    const JsonEncoder.withIndent('  ').convert(backup);

/// What the file is called.
///
/// The child's name is in it so a folder with three of them stays readable,
/// and the date so a newer one does not overwrite an older one. Everything a
/// filesystem objects to is replaced — children's names arrive with spaces,
/// apostrophes and, on some systems fatally, slashes.
String backupFilename(List<Child> children, DateTime at) {
  final stamp =
      '${at.year}-${_two(at.month)}-${_two(at.day)}';

  final who = children.length == 1 ? _safe(children.single.name) : '';
  return who.isEmpty ? 'дневник-$stamp.json' : 'дневник-$who-$stamp.json';
}

String _two(int v) => v.toString().padLeft(2, '0');

String _safe(String name) => name
    .trim()
    .replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')
    .replaceAll(RegExp('_+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');
