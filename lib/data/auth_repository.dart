/// The signed-in parent, reduced to what the app actually uses.
///
/// Deliberately not `firebase_auth.User`: keeping the UI behind this type is
/// what lets the widget tests run without initialising Firebase.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.providers = const {'password'},
  });

  final String uid;
  final String email;

  /// How this account can sign in: `password`, `google.com`, `apple.com`.
  ///
  /// The app needs it for one reason — an account created through Google has
  /// no password, so anything that asks for the current one has to ask
  /// something else instead. Defaults to a password account, which is what
  /// the demo stack and the tests are.
  final Set<String> providers;

  bool get hasPassword => providers.contains(passwordProvider);

  bool get signedInWithGoogle => providers.contains(googleProvider);
}

const passwordProvider = 'password';
const googleProvider = 'google.com';
const appleProvider = 'apple.com';

/// A failure worth showing to the parent, already phrased in Russian.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The parent closed the provider's window without finishing.
///
/// Deliberately not an [AuthException]: there is nothing to tell them, the
/// screen just goes back to how it was.
class AuthCancelled implements Exception {
  const AuthCancelled();
}

/// Sign-in providers offered alongside email and password.
enum SocialProvider { google, apple }

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  /// Signs in through [provider], creating the account on first use.
  ///
  /// Throws [AuthCancelled] when the parent backs out of the provider's own
  /// dialog, which is a normal outcome rather than a failure.
  Future<void> signInWith(SocialProvider provider);

  Future<void> sendPasswordReset(String email);

  /// Both operations below re-check the current password first.
  ///
  /// Firebase demands it for any sensitive change, and it is the right rule
  /// anyway: a phone left unlocked on a changing table should not be enough
  /// to lock the parent out or erase a year of records.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Removes the Firebase user. Everything the parent stored must already be
  /// deleted by the caller — once the account is gone, the security rules
  /// deny access to those documents forever.
  Future<void> deleteAccount({required String currentPassword});

  Future<void> signOut();
}

/// Always-signed-in stand-in used by tests and by the in-memory demo mode.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({this.uid = 'demo-parent'});

  final String uid;

  @override
  AuthUser? get currentUser => AuthUser(uid: uid, email: 'demo@example.com');

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(currentUser);

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWith(SocialProvider provider) async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount({required String currentPassword}) async {}

  @override
  Future<void> signOut() async {}
}
