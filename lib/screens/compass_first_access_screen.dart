import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../branding/brand_provider.dart';
import '../branding/brand_tokens.dart';
import '../l10n/app_strings.dart';
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
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: BrandTokens.background,
      appBar: AppBar(title: Text(strings.tr('Primeiro acesso', 'First access'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.verified_user_outlined, size: 56, color: tokens.primary),
              const SizedBox(height: 16),
              Text(
                strings.tr('Ative seu acesso Compass', 'Activate your Compass access'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BrandTokens.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.tr(
                  'Use os dados ja cadastrados pela empresa. Vamos localizar seu cadastro e enviar um codigo de confirmacao para o seu contato salvo.',
                  'Use the data already registered by the company. We will locate your profile and send a confirmation code to your saved contact.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: BrandTokens.textSecondary, height: 1.35),
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
    final strings = AppStrings.of(context);
    return Form(
      key: _lookupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('compass_first_access_cpf_field'),
            controller: _cpfController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.tr('CPF', 'CPF'),
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('compass_first_access_birth_date_field'),
            controller: _birthDateController,
            keyboardType: TextInputType.number,
            inputFormatters: const <TextInputFormatter>[
              _BirthDateTextInputFormatter(),
            ],
            decoration: InputDecoration(
              labelText: strings.tr('Data de nascimento', 'Birth date'),
              hintText: 'dd/mm/yyyy',
              prefixIcon: const Icon(Icons.event_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (_required(value) != null) return _required(value);
              return _normalizeBirthDate(value!).isEmpty
                  ? strings.tr('Use o formato dd/mm/aaaa', 'Use the dd/mm/yyyy format')
                  : null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('compass_first_access_identifier_field'),
            controller: _identifierController,
            decoration: InputDecoration(
              labelText: strings.tr('Identificador da empresa', 'Company identifier'),
              hintText: strings.tr(
                'Matricula, codigo ou ID informado pela Compass',
                'Registration, code or ID provided by Compass',
              ),
              prefixIcon: const Icon(Icons.business_center_outlined),
              border: const OutlineInputBorder(),
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
                : Text(strings.tr('Enviar codigo de ativacao', 'Send activation code')),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    final strings = AppStrings.of(context);
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
          if (_challenge!.debugOtp != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.tr(
                      'Codigo de teste do ambiente local',
                      'Local environment test code',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _challenge!.debugOtp!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: BrandTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.tr(
                      'Use esse codigo apenas para o teste funcional local.',
                      'Use this code only for local functional testing.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BrandTokens.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          TextFormField(
            key: const Key('compass_first_access_otp_field'),
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.tr('Codigo de confirmacao', 'Confirmation code'),
              prefixIcon: const Icon(Icons.pin_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('compass_first_access_password_field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: strings.tr('Criar senha', 'Create password'),
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
              return value!.length < 8
                  ? strings.tr('Use ao menos 8 caracteres', 'Use at least 8 characters')
                  : null;
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
                : Text(strings.tr('Ativar e entrar', 'Activate and sign in')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loading ? null : _start,
            child: Text(strings.tr('Reenviar codigo', 'Resend code')),
          ),
          TextButton(
            onPressed: _loading ? null : () => setState(() => _challenge = null),
            child: Text(strings.tr('Corrigir meus dados', 'Correct my details')),
          ),
          TextButton(
            onPressed: _loading ? null : _showHelp,
            child: Text(strings.tr('Nao recebi o codigo', 'I did not receive the code')),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    final strings = AppStrings.of(context);
    return value == null || value.trim().isEmpty
        ? strings.tr('Campo obrigatorio', 'Required field')
        : null;
  }

  String _normalizeBirthDate(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return '';
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
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

  void _showHelp() {
    if (!mounted) return;
    final strings = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.tr('Como encontrar o codigo', 'How to find the code'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BrandTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.tr(
                    '1. Verifique o telefone ou e-mail mostrado acima.',
                    '1. Check the phone number or email shown above.',
                  ),
                  style: const TextStyle(color: BrandTokens.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.tr(
                    '2. Se o codigo nao chegou, toque em "Reenviar codigo".',
                    '2. If the code did not arrive, tap "Resend code".',
                  ),
                  style: const TextStyle(color: BrandTokens.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.tr(
                    '3. Se o problema continuar, procure o administrador da sua empresa para confirmar o contato cadastrado.',
                    '3. If the problem continues, contact your company administrator to confirm the registered contact.',
                  ),
                  style: const TextStyle(color: BrandTokens.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BirthDateTextInputFormatter extends TextInputFormatter {
  const _BirthDateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var index = 0; index < limited.length; index++) {
      if (index == 2 || index == 4) {
        buffer.write('/');
      }
      buffer.write(limited[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
