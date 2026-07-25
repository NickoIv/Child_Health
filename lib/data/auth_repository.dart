/// The signed-in parent, reduced to what the app actually uses.
///
/// Deliberately not `firebase_auth.User`: keeping the UI behind this type is
/// what lets the widget tests run without initialising Firebase.
class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

/// A failure worth showing to the parent, already phrased in Russian.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  Future<void> sendPasswordReset(String email);

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
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}
}
