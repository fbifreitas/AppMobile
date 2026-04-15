import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../branding/brand_provider.dart';
import '../branding/brand_tokens.dart';
import '../l10n/app_strings.dart';
import '../services/mobile_auth_service.dart';
import '../state/auth_state.dart';
import 'compass_first_access_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _obscureSenha = true;
  bool _loading = false;

  String _errorMessageFor(Object error) {
    final strings = AppStrings.of(context);
    if (error is MobileAuthException) {
      return error.message;
    }
    return strings.tr(
      'Nao foi possivel entrar no momento. Tente novamente.',
      'Could not sign in right now. Please try again.',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthState>().login(
        _emailController.text,
        password: _senhaController.text,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessageFor(error))));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    final tokens = config.tokens;
    final strings = AppStrings.of(context);
    final welcomeText = strings.tr(
      'Bem-vindo à ${config.appName}',
      'Welcome to ${config.appName}',
    );
    final isCompass = config.brandId == 'compass';

    return Scaffold(
      backgroundColor: BrandTokens.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 64,
                    color: tokens.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    welcomeText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BrandTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.tr(
                      'Faça login para acessar seu painel',
                      'Sign in to access your dashboard',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Semantics(
                    identifier: 'login_email_field',
                    label: 'login_email_field',
                    textField: true,
                    child: TextFormField(
                      key: const Key('login_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: strings.tr('E-mail', 'Email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return strings.tr(
                            'Informe o e-mail',
                            'Enter your email',
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    identifier: 'login_senha_field',
                    label: 'login_senha_field',
                    textField: true,
                    child: TextFormField(
                      key: const Key('login_senha_field'),
                      controller: _senhaController,
                      obscureText: _obscureSenha,
                      decoration: InputDecoration(
                        labelText: strings.tr('Senha', 'Password'),
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSenha
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed:
                              () => setState(
                                () => _obscureSenha = !_obscureSenha,
                              ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings.tr(
                            'Informe a senha',
                            'Enter your password',
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    identifier: 'login_submit_button',
                    label: 'login_submit_button',
                    button: true,
                    child: FilledButton(
                      key: const Key('login_submit_button'),
                      onPressed: _loading ? null : _submit,
                      child:
                          _loading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(strings.tr('Entrar', 'Sign in')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const Key('login_first_access_button'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) =>
                                isCompass
                                    ? const CompassFirstAccessScreen()
                                    : const OnboardingScreen(),
                      ),
                    ),
                    child: Text(
                      isCompass
                          ? strings.tr('Primeiro acesso', 'First access')
                          : strings.tr(
                            'Criar minha conta de Vistoriador',
                            'Create inspector account',
                          ),
                    ),
                  ),
                  TextButton(
                    key: const Key('login_forgot_password_button'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.tr(
                              'Recuperacao de senha sera validada no proximo pacote de autenticacao.',
                              'Password recovery will be delivered in the next authentication package.',
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      strings.tr('Esqueci minha senha', 'Forgot password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
