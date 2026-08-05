import '../../data/auth_repository.dart';
import '../../l10n/app_localizations.dart';

/// The message to show for [error], in the chosen language.
///
/// Falls back to the Russian text the repository carried when the code is
/// unknown — a message in the wrong language beats no message at all.
String authErrorText(AppLocalizations l, AuthException error) =>
    switch (error.code) {
      AuthErrorCode.invalidCredentials => l.authErrorInvalidCredentials,
      AuthErrorCode.invalidEmail => l.authErrorInvalidEmail,
      AuthErrorCode.emailInUse => l.authErrorEmailInUse,
      AuthErrorCode.weakPassword => l.authErrorWeakPassword,
      AuthErrorCode.userDisabled => l.authErrorUserDisabled,
      AuthErrorCode.requiresRecentLogin => l.authErrorRequiresRecentLogin,
      AuthErrorCode.tooManyRequests => l.authErrorTooManyRequests,
      AuthErrorCode.network => l.authErrorNetwork,
      AuthErrorCode.operationNotAllowed => l.authErrorOperationNotAllowed,
      AuthErrorCode.googleNotConfigured => l.authErrorGoogleNotConfigured,
      AuthErrorCode.googleProvider => l.authErrorGoogleProvider,
      AuthErrorCode.googleInterrupted => l.authErrorGoogleInterrupted,
      AuthErrorCode.googleNoToken => l.authErrorGoogleNoToken,
      AuthErrorCode.signInFirst => l.authErrorSignInFirst,
      AuthErrorCode.noPassword => l.authErrorNoPassword,
      AuthErrorCode.unknownProvider => l.authErrorUnknownProvider,
      _ => error.message,
    };
