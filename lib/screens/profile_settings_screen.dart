import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cpfController;
  late TextEditingController _cnpjController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthState>();
    _nomeController = TextEditingController(text: authState.userNome ?? '');
    _cpfController = TextEditingController(text: authState.userCpf ?? '');
    _cnpjController = TextEditingController(text: authState.userCnpj ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final authState = context.read<AuthState>();
      final appState = context.read<AppState>();
      final isPj = authState.userTipo == 'PJ';

      await authState.updateProfile(
        nome: _nomeController.text,
        cpf: isPj ? null : _cpfController.text,
        cnpj: isPj ? _cnpjController.text : null,
      );
      appState.setUsuarioNomeCompleto(_nomeController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).tr(
              'Dados atualizados com sucesso.',
              'Profile updated successfully.',
            ),
          ),
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final authState = context.watch<AuthState>();
    final isPj = authState.userTipo == 'PJ';

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Dados cadastrais', 'Profile details')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (authState.userTipo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Chip(
                  label: Text(
                    '${strings.tr('Vinculo', 'Relationship')}: ${authState.userTipo}',
                  ),
                  avatar: const Icon(Icons.badge_outlined, size: 16),
                ),
              ),
            TextFormField(
              key: const Key('profile_nome_field'),
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: strings.tr('Nome completo', 'Full name'),
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? strings.tr('Informe o nome', 'Enter the name')
                  : null,
            ),
            const SizedBox(height: 16),
            if (!isPj)
              TextFormField(
                key: const Key('profile_cpf_field'),
                controller: _cpfController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.tr('CPF', 'CPF'),
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
            if (isPj)
              TextFormField(
                key: const Key('profile_cnpj_field'),
                controller: _cnpjController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.tr('CNPJ', 'CNPJ'),
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
            if (authState.userEmail != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: authState.userEmail,
                decoration: InputDecoration(
                  labelText: strings.tr(
                    'E-mail (somente leitura)',
                    'Email (read-only)',
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              key: const Key('profile_save_button'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(strings.tr('Salvar alteracoes', 'Save changes')),
            ),
          ],
        ),
      ),
    );
  }
}
