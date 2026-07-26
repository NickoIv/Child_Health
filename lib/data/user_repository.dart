import '../models/app_user.dart';

/// The parent's own profile and preferences (requirement 2.1).
///
/// Kept apart from [AuthRepository]: authentication says who someone is,
/// this says how they want the app to behave. The two change for different
/// reasons and live in different places — one in Firebase Auth, one in the
/// `users` collection.
abstract class UserRepository {
  Stream<AppUser?> watchProfile(String uid);

  Future<void> save(AppUser user);
}

class MemoryUserRepository implements UserRepository {
  final _profiles = <String, AppUser>{};

  @override
  Stream<AppUser?> watchProfile(String uid) =>
      Stream.value(_profiles[uid]);

  @override
  Future<void> save(AppUser user) async => _profiles[user.uid] = user;
}
