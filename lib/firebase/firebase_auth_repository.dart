import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart' as gs;

import '../data/auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication (email + password,
/// per requirement 2.1, plus Google and Apple).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([fb.FirebaseAuth? auth])
    : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  /// `initialize` may only be called once per run, and nothing else in the
  /// plugin reports whether it already has been.
  bool _googleReady = false;

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
  Future<void> signInWith(SocialProvider provider) async {
    await _guard(() async {
      switch (provider) {
        case SocialProvider.google:
          await _signInWithGoogle();
        case SocialProvider.apple:
          await _signInWithApple();
      }
    });
  }

  /// Google, by way of whichever flow the platform allows.
  ///
  /// The web plugin refuses to open a dialog of its own — Google insists on
  /// its rendered button there — so on the web the popup comes from Firebase
  /// instead. Everywhere else the plugin returns an ID token that Firebase
  /// exchanges for a session.
  Future<void> _signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(fb.GoogleAuthProvider());
      return;
    }

    final google = gs.GoogleSignIn.instance;
    if (!_googleReady) {
      // Client ids come from google-services.json and GoogleService-Info.plist,
      // so there is nothing to pass here.
      await google.initialize();
      _googleReady = true;
    }

    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        'Google не вернул токен входа. Попробуйте ещё раз',
      );
    }
    await _auth.signInWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Apple, through Firebase's own provider flow.
  ///
  /// No extra package: `signInWithProvider` drives the native Sign in with
  /// Apple sheet on iOS and macOS and takes care of the nonce, which is the
  /// only fiddly part of doing this by hand.
  Future<void> _signInWithApple() async {
    final provider = fb.AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw const AuthException('Сначала войдите в свою учётную запись');
    }
    if (!_providersOf(current).contains(passwordProvider)) {
      // Firebase can set a password on such an account, but that would quietly
      // turn a Google sign-in into a second, separate way in — a surprise
      // nobody asked for from a screen labelled "change password".
      throw const AuthException(
        'У этой учётной записи нет пароля: вход выполняется через Google. '
        'Пароль меняется в настройках аккаунта Google',
      );
    }
    final user = await _reauthenticate(currentPassword);
    await _guard(() => user.updatePassword(newPassword));
  }

  @override
  Future<void> deleteAccount({required String currentPassword}) async {
    final user = await _reauthenticate(currentPassword);
    await _guard(user.delete);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Firebase rejects a password change or deletion on a session older than a
  /// few minutes, so both paths prove who the parent is first.
  ///
  /// How they prove it depends on how they got in: a typed password for an
  /// email account, and the provider's own dialog for a Google or Apple one,
  /// where [password] is meaningless and ignored.
  Future<fb.User> _reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Сначала войдите в свою учётную запись');
    }
    final providers = _providersOf(user);

    if (providers.contains(passwordProvider)) {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw const AuthException('Сначала войдите в свою учётную запись');
      }
      await _guard(
        () => user.reauthenticateWithCredential(
          fb.EmailAuthProvider.credential(email: email, password: password),
        ),
      );
      return user;
    }

    if (providers.contains(googleProvider)) {
      await _guard(() => _reauthenticateWithGoogle(user));
      return user;
    }

    if (providers.contains(appleProvider)) {
      final provider = fb.AppleAuthProvider();
      await _guard(
        () => kIsWeb
            ? user.reauthenticateWithPopup(provider)
            : user.reauthenticateWithProvider(provider),
      );
      return user;
    }

    throw const AuthException(
      'Не удалось подтвердить личность: неизвестный способ входа. '
      'Выйдите и войдите заново',
    );
  }

  /// Same two flows as signing in, aimed at the account already present.
  Future<void> _reauthenticateWithGoogle(fb.User user) async {
    if (kIsWeb) {
      await user.reauthenticateWithPopup(fb.GoogleAuthProvider());
      return;
    }

    final google = gs.GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize();
      _googleReady = true;
    }

    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        'Google не вернул токен входа. Попробуйте ещё раз',
      );
    }
    await user.reauthenticateWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  AuthUser? _map(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      providers: _providersOf(user),
    );
  }

  static Set<String> _providersOf(fb.User user) =>
      user.providerData.map((info) => info.providerId).toSet();

  /// Turns Firebase's error codes into messages a parent can act on.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fb.FirebaseAuthException catch (e) {
      if (_cancellationCodes.contains(e.code)) throw const AuthCancelled();
      throw AuthException(_messageFor(e));
    } on gs.GoogleSignInException catch (e) {
      if (e.code == gs.GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelled();
      }
      throw AuthException(_googleMessageFor(e));
    }
  }

  /// Shutting the provider's window is not an error, on any platform.
  static const _cancellationCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'user-cancelled',
    'web-context-canceled',
  };

  static String _googleMessageFor(gs.GoogleSignInException e) =>
      switch (e.code) {
        gs.GoogleSignInExceptionCode.clientConfigurationError =>
          'Вход через Google не настроен для этой сборки приложения',
        gs.GoogleSignInExceptionCode.providerConfigurationError =>
          'Google не может подтвердить это приложение. Обратитесь в поддержку',
        gs.GoogleSignInExceptionCode.interrupted =>
          'Вход через Google прервался. Проверьте связь и попробуйте ещё раз',
        _ => 'Не удалось войти через Google: ${e.description ?? e.code.name}',
      };

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
    'requires-recent-login' =>
      'Для этого действия нужно войти заново. Выйдите и войдите ещё раз',
    'too-many-requests' =>
      'Слишком много попыток. Попробуйте через несколько минут',
    'network-request-failed' => 'Нет связи с сервером. Проверьте интернет',
    'operation-not-allowed' =>
      'Вход по email и паролю выключен в консоли Firebase',
    _ => 'Не удалось выполнить операцию: ${e.code}',
  };
}
