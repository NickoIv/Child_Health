import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../data/auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication (email + password,
/// per requirement 2.1).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([fb.FirebaseAuth? auth])
    : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _guard(
      () => _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser? _map(fb.User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email ?? '');
  }

  /// Turns Firebase's error codes into messages a parent can act on.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  static String _messageFor(fb.FirebaseAuthException e) => switch (e.code) {
    // Modern Firebase returns invalid-credential for both a wrong password
    // and an unknown address, to avoid leaking which accounts exist.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Неверный email или пароль',
    'invalid-email' => 'Некорректный адрес электронной почты',
    'email-already-in-use' => 'Этот email уже зарегистрирован',
    'weak-password' => 'Пароль слишком простой — минимум 6 символов',
    'user-disabled' => 'Учётная запись отключена',
    'too-many-requests' =>
      'Слишком много попыток. Попробуйте через несколько минут',
    'network-request-failed' => 'Нет связи с сервером. Проверьте интернет',
    'operation-not-allowed' =>
      'Вход по email и паролю выключен в консоли Firebase',
    _ => 'Не удалось выполнить операцию: ${e.code}',
  };
}
