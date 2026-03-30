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

  String _tipoSelecionado = 'CLT';
  int _currentPage = 0;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _bancoController = TextEditingController();
  final _agenciaController = TextEditingController();
  final _contaController = TextEditingController();

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  bool _loading = false;

  bool get _isPj => _tipoSelecionado == 'PJ';

  int get _totalPages => _isPj ? 3 : 2;

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _bancoController.dispose();
    _agenciaController.dispose();
    _contaController.dispose();
    super.dispose();
  }

  void _nextPage() {
    bool valid = true;
    if (_currentPage == 1) {
      valid = _formKeyStep2.currentState?.validate() ?? false;
    }
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
    final formValid = _formKeyStep2.currentState?.validate() ?? false;
    if (_isPj) {
      final bankValid = _formKeyStep1.currentState?.validate() ?? false;
      if (!formValid && !bankValid) return;
    } else if (!formValid) {
      return;
    }

    setState(() => _loading = true);
    try {
      final authState = context.read<AuthState>();
      final appState = context.read<AppState>();

      await authState.completeOnboarding(
        nome: _nomeController.text,
        tipo: _tipoSelecionado,
        cpf: _isPj ? null : _cpfController.text,
        cnpj: _isPj ? _cnpjController.text : null,
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
        title: const Text('Cadastro'),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevPage,
              )
            : null,
      ),
      body: Column(
        children: [
          _OnboardingProgress(
            current: _currentPage + 1,
            total: _totalPages,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _StepTipoUsuario(
                  selected: _tipoSelecionado,
                  onChanged: (tipo) => setState(() => _tipoSelecionado = tipo),
                ),
                _StepDadosPessoais(
                  formKey: _formKeyStep2,
                  isPj: _isPj,
                  nomeController: _nomeController,
                  cpfController: _cpfController,
                  cnpjController: _cnpjController,
                ),
                if (_isPj)
                  _StepDadosBancarios(
                    formKey: _formKeyStep1,
                    bancoController: _bancoController,
                    agenciaController: _agenciaController,
                    contaController: _contaController,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton(
              key: const Key('onboarding_next_button'),
              onPressed: _loading ? null : _nextPage,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentPage < _totalPages - 1 ? 'Continuar' : 'Concluir',
                    ),
            ),
          ),
        ],
      ),
    );
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

class _StepTipoUsuario extends StatelessWidget {
  const _StepTipoUsuario({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Qual é o seu vínculo?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione o tipo de cadastro para configurar seus dados.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        _TipoCard(
          key: const Key('tipo_clt'),
          titulo: 'CLT',
          descricao: 'Trabalhador com carteira assinada',
          icon: Icons.badge_outlined,
          selected: selected == 'CLT',
          onTap: () => onChanged('CLT'),
        ),
        const SizedBox(height: 12),
        _TipoCard(
          key: const Key('tipo_pj'),
          titulo: 'PJ',
          descricao: 'Pessoa Jurídica / Prestador de serviços',
          icon: Icons.business_outlined,
          selected: selected == 'PJ',
          onTap: () => onChanged('PJ'),
        ),
      ],
    );
  }
}

class _TipoCard extends StatelessWidget {
  const _TipoCard({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String titulo;
  final String descricao;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _StepDadosPessoais extends StatelessWidget {
  const _StepDadosPessoais({
    required this.formKey,
    required this.isPj,
    required this.nomeController,
    required this.cpfController,
    required this.cnpjController,
  });

  final GlobalKey<FormState> formKey;
  final bool isPj;
  final TextEditingController nomeController;
  final TextEditingController cpfController;
  final TextEditingController cnpjController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Seus dados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
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
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),
          if (!isPj)
            TextFormField(
              key: const Key('onboarding_cpf_field'),
              controller: cpfController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CPF',
                prefixIcon: Icon(Icons.credit_card_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o CPF' : null,
            ),
          if (isPj)
            TextFormField(
              key: const Key('onboarding_cnpj_field'),
              controller: cnpjController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o CNPJ' : null,
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
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bancoController;
  final TextEditingController agenciaController;
  final TextEditingController contaController;

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
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o banco' : null,
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe' : null,
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
