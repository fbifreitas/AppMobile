import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../branding/brand_provider.dart';
import '../branding/brand_tokens.dart';
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
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
    final welcomeText = config.copyText(
      'login_welcome',
      defaultValue: 'Bem-vindo ao App de Vistorias',
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
                  const Text(
                    'Faça login para acessar seu painel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o e-mail';
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
                        labelText: 'Senha',
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
                          return 'Informe a senha';
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
                              : const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const Key('login_first_access_button'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => isCompass
                            ? const CompassFirstAccessScreen()
                            : const OnboardingScreen(),
                      ),
                    ),
                    child: Text(
                      isCompass
                          ? 'Primeiro acesso'
                          : 'Criar minha conta de Vistoriador',
                    ),
                  ),
                  TextButton(
                    key: const Key('login_forgot_password_button'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Recuperacao de senha sera validada no proximo pacote de autenticacao.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Esqueci minha senha'),
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
