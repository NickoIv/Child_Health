import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase/firebase_auth_repository.dart';
import 'firebase/firebase_options.dart';
import 'firebase/firestore_repositories.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month and weekday names come from intl, not from the widget tree, so the
  // Russian locale data has to be loaded before the first frame.
  await initializeDateFormatting('ru_RU');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline support, required by 3.3: Firestore keeps a local cache and
  // replays writes once the connection is back.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    ProviderScope(
      // This list is the entire difference between the offline demo stack the
      // tests run on and the real backend.
      overrides: [
        authRepositoryProvider.overrideWithValue(FirebaseAuthRepository()),
        childRepositoryProvider.overrideWith(
          (ref) => FirestoreChildRepository(
            FirebaseFirestore.instance,
            ref.watch(currentUidProvider),
          ),
        ),
        logRepositoryProvider.overrideWith(
          (ref) => FirestoreLogRepository(
            FirebaseFirestore.instance,
            ref.watch(currentUidProvider),
          ),
        ),
        medicalRepositoryProvider.overrideWith(
          (ref) => FirestoreMedicalRecordRepository(
            FirebaseFirestore.instance,
            ref.watch(currentUidProvider),
          ),
        ),
        reminderRepositoryProvider.overrideWith(
          (ref) => FirestoreReminderRepository(
            FirebaseFirestore.instance,
            ref.watch(currentUidProvider),
          ),
        ),
      ],
      child: const ChildHealthApp(),
    ),
  );
}
