import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  int _currentPage = 0;

  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _bancoController = TextEditingController();
  final _agenciaController = TextEditingController();
  final _contaController = TextEditingController();

  final _formKeyDadosPessoais = GlobalKey<FormState>();
  final _formKeyDadosBancarios = GlobalKey<FormState>();

  bool _loading = false;

  int get _totalPages => 2;

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _cnpjController.dispose();
    _bancoController.dispose();
    _agenciaController.dispose();
    _contaController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final strings = AppStrings.of(context);
    final valid =
        _currentPage == 0
            ? (_formKeyDadosPessoais.currentState?.validate() ?? false)
            : (_formKeyDadosBancarios.currentState?.validate() ?? false);
    if (!valid) {
      final message =
          _currentPage == 0
              ? strings.tr(
                  'Preencha os dados da empresa para continuar.',
                  'Fill in company details to continue.',
                )
              : strings.tr(
                  'Preencha os dados bancarios para continuar.',
                  'Fill in bank details to continue.',
                );
      _showMessage(message);
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    final strings = AppStrings.of(context);
    final formValid =
        _validateNome(_nomeController.text) == null &&
        _validateCnpj(_cnpjController.text) == null;
    final bankValid = _formKeyDadosBancarios.currentState?.validate() ?? false;
    if (!formValid) {
      if (_currentPage != 0) {
        await _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
        );
      }
      _showMessage(
        strings.tr(
          'Revise os dados da empresa para concluir.',
          'Review company details to finish.',
        ),
      );
      return;
    }

    if (!bankValid) {
      _showMessage(
        strings.tr(
          'Revise os dados bancarios para concluir.',
          'Review bank details to finish.',
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final authState = context.read<AuthState>();
      final appState = context.read<AppState>();

      await authState.completeOnboarding(
        nome: _nomeController.text,
        tipo: 'PJ',
        cnpj: _cnpjController.text,
      );

      appState.setUsuarioNomeCompleto(_nomeController.text);
    } catch (_) {
      _showMessage(
        strings.tr(
          'Nao foi possivel concluir o cadastro agora. Tente novamente.',
          'Could not complete registration right now. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.tr('Cadastro PJ', 'Business registration')),
        leading:
            _currentPage > 0
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _prevPage,
                )
                : null,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            key: const Key('onboarding_next_button'),
            onPressed: _loading ? null : _nextPage,
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
                    : Text(
                      _currentPage < _totalPages - 1
                          ? strings.tr('Continuar', 'Continue')
                          : strings.tr('Concluir', 'Finish'),
                    ),
          ),
        ),
      ),
      body: Column(
        children: [
          _OnboardingProgress(current: _currentPage + 1, total: _totalPages),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _StepDadosPessoais(
                  formKey: _formKeyDadosPessoais,
                  nomeController: _nomeController,
                  cnpjController: _cnpjController,
                  cnpjValidator: _validateCnpj,
                ),
                _StepDadosBancarios(
                  formKey: _formKeyDadosBancarios,
                  bancoController: _bancoController,
                  agenciaController: _agenciaController,
                  contaController: _contaController,
                  bancoValidator: _validateBanco,
                  agenciaValidator: _validateAgencia,
                  contaValidator: _validateConta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _validateCnpj(String? value) {
    final strings = AppStrings.of(context);
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) {
      return strings.tr(
        'Informe um CNPJ valido com 14 digitos',
        'Enter a valid 14-digit company ID',
      );
    }
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return strings.tr('CNPJ inválido', 'Invalid company ID');
    }
    if (!_isValidCnpjDigits(digits)) {
      return strings.tr('CNPJ inválido', 'Invalid company ID');
    }
    return null;
  }

  String? _validateNome(String? value) {
    final strings = AppStrings.of(context);
    return (value == null || value.trim().isEmpty)
        ? strings.tr('Informe o nome', 'Enter the name')
        : null;
  }

  bool _isValidCnpjDigits(String digits) {
    int calc(List<int> factors, String base) {
      var sum = 0;
      for (var i = 0; i < factors.length; i++) {
        sum += int.parse(base[i]) * factors[i];
      }
      final mod = sum % 11;
      return mod < 2 ? 0 : 11 - mod;
    }

    final first = calc([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], digits);
    final second = calc([6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], digits);
    return digits.endsWith('$first$second');
  }

  String? _validateBanco(String? value) {
    final strings = AppStrings.of(context);
    final text = (value ?? '').trim();
    if (text.length < 3) {
      return strings.tr(
        'Informe o banco (minimo 3 caracteres)',
        'Enter the bank name (minimum 3 characters)',
      );
    }
    return null;
  }

  String? _validateAgencia(String? value) {
    final strings = AppStrings.of(context);
    final normalized = _normalizeBankToken(value);
    if (normalized.length < 3 || normalized.length > 7) {
      return strings.tr('Agencia invalida', 'Invalid branch number');
    }
    return null;
  }

  String? _validateConta(String? value) {
    final strings = AppStrings.of(context);
    final normalized = _normalizeBankToken(value);
    if (normalized.length < 4 || normalized.length > 13) {
      return strings.tr('Conta invalida', 'Invalid account number');
    }
    return null;
  }

  String _normalizeBankToken(String? value) {
    final cleaned = (value ?? '').trim();
    return cleaned.replaceAll(RegExp(r'[^0-9Xx]'), '');
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            strings.tr('Passo $current de $total', 'Step $current of $total'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDadosPessoais extends StatelessWidget {
  const _StepDadosPessoais({
    required this.formKey,
    required this.nomeController,
    required this.cnpjController,
    required this.cnpjValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nomeController;
  final TextEditingController cnpjController;
  final String? Function(String?) cnpjValidator;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.tr('Dados da empresa', 'Company details'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              'Cadastro focado em prestador PJ. Preencha CNPJ valido para continuar.',
              'Registration focused on business providers. Fill in a valid company ID to continue.',
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('onboarding_nome_field'),
            controller: nomeController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: strings.tr('Nome completo', 'Full name'),
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? strings.tr('Informe o nome', 'Enter the name')
                    : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_cnpj_field'),
            controller: cnpjController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.tr('CNPJ', 'Company ID'),
              prefixIcon: const Icon(Icons.business_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: cnpjValidator,
          ),
        ],
      ),
    );
  }
}

class _StepDadosBancarios extends StatelessWidget {
  const _StepDadosBancarios({
    required this.formKey,
    required this.bancoController,
    required this.agenciaController,
    required this.contaController,
    required this.bancoValidator,
    required this.agenciaValidator,
    required this.contaValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bancoController;
  final TextEditingController agenciaController;
  final TextEditingController contaController;
  final String? Function(String?) bancoValidator;
  final String? Function(String?) agenciaValidator;
  final String? Function(String?) contaValidator;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.tr('Dados bancarios', 'Bank details'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              'Necessario para repasse de valores por servicos prestados.',
              'Required for service payment transfers.',
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('onboarding_banco_field'),
            controller: bancoController,
            decoration: InputDecoration(
              labelText: strings.tr('Banco', 'Bank'),
              prefixIcon: const Icon(Icons.account_balance_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: bancoValidator,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: const Key('onboarding_agencia_field'),
                  controller: agenciaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: strings.tr('Agencia', 'Branch'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: agenciaValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: const Key('onboarding_conta_field'),
                  controller: contaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: strings.tr('Conta', 'Account'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: contaValidator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
