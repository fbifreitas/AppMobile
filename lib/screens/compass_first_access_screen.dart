import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../branding/brand_provider.dart';
import '../branding/brand_tokens.dart';
import '../services/mobile_auth_service.dart';
import '../state/auth_state.dart';

class CompassFirstAccessScreen extends StatefulWidget {
  const CompassFirstAccessScreen({
    super.key,
    this.authService = const MobileBackendAuthService(),
  });

  final MobileBackendAuthService authService;

  @override
  State<CompassFirstAccessScreen> createState() =>
      _CompassFirstAccessScreenState();
}

class _CompassFirstAccessScreenState extends State<CompassFirstAccessScreen> {
  final _lookupFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  MobileFirstAccessChallenge? _challenge;
  bool _loading = false;
  bool _obscurePassword = true;

  static const String _tenantId = String.fromEnvironment(
    'APP_TENANT_ID',
    defaultValue: 'tenant-compass',
  );

  @override
  void dispose() {
    _cpfController.dispose();
    _birthDateController.dispose();
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!(_lookupFormKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final challenge = await widget.authService.startFirstAccess(
        tenantId: _tenantId,
        cpf: _cpfController.text,
        birthDate: _normalizeBirthDate(_birthDateController.text),
        identifier: _identifierController.text,
      );
      if (!mounted) return;
      setState(() => _challenge = challenge);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final session = await widget.authService.completeFirstAccess(
        tenantId: _tenantId,
        challengeId: _challenge!.challengeId,
        otp: _otpController.text,
        newPassword: _passwordController.text,
        deviceInfo: 'mobile-compass-first-access',
      );
      if (!mounted) return;
      await context.read<AuthState>().applyBackendSession(session);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    final tokens = config.tokens;

    return Scaffold(
      backgroundColor: BrandTokens.background,
      appBar: AppBar(title: const Text('Primeiro acesso')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.verified_user_outlined, size: 56, color: tokens.primary),
              const SizedBox(height: 16),
              const Text(
                'Ative seu acesso Compass',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandTokens.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use os dados ja cadastrados pela empresa. CPF e data de nascimento localizam seu cadastro; a ativacao exige codigo OTP enviado ao contato cadastrado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BrandTokens.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 28),
              if (_challenge == null) _buildLookupForm() else _buildOtpForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLookupForm() {
    return Form(
      key: _lookupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('compass_first_access_cpf_field'),
            controller: _cpfController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'CPF',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('compass_first_access_birth_date_field'),
            controller: _birthDateController,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Data de nascimento',
              hintText: 'dd/mm/aaaa',
              prefixIcon: Icon(Icons.event_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_required(value) != null) return _required(value);
              return _normalizeBirthDate(value!).isEmpty
                  ? 'Use o formato dd/mm/aaaa'
                  : null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('compass_first_access_identifier_field'),
            controller: _identifierController,
            decoration: const InputDecoration(
              labelText: 'Identificador da empresa',
              hintText: 'Matricula, codigo ou ID informado pela Compass',
              prefixIcon: Icon(Icons.business_center_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 22),
          FilledButton(
            key: const Key('compass_first_access_start_button'),
            onPressed: _loading ? null : _start,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar codigo de ativacao'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _challenge!.deliveryHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BrandTokens.textSecondary),
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const Key('compass_first_access_otp_field'),
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Codigo OTP',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('compass_first_access_password_field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Criar senha',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
              ),
            ),
            validator: (value) {
              if (_required(value) != null) return _required(value);
              return value!.length < 8 ? 'Use ao menos 8 caracteres' : null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            key: const Key('compass_first_access_complete_button'),
            onPressed: _loading ? null : _complete,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ativar e entrar'),
          ),
          TextButton(
            onPressed: _loading ? null : () => setState(() => _challenge = null),
            child: const Text('Corrigir meus dados'),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatorio' : null;
  }

  String _normalizeBirthDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) return '';
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return '';
    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
      return '';
    }
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}
