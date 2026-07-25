import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/memory_repository.dart';
import 'data/repositories.dart';
import 'models/child.dart';
import 'models/development_log.dart';
import 'models/medical_record.dart';
import 'models/reminder.dart';

/// Uid of the signed-in parent.
///
/// Hard-coded until Firebase Auth is configured. Once it is, this becomes a
/// provider watching `FirebaseAuth.instance.authStateChanges()`, and nothing
/// downstream has to change.
final currentUidProvider = Provider<String>((ref) => 'demo-parent');

final memoryDatabaseProvider = Provider<MemoryDatabase>((ref) {
  final db = MemoryDatabase.seeded(ref.watch(currentUidProvider));
  ref.onDispose(db.dispose);
  return db;
});

// --- Repositories ---------------------------------------------------------
// Swapping these four overrides for Firestore implementations is the whole
// migration, as far as the UI is concerned.

final childRepositoryProvider = Provider<ChildRepository>(
  (ref) => MemoryChildRepository(ref.watch(memoryDatabaseProvider)),
);

final logRepositoryProvider = Provider<DevelopmentLogRepository>(
  (ref) => MemoryDevelopmentLogRepository(ref.watch(memoryDatabaseProvider)),
);

final medicalRepositoryProvider = Provider<MedicalRecordRepository>(
  (ref) => MemoryMedicalRecordRepository(ref.watch(memoryDatabaseProvider)),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => MemoryReminderRepository(ref.watch(memoryDatabaseProvider)),
);

// --- Queries --------------------------------------------------------------

final childrenProvider = StreamProvider<List<Child>>((ref) {
  return ref
      .watch(childRepositoryProvider)
      .watchChildren(ref.watch(currentUidProvider));
});

/// Id of the child currently being viewed. Null means "not chosen yet", in
/// which case [selectedChildProvider] falls back to the first one.
class SelectedChildId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedChildIdProvider = NotifierProvider<SelectedChildId, String?>(
  SelectedChildId.new,
);

final selectedChildProvider = Provider<Child?>((ref) {
  final children = ref.watch(childrenProvider).value ?? const <Child>[];
  if (children.isEmpty) return null;
  final id = ref.watch(selectedChildIdProvider);
  if (id == null) return children.first;
  for (final c in children) {
    if (c.id == id) return c;
  }
  return children.first;
});

final logsProvider = StreamProvider<List<DevelopmentLog>>((ref) {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return Stream.value(const []);
  return ref.watch(logRepositoryProvider).watchLogs(child.id);
});

final medicalRecordsProvider = StreamProvider<List<MedicalRecord>>((ref) {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return Stream.value(const []);
  return ref.watch(medicalRepositoryProvider).watchRecords(child.id);
});

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return Stream.value(const []);
  return ref.watch(reminderRepositoryProvider).watchReminders(child.id);
});

// --- Derived views --------------------------------------------------------

/// Measurement entries only, oldest first — the shape the growth chart wants.
final measurementsProvider = Provider<List<DevelopmentLog>>((ref) {
  final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
  final result =
      logs
          .where((l) => l.type == LogType.measurement && !l.metrics.isEmpty)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  return result;
});

/// Distinct calendar days marked as illness, used by the heat map and stats.
final illnessDaysProvider = Provider<Set<DateTime>>((ref) {
  final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
  return {
    for (final l in logs)
      if (l.type == LogType.illness)
        DateTime(l.date.year, l.date.month, l.date.day),
  };
});
