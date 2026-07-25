import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../providers.dart';

enum _Mode { signIn, register }

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
    final isRegister = _mode == _Mode.register;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
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
                        'Календарь развития\nи здоровья ребёнка',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? 'Создайте учётную запись родителя'
                            : 'Войдите, чтобы продолжить',
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
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Пароль',
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
                            : Text(isRegister ? 'Зарегистрироваться' : 'Войти'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _toggleMode,
                        child: Text(
                          isRegister
                              ? 'Уже есть учётная запись — войти'
                              : 'Нет учётной записи — зарегистрироваться',
                        ),
                      ),
                      if (!isRegister)
                        TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text('Забыли пароль?'),
                        ),
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
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Введите email';
    // Deliberately loose: Firebase does the authoritative check, and an
    // over-strict regex rejects valid addresses.
    if (!email.contains('@') || !email.contains('.')) {
      return 'Похоже, адрес неполный';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Введите пароль';
    if (_mode == _Mode.register && password.length < 6) {
      return 'Минимум 6 символов';
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
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Неожиданная ошибка: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (_validateEmail(email) != null) {
      setState(() => _error = 'Введите email, на него придёт ссылка');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Письмо для сброса пароля отправлено на $email')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
