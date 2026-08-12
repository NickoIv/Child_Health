import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/diagnostics/error_log.dart';
import 'core/storage/persist.dart';
import 'core/l10n/app_locale.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/theme_mode.dart';
import 'firebase/firebase_auth_repository.dart';
import 'firebase/firebase_options.dart';
import 'firebase/firestore_repositories.dart';
import 'firebase/push_messaging.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month and weekday names come from intl, not from the widget tree, so the
  // date symbols have to be loaded before the first frame. All locales rather
  // than one: the parent may have chosen English or Kazakh last time.
  await initializeDateFormatting();
  final locale = await readSavedLocale();
  // Read before the first frame for the same reason as the language: drawing
  // the dark theme and then repainting light is worse than waiting a moment.
  final theme = await readSavedTheme();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline support, required by 3.3: Firestore keeps a local cache and
  // replays writes once the connection is back.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Local reminders. Started before the first frame so a notification tapped
  // from the lock screen has somewhere to arrive, and deliberately independent
  // of Firebase Messaging above: push and local reminders run side by side.
  final notifications = NotificationService(
    null,
    lookupAppLocalizations(locale),
  );
  await notifications.init();

  // Built here rather than by [ProviderScope] so the error log exists before
  // the first widget does: the errors most worth having are the ones thrown
  // while the app is still starting, and a handler installed from inside the
  // tree misses every one of them.
  final container = ProviderContainer(
      // This list is the entire difference between the offline demo stack the
      // tests run on and the real backend.
      overrides: [
        localeProvider.overrideWith(() => LocaleChoice(locale)),
        themePreferenceProvider.overrideWith(() => ThemeChoice(theme)),
        notificationServiceProvider.overrideWithValue(notifications),
        authRepositoryProvider.overrideWithValue(FirebaseAuthRepository()),
        // Reads, never prompts — see [pushTokenSyncProvider].
        pushTokenReaderProvider.overrideWithValue(currentPushToken),
        idTokenReaderProvider.overrideWithValue(currentIdToken),
        // The *raw* repositories, deliberately. The public providers wrap
        // these in a read-only guard when the session is a viewer's, and
        // overriding those instead would hand a father a writable client.
        //
        // Scoped to `dataOwnerUidProvider` rather than to the caller's own
        // uid: every document a viewer is allowed to read carries the
        // inviter's uid, so that is what the queries have to filter on.
        rawChildRepositoryProvider.overrideWith(
          (ref) => FirestoreChildRepository(
            FirebaseFirestore.instance,
            ref.watch(dataOwnerUidProvider),
          ),
        ),
        rawLogRepositoryProvider.overrideWith(
          (ref) => FirestoreLogRepository(
            FirebaseFirestore.instance,
            ref.watch(dataOwnerUidProvider),
          ),
        ),
        rawMedicalRepositoryProvider.overrideWith(
          (ref) => FirestoreMedicalRecordRepository(
            FirebaseFirestore.instance,
            ref.watch(dataOwnerUidProvider),
          ),
        ),
        rawReminderRepositoryProvider.overrideWith(
          (ref) => FirestoreReminderRepository(
            FirebaseFirestore.instance,
            ref.watch(dataOwnerUidProvider),
          ),
        ),
        rawPhotoRepositoryProvider.overrideWith(
          (ref) => FirestorePhotoRepository(
            FirebaseFirestore.instance,
            ref.watch(dataOwnerUidProvider),
          ),
        ),
        familyRepositoryProvider.overrideWith(
          (ref) => FirestoreFamilyRepository(FirebaseFirestore.instance),
        ),
        userRepositoryProvider.overrideWith(
          (ref) => FirestoreUserRepository(FirebaseFirestore.instance),
        ),
      ],
  );

  // Both of Flutter's error channels, pointed at local storage and nowhere
  // else. Nothing is uploaded: the settings screen shows the log in full and
  // she copies it herself if she chooses to.
  installErrorLogging(container.read(errorLogProvider.notifier));

  // Asked once, never insisted on, and nothing waits for the answer.
  //
  // The offline copy of the diary lives in IndexedDB, and browser storage is
  // evictable by default — under pressure for space the browser may clear it
  // and is entitled to. For a shop that costs a session; here it would cost
  // the copy that makes the app work in a lift. Refusal changes nothing that
  // was working.
  unawaited(requestPersistentStorage());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ChildHealthApp(),
    ),
  );
}
