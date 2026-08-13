import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/medical_record.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../care/backup_store.dart';
import 'backup.dart';
import 'save_file.dart';

/// Writes the whole diary to a file, from wherever it was asked for.
///
/// Lifted out of the settings card because there are two places that ask now
/// — that card and the reminder on the home screen — and two copies of this
/// would drift. The one that matters if they drifted is the loop over
/// children: a backup quietly missing one of two children looks exactly like
/// a backup, and is trusted like one.
///
/// Returns the file name on success and null on failure. Never throws: this
/// is called from a button, and a button that can explode is a crash instead
/// of a message.
Future<String?> runBackup(WidgetRef ref, {DateTime? now}) async {
  try {
    final children = ref.read(childrenProvider).value ?? const <Child>[];
    final logs = <String, List<DevelopmentLog>>{};
    final records = <String, List<MedicalRecord>>{};
    final reminders = <String, List<Reminder>>{};

    // Read per child rather than from the screen's own providers: those hold
    // the selected child only.
    for (final child in children) {
      logs[child.id] =
          await ref.read(logRepositoryProvider).watchLogs(child.id).first;
      records[child.id] = await ref
          .read(medicalRepositoryProvider)
          .watchRecords(child.id)
          .first;
      reminders[child.id] = await ref
          .read(reminderRepositoryProvider)
          .watchReminders(child.id)
          .first;
    }

    final at = now ?? DateTime.now();
    final name = backupFilename(children, at);
    final ok = await saveTextFile(
      name,
      encodeBackup(
        buildBackup(
          children: children,
          logsByChild: logs,
          recordsByChild: records,
          remindersByChild: reminders,
          at: at,
        ),
      ),
    );
    if (!ok) return null;

    // Recorded here rather than at either call site, so the reminder can
    // never go on asking for a copy she has just made.
    await ref.read(backupStoreProvider.notifier).saved(at);
    return name;
  } on Exception {
    return null;
  }
}
