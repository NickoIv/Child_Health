import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/ai_config.dart';
import 'ai/assistant_service.dart';
import 'core/analytics/daily_care.dart';
import 'core/analytics/daily_digest.dart';
import 'core/analytics/illness_stats.dart';
import 'core/analytics/shared_moments.dart';
import 'core/analytics/weekly_story.dart';
import 'core/notifications/notification_service.dart';
import 'core/voice/dictation.dart';
import 'data/auth_repository.dart';
import 'data/family_repository.dart';
import 'data/memory_repository.dart';
import 'data/photo_repository.dart';
import 'data/read_only_repositories.dart';
import 'data/repositories.dart';
import 'data/user_repository.dart';
import 'models/app_user.dart';
import 'models/child.dart';
import 'models/development_log.dart';
import 'models/family_member.dart';
import 'models/medical_record.dart';
import 'models/photo.dart';
import 'models/reminder.dart';

// --- Authentication -------------------------------------------------------
// The defaults here are the offline demo stack: an always-signed-in user on
// an in-memory store. `main.dart` overrides them with the Firebase versions.
// Tests get the demo stack for free and never touch the network.

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DemoAuthRepository(),
);

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Uid of the signed-in parent, empty while signed out.
final currentUidProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).value?.uid ?? '';
});

final memoryDatabaseProvider = Provider<MemoryDatabase>((ref) {
  final db = MemoryDatabase.seeded(ref.watch(currentUidProvider));
  ref.onDispose(db.dispose);
  return db;
});

// --- Family access --------------------------------------------------------
// Who is holding the phone, and what they are allowed to do with it.

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final repository = MemoryFamilyRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

/// Address of the signed-in account, lowercased. Empty while signed out.
final currentEmailProvider = Provider<String>((ref) {
  return normalizeEmail(ref.watch(authStateProvider).value?.email ?? '');
});

/// Every invitation addressed to this account, pending and accepted.
final myInvitationsProvider = StreamProvider<List<FamilyMember>>((ref) {
  final email = ref.watch(currentEmailProvider);
  if (email.isEmpty) return Stream.value(const []);
  return ref.watch(familyRepositoryProvider).watchInvitationsFor(email);
});

/// The invitation this account has taken up, if any.
///
/// One, not a list: phase one gives a viewer access to the family that
/// invited them, and a father who has been invited by two different mothers
/// is a problem to have later rather than a case to design for now.
final familyAccessProvider = Provider<FamilyMember?>((ref) {
  final invitations =
      ref.watch(myInvitationsProvider).value ?? const <FamilyMember>[];
  for (final invitation in invitations) {
    if (invitation.isAccepted) return invitation;
  }
  return null;
});

/// Invitations still waiting on an answer from this account.
final pendingInvitationsProvider = Provider<List<FamilyMember>>((ref) {
  final invitations =
      ref.watch(myInvitationsProvider).value ?? const <FamilyMember>[];
  return invitations.where((invitation) => invitation.isPending).toList();
});

/// Whose data this session is looking at.
///
/// The viewer's own uid owns nothing; every document he is allowed to see
/// carries the *inviter's* uid, so that is what the queries are scoped to.
/// This one line is what makes read access work without a second code path
/// through every repository.
final dataOwnerUidProvider = Provider<String>((ref) {
  return ref.watch(familyAccessProvider)?.ownerUid ??
      ref.watch(currentUidProvider);
});

final accessRoleProvider = Provider<FamilyRole>((ref) {
  return ref.watch(familyAccessProvider) == null
      ? FamilyRole.owner
      : FamilyRole.viewer;
});

/// The single question the interface asks before offering any control that
/// writes something.
final isReadOnlyProvider = Provider<bool>((ref) {
  return ref.watch(accessRoleProvider) == FamilyRole.viewer;
});

// --- Repositories ---------------------------------------------------------
// Swapping the raw overrides for Firestore implementations is the whole
// migration, as far as the UI is concerned.
//
// Each public provider is the raw one behind a read-only wrapper. The split
// is deliberate: `main.dart` overrides the raw providers, so a viewer cannot
// be handed a writable repository by a stack that forgot to wrap it.

final rawChildRepositoryProvider = Provider<ChildRepository>(
  (ref) => MemoryChildRepository(ref.watch(memoryDatabaseProvider)),
);

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  final raw = ref.watch(rawChildRepositoryProvider);
  return ref.watch(isReadOnlyProvider) ? ReadOnlyChildRepository(raw) : raw;
});

final rawLogRepositoryProvider = Provider<DevelopmentLogRepository>(
  (ref) => MemoryDevelopmentLogRepository(ref.watch(memoryDatabaseProvider)),
);

final logRepositoryProvider = Provider<DevelopmentLogRepository>((ref) {
  final raw = ref.watch(rawLogRepositoryProvider);
  return ref.watch(isReadOnlyProvider) ? ReadOnlyLogRepository(raw) : raw;
});

final rawMedicalRepositoryProvider = Provider<MedicalRecordRepository>(
  (ref) => MemoryMedicalRecordRepository(ref.watch(memoryDatabaseProvider)),
);

final medicalRepositoryProvider = Provider<MedicalRecordRepository>((ref) {
  final raw = ref.watch(rawMedicalRepositoryProvider);
  return ref.watch(isReadOnlyProvider)
      ? ReadOnlyMedicalRecordRepository(raw)
      : raw;
});

final rawReminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => MemoryReminderRepository(ref.watch(memoryDatabaseProvider)),
);

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final raw = ref.watch(rawReminderRepositoryProvider);
  return ref.watch(isReadOnlyProvider) ? ReadOnlyReminderRepository(raw) : raw;
});

final rawPhotoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => MemoryPhotoRepository(),
);

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final raw = ref.watch(rawPhotoRepositoryProvider);
  return ref.watch(isReadOnlyProvider) ? ReadOnlyPhotoRepository(raw) : raw;
});

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => MemoryUserRepository(),
);

/// The parent's profile, or null before it has been saved for the first time.
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid.isEmpty) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchProfile(uid);
});

/// Display units. Falls back to metric, which is also what everything is
/// stored in — see `core/units/units.dart`.
final unitSystemProvider = Provider<UnitSystem>((ref) {
  return ref.watch(userProfileProvider).value?.settings.unitSystem ??
      UnitSystem.metric;
});

/// The microphone behind the note field.
///
/// Unavailable by default, exactly like the repositories above: a widget test
/// gets a recogniser that politely declines and the button hides itself,
/// rather than a platform channel that is not there. `main.dart` overrides
/// this with the real one.
final dictationProvider = Provider<Dictation>(
  (ref) => const UnavailableDictation(),
);

/// One photo, fetched on demand.
///
/// A photo never changes after it is written, so this is a plain future
/// rather than a stream — and `keepAlive` stops a scroll past a diary entry
/// from re-downloading the same image over and over.
final photoProvider = FutureProvider.family<Photo?, String>((ref, id) async {
  ref.keepAlive();
  return ref.watch(photoRepositoryProvider).byId(id);
});

// --- Queries --------------------------------------------------------------

final childrenProvider = StreamProvider<List<Child>>((ref) {
  // Scoped to whoever owns the record, which for an invited viewer is not
  // himself. See [dataOwnerUidProvider].
  return ref
      .watch(childRepositoryProvider)
      .watchChildren(ref.watch(dataOwnerUidProvider));
});

/// Everyone with access to the child currently on screen.
final familyMembersProvider = StreamProvider<List<FamilyMember>>((ref) {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return Stream.value(const []);
  return ref.watch(familyRepositoryProvider).watchMembers(child.id);
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

// --- Local notifications --------------------------------------------------

/// The device's own reminder scheduler.
///
/// The default instance is never initialised, and every method on it returns
/// early until it is — which is exactly what tests and the offline demo want.
/// `main.dart` overrides this with the one it has started up.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Reminders of every child at once.
///
/// Deliberately not [remindersProvider], which follows the child currently on
/// screen: the planner shows one child at a time, but a phone has to ring for
/// all of them. Reminder ids are unique across children, so concatenating the
/// lists cannot produce a duplicate notification.
final allRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  final children = ref.watch(childrenProvider).value ?? const <Child>[];
  if (children.isEmpty) return Stream.value(const <Reminder>[]);

  final repository = ref.watch(reminderRepositoryProvider);
  return _combineLatest([
    for (final child in children) repository.watchReminders(child.id),
  ]);
});

/// Latest value of every stream, concatenated, re-emitted whenever any of them
/// moves.
///
/// Hand-rolled because the alternative is a reactive-extensions dependency for
/// this one function. Each list starts out empty rather than absent, so a
/// child whose stream has not spoken yet cannot hold up the others.
Stream<List<Reminder>> _combineLatest(List<Stream<List<Reminder>>> streams) {
  final latest = List<List<Reminder>>.filled(streams.length, const []);
  final subscriptions = <StreamSubscription<List<Reminder>>>[];
  late final StreamController<List<Reminder>> controller;

  controller = StreamController<List<Reminder>>(
    onListen: () {
      for (var i = 0; i < streams.length; i++) {
        final index = i;
        subscriptions.add(
          streams[i].listen((reminders) {
            latest[index] = reminders;
            controller.add([for (final list in latest) ...list]);
          }, onError: controller.addError),
        );
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    },
  );

  return controller.stream;
}

/// Keeps the scheduled notifications in step with the planner.
///
/// Watched once from the root widget. Every change to the reminder list —
/// added, completed, deleted — re-runs the whole schedule, which is safe
/// because scheduling is keyed by reminder id and so replaces rather than
/// accumulates.
final notificationSyncProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  ref.listen<AsyncValue<List<Reminder>>>(allRemindersProvider, (_, next) {
    final reminders = next.value;
    if (reminders != null) service.syncAll(reminders);
  }, fireImmediately: true);
});

// --- Assistant ------------------------------------------------------------

/// Falls back to the disabled implementation when no proxy URL was compiled
/// in, so a build without AI degrades to an explanation instead of an error.
final assistantServiceProvider = Provider<AssistantService>((ref) {
  return AiConfig.isConfigured
      ? GeminiAssistantService()
      : const DisabledAssistantService();
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

/// Today's feeds, nappies and sleep for the selected child.
final dailyCareProvider = Provider<DailyCare>((ref) {
  return dailyCareFor(
    ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
    DateTime.now(),
  );
});

/// Today, condensed for someone who was not there.
///
/// Built from the same logs the diary draws, so there is no second store to
/// keep in step and nothing to backfill — see `core/analytics/daily_digest`.
final dailyDigestProvider = Provider<DailyDigest>((ref) {
  return buildDailyDigest(
    ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
    DateTime.now(),
  );
});

/// Today's photographs, newest first and never more than three.
///
/// Same logs, same photo ids as the diary and the digest — see
/// `core/analytics/shared_moments`.
final recentMomentsProvider = Provider<List<Moment>>((ref) {
  return recentMoments(
    ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
    DateTime.now(),
  );
});

/// The last seven days, for the card both parents keep.
///
/// Nothing is stored for it — see `core/analytics/weekly_story`.
final weeklyStoryProvider = Provider<WeeklyStory>((ref) {
  return buildWeeklyStory(
    ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
    DateTime.now(),
  );
});

/// Things to raise at the next appointment, newest first.
///
/// They accumulate over a week and evaporate the moment the doctor says
/// "any questions?" — which is why they are collected here and printed into
/// the report rather than left in the diary stream.
final doctorQuestionsProvider = Provider<List<DevelopmentLog>>((ref) {
  final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
  return logs.where((l) => l.type == LogType.question).toList();
});

/// Distinct calendar days marked as illness, used by the heat map and stats.
final illnessDaysProvider = Provider<Set<DateTime>>((ref) {
  return ref.watch(illnessSeverityByDayProvider).keys.toSet();
});

/// Worst severity recorded on each sick day. The arithmetic lives in
/// `core/analytics/illness_stats.dart` so it can be tested on its own.
final illnessSeverityByDayProvider = Provider<Map<DateTime, Severity>>((ref) {
  return worstSeverityByDay(
    ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
  );
});
