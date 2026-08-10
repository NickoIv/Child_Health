import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_snack.dart';
import '../../core/l10n/auth_errors.dart';
import '../../data/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../shared/widgets.dart';
import '../../providers.dart';

enum _Mode { signIn, register }

/// Sign in with Apple exists only on Apple's own platforms; the web flow needs
/// a separate Apple Developer service id, so it stays off until that is set up.
final _appleAvailable =
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Email + password sign-in and registration, per requirement 2.1.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final isRegister = _mode == _Mode.register;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.child_care,
                        size: 44,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.appTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? l.authRegisterSubtitle
                            : l.authSignInSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _email,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l.authEmail,
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l.authPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: _validatePassword,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 20,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isRegister ? l.authRegister : l.authSignIn),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _toggleMode,
                        child: Text(
                          isRegister
                              ? l.authToSignIn
                              : l.authToRegister,
                        ),
                      ),
                      if (!isRegister)
                        TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: Text(l.authForgotPassword),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l.authOr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _signInWith(SocialProvider.google),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: Text(l.authWithGoogle),
                      ),
                      // Apple only wants its button where its own sheet
                      // exists; on Android it would lead nowhere.
                      if (_appleAvailable) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _signInWith(SocialProvider.apple),
                          icon: const Icon(Icons.apple, size: 22),
                          label: Text(l.authWithApple),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final l = AppLocalizations.of(context);
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l.authEmailRequired;
    // Deliberately loose: Firebase does the authoritative check, and an
    // over-strict regex rejects valid addresses.
    if (!email.contains('@') || !email.contains('.')) {
      return l.authEmailIncomplete;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l = AppLocalizations.of(context);
    final password = value ?? '';
    if (password.isEmpty) return l.authPasswordRequired;
    if (_mode == _Mode.register && password.length < 6) {
      return l.authPasswordTooShort;
    }
    return null;
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _Mode.signIn ? _Mode.register : _Mode.signIn;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = ref.read(authRepositoryProvider);
    try {
      if (_mode == _Mode.register) {
        await auth.register(
          email: _email.text,
          password: _password.text,
        );
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
      // Navigation is driven by the router's auth redirect, so there is
      // nothing to push here.
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = authErrorText(AppLocalizations.of(context), e),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).authUnexpected('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Google or Apple. No form validation: the provider collects the
  /// credentials itself, so the email and password fields are irrelevant here.
  Future<void> _signInWith(SocialProvider provider) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWith(provider);
    } on AuthCancelled {
      // Backing out of the provider's window is not a failure.
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = authErrorText(AppLocalizations.of(context), e),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).authUnexpected('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (_validateEmail(email) != null) {
      setState(() => _error = AppLocalizations.of(context).authResetNeedsEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showAppSnack(
          appSnack(
            AppLocalizations.of(context).authResetSent(email),
            kind: SnackKind.done,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = authErrorText(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
