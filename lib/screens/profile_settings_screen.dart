import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        const SnackBar(content: Text('Dados atualizados com sucesso.')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final isPj = authState.userTipo == 'PJ';

    return Scaffold(
      appBar: AppBar(title: const Text('Dados cadastrais')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (authState.userTipo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Chip(
                  label: Text('Vínculo: ${authState.userTipo}'),
                  avatar: const Icon(Icons.badge_outlined, size: 16),
                ),
              ),
            TextFormField(
              key: const Key('profile_nome_field'),
              controller: _nomeController,
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
                key: const Key('profile_cpf_field'),
                controller: _cpfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            if (isPj)
              TextFormField(
                key: const Key('profile_cnpj_field'),
                controller: _cnpjController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            if (authState.userEmail != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: authState.userEmail,
                decoration: const InputDecoration(
                  labelText: 'E-mail (somente leitura)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
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
                  : const Text('Salvar alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
