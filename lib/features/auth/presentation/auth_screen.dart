import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guesstogether/core/theme/app_spacing.dart';
import 'package:guesstogether/data/api/app_backend_api.dart';
import 'package:guesstogether/features/home/presentation/home_screen.dart';
import 'package:guesstogether/features/session/app_session_controller.dart';
import 'package:guesstogether/widgets/app_panel.dart';

enum _AuthMode { login, register }

enum _AuthField { displayName, credential, password, confirmPassword }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  static const String routePath = '/auth';
  static const String routeName = 'auth';

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _displayNameFocusNode = FocusNode();
  final FocusNode _credentialFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  _AuthMode _mode = _AuthMode.login;
  String? _formErrorText;
  String? _displayNameErrorText;
  String? _credentialErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;

  bool get _isRussian =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ru';

  String get _title {
    switch (_mode) {
      case _AuthMode.login:
        return _isRussian ? 'Вход в аккаунт' : 'Sign in';
      case _AuthMode.register:
        return _isRussian ? 'Создание аккаунта' : 'Create account';
    }
  }

  String get _submitLabel {
    switch (_mode) {
      case _AuthMode.login:
        return _isRussian ? 'Войти' : 'Sign in';
      case _AuthMode.register:
        return _isRussian ? 'Зарегистрироваться' : 'Create account';
    }
  }

  String get _switchPrompt {
    switch (_mode) {
      case _AuthMode.login:
        return _isRussian ? 'Нет аккаунта?' : 'No account yet?';
      case _AuthMode.register:
        return _isRussian ? 'Уже есть аккаунт?' : 'Already have an account?';
    }
  }

  String get _switchLabel {
    switch (_mode) {
      case _AuthMode.login:
        return _isRussian ? 'Регистрация' : 'Sign up';
      case _AuthMode.register:
        return _isRussian ? 'Авторизация' : 'Sign in';
    }
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<AppSessionState>>(
      appSessionControllerProvider,
      (
        AsyncValue<AppSessionState>? previous,
        AsyncValue<AppSessionState> next,
      ) {
        if (!mounted) {
          return;
        }
        final bool becameAuthenticated =
            previous?.valueOrNull?.isAuthenticated != true &&
                next.valueOrNull?.isAuthenticated == true;
        if (becameAuthenticated) {
          context.go(HomeScreen.routePath);
        }
      },
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _credentialController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameFocusNode.dispose();
    _credentialFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _AuthMode.login ? _AuthMode.register : _AuthMode.login;
      _clearErrors();
    });
  }

  void _clearErrors() {
    _formErrorText = null;
    _displayNameErrorText = null;
    _credentialErrorText = null;
    _passwordErrorText = null;
    _confirmPasswordErrorText = null;
  }

  void _clearFieldError(_AuthField field) {
    if (_formErrorText == null &&
        _displayNameErrorText == null &&
        _credentialErrorText == null &&
        _passwordErrorText == null &&
        _confirmPasswordErrorText == null) {
      return;
    }

    setState(() {
      _formErrorText = null;
      switch (field) {
        case _AuthField.displayName:
          _displayNameErrorText = null;
        case _AuthField.credential:
          _credentialErrorText = null;
        case _AuthField.password:
          _passwordErrorText = null;
        case _AuthField.confirmPassword:
          _confirmPasswordErrorText = null;
      }
    });
  }

  void _requestFocus(_AuthField field) {
    final FocusNode focusNode = switch (field) {
      _AuthField.displayName => _displayNameFocusNode,
      _AuthField.credential => _credentialFocusNode,
      _AuthField.password => _passwordFocusNode,
      _AuthField.confirmPassword => _confirmPasswordFocusNode,
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      focusNode.requestFocus();
    });
  }

  void _setFieldErrors({
    String? formErrorText,
    String? displayNameErrorText,
    String? credentialErrorText,
    String? passwordErrorText,
    String? confirmPasswordErrorText,
    _AuthField? focusField,
  }) {
    setState(() {
      _formErrorText = formErrorText;
      _displayNameErrorText = displayNameErrorText;
      _credentialErrorText = credentialErrorText;
      _passwordErrorText = passwordErrorText;
      _confirmPasswordErrorText = confirmPasswordErrorText;
    });

    if (focusField != null) {
      _requestFocus(focusField);
    }
  }

  void _applyBackendError(BackendException error) {
    final String message = error.message;
    final String normalized = message.trim().toLowerCase();

    if (_mode == _AuthMode.register) {
      if (normalized.contains('nickname')) {
        _setFieldErrors(
          displayNameErrorText: message,
          focusField: _AuthField.displayName,
        );
        return;
      }
      if (normalized.contains('password')) {
        _setFieldErrors(
          passwordErrorText: message,
          focusField: _AuthField.password,
        );
        return;
      }
      _setFieldErrors(formErrorText: message);
      return;
    }

    if (normalized.contains('password')) {
      _setFieldErrors(
        passwordErrorText: message,
        focusField: _AuthField.password,
      );
      return;
    }
    if (normalized.contains('credential') ||
        normalized.contains('nickname') ||
        normalized.contains('email') ||
        normalized.contains('invalid credentials')) {
      _setFieldErrors(
        credentialErrorText: message,
        focusField: _AuthField.credential,
      );
      return;
    }
    _setFieldErrors(formErrorText: message);
  }

  Future<void> _submit() async {
    setState(_clearErrors);
    try {
      if (_mode == _AuthMode.register) {
        final String password = _passwordController.text;
        final String confirmPassword = _confirmPasswordController.text;
        if (password != confirmPassword) {
          _setFieldErrors(
            confirmPasswordErrorText:
                _isRussian ? 'Пароли не совпадают.' : 'Passwords do not match.',
            focusField: _AuthField.confirmPassword,
          );
          return;
        }
        await ref.read(appSessionControllerProvider.notifier).register(
              displayName: _displayNameController.text,
              password: password,
            );
        return;
      }

      await ref.read(appSessionControllerProvider.notifier).login(
            credential: _credentialController.text,
            password: _passwordController.text,
          );
    } on BackendException catch (error) {
      if (!mounted) {
        return;
      }
      _applyBackendError(error);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _setFieldErrors(
        formErrorText: _isRussian
            ? 'Не удалось выполнить запрос. Попробуйте ещё раз.'
            : 'The request failed. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final AsyncValue<AppSessionState> sessionAsync =
        ref.watch(appSessionControllerProvider);
    final bool isLoading = sessionAsync.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppPanel(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color.alphaBlend(
                      Colors.white.withValues(alpha: isLight ? 0.18 : 0.08),
                      scheme.surfaceContainerHighest
                          .withValues(alpha: isLight ? 0.82 : 0.56),
                    ),
                    Color.alphaBlend(
                      scheme.primary.withValues(alpha: isLight ? 0.08 : 0.12),
                      scheme.surfaceContainerHighest
                          .withValues(alpha: isLight ? 0.72 : 0.48),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_mode == _AuthMode.register) ...<Widget>[
                      TextField(
                        controller: _displayNameController,
                        focusNode: _displayNameFocusNode,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) =>
                            _clearFieldError(_AuthField.displayName),
                        decoration: InputDecoration(
                          labelText: _isRussian ? 'Ник' : 'Nickname',
                          errorText: _displayNameErrorText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ] else ...<Widget>[
                      TextField(
                        controller: _credentialController,
                        focusNode: _credentialFocusNode,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) =>
                            _clearFieldError(_AuthField.credential),
                        decoration: InputDecoration(
                          labelText: _isRussian ? 'Ник' : 'Nickname',
                          errorText: _credentialErrorText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: true,
                      textInputAction: _mode == _AuthMode.register
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onChanged: (_) => _clearFieldError(_AuthField.password),
                      onSubmitted:
                          _mode == _AuthMode.login ? (_) => _submit() : null,
                      decoration: InputDecoration(
                        labelText: _isRussian ? 'Пароль' : 'Password',
                        errorText: _passwordErrorText,
                      ),
                    ),
                    if (_mode == _AuthMode.register) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) =>
                            _clearFieldError(_AuthField.confirmPassword),
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: _isRussian
                              ? 'Повторите пароль'
                              : 'Repeat password',
                          errorText: _confirmPasswordErrorText,
                        ),
                      ),
                    ],
                    if (_formErrorText != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _formErrorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: AppSpacing.tapTargetMin + 4,
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Icon(
                                _mode == _AuthMode.login
                                    ? Icons.login_rounded
                                    : Icons.person_add_alt_1_rounded,
                              ),
                        label: Text(_submitLabel),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _switchPrompt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.9),
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : _toggleMode,
                          child: Text(_switchLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
