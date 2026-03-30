import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final valid =
        _currentPage == 0
            ? (_formKeyDadosPessoais.currentState?.validate() ?? false)
            : (_formKeyDadosBancarios.currentState?.validate() ?? false);
    if (!valid) return;

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
    final formValid = _formKeyDadosPessoais.currentState?.validate() ?? false;
    final bankValid = _formKeyDadosBancarios.currentState?.validate() ?? false;
    if (!formValid || !bankValid) {
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cadastro PJ'),
        leading:
            _currentPage > 0
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _prevPage,
                )
                : null,
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
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                            ? 'Continuar'
                            : 'Concluir',
                      ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateCnpj(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) {
      return 'Informe um CNPJ válido com 14 dígitos';
    }
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return 'CNPJ inválido';
    }
    if (!_isValidCnpjDigits(digits)) {
      return 'CNPJ inválido';
    }
    return null;
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
    final text = (value ?? '').trim();
    if (text.length < 3) {
      return 'Informe o banco (mínimo 3 caracteres)';
    }
    return null;
  }

  String? _validateAgencia(String? value) {
    final cleaned = (value ?? '').trim();
    if (!RegExp(r'^\d{3,6}$').hasMatch(cleaned)) {
      return 'Agência inválida (3 a 6 dígitos)';
    }
    return null;
  }

  String? _validateConta(String? value) {
    final cleaned = (value ?? '').trim();
    if (!RegExp(r'^\d{4,12}([\-\s]?[0-9Xx])?$').hasMatch(cleaned)) {
      return 'Conta inválida';
    }
    return null;
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Passo $current de $total',
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
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Dados da empresa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastro focado em prestador PJ. Preencha CNPJ válido para continuar.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('onboarding_nome_field'),
            controller: nomeController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_cnpj_field'),
            controller: cnpjController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'CNPJ',
              prefixIcon: Icon(Icons.business_outlined),
              border: OutlineInputBorder(),
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
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Dados bancários',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Necessário para repasse de valores por serviços prestados.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('onboarding_banco_field'),
            controller: bancoController,
            decoration: const InputDecoration(
              labelText: 'Banco',
              prefixIcon: Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Agência',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Conta',
                    border: OutlineInputBorder(),
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
