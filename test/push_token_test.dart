import 'package:child_health_tracker/data/user_repository.dart';
import 'package:child_health_tracker/models/app_user.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeping the list of devices honest.
///
/// A push token is not permanent: a browser rotates it when storage is
/// cleared or when the app is reinstalled to the home screen. Registering
/// once and never looking again leaves the profile pointing at a device that
/// no longer exists — the worker sends, nothing arrives, and nobody finds
/// out. What is tested here is that the token is re-read on every start, that
/// it is only ever added, and that a browser which was never given permission
/// causes no write at all.
void main() {
  final settingsOn = const UserSettings(notificationsEnabled: true);
  final settingsOff = const UserSettings(notificationsEnabled: false);

  AppUser profileWith(
    List<String> tokens, {
    UserSettings? settings,
  }) => AppUser(
    uid: 'u1',
    email: 'mum@example.com',
    displayName: 'Mum',
    settings: settings ?? const UserSettings(notificationsEnabled: true),
    pushTokens: tokens,
  );

  /// A repository that only records what it was asked to save.
  Future<ProviderContainer> containerFor(
    AppUser? profile,
    Future<String?> Function() reader,
    List<AppUser> saved,
  ) async {
    final repository = _RecordingUserRepository(saved);
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        userRepositoryProvider.overrideWithValue(repository),
        pushTokenReaderProvider.overrideWithValue(reader),
      ],
    );
    addTearDown(container.dispose);
    // Subscribed rather than read: in Riverpod 3 every provider is
    // auto-dispose, so a bare read is torn down again before the stream it
    // listens to has said anything. In the app the root widget watches it,
    // which is the same thing.
    container.listen(pushTokenSyncProvider, (_, _) {}, fireImmediately: true);
    // Three hops, not one: the stream has to emit, the listener has to await
    // the token reader, and only then does the save happen. `fireImmediately`
    // delivers an AsyncLoading first, which is exactly the case the guard
    // inside is written for.
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    return container;
  }

  test('a token the profile has never seen is added to it', () async {
    final saved = <AppUser>[];
    await containerFor(
      profileWith(const ['old-phone']),
      () async => 'new-tablet',
      saved,
    );

    expect(saved, hasLength(1));
    expect(saved.single.pushTokens, ['old-phone', 'new-tablet']);
  });

  test('a token already on file is not written again', () async {
    final saved = <AppUser>[];
    await containerFor(
      profileWith(const ['this-phone']),
      () async => 'this-phone',
      saved,
    );

    expect(saved, isEmpty);
  });

  test('the other devices are left alone', () async {
    // Pruning from here would unsubscribe the tablet every time the phone
    // starts. Only the switch in settings clears the list.
    final saved = <AppUser>[];
    await containerFor(
      profileWith(const ['tablet', 'grandmothers-phone']),
      () async => 'this-phone',
      saved,
    );

    expect(saved.single.pushTokens, [
      'tablet',
      'grandmothers-phone',
      'this-phone',
    ]);
  });

  test('a browser that never granted permission writes nothing', () async {
    final saved = <AppUser>[];
    await containerFor(profileWith(const []), () async => null, saved);

    expect(saved, isEmpty);
  });

  test('notifications switched off is left switched off', () async {
    final saved = <AppUser>[];
    await containerFor(
      profileWith(const [], settings: settingsOff),
      () async => 'a-token',
      saved,
    );

    expect(saved, isEmpty);
  });

  test('no profile yet means nothing to add a token to', () async {
    final saved = <AppUser>[];
    await containerFor(null, () async => 'a-token', saved);

    expect(saved, isEmpty);
  });

  test('the default reader answers none, so tests never reach Firebase',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(pushTokenReaderProvider)(), isNull);
    // And the settings default has notifications on, which is what makes the
    // guard above the interesting one.
    expect(settingsOn.notificationsEnabled, isTrue);
  });
}

class _RecordingUserRepository implements UserRepository {
  _RecordingUserRepository(this.saved);

  final List<AppUser> saved;

  @override
  Future<void> save(AppUser user) async => saved.add(user);

  @override
  Stream<AppUser?> watchProfile(String uid) => Stream.value(null);

  @override
  Future<void> delete(String uid) async {}
}
