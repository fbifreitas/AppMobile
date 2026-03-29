import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _developerModeTapThreshold = 7;

  late TextEditingController _nomeController;
  int _versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _nomeController = TextEditingController(text: appState.usuarioNomeCompleto);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _handleDeveloperModeHiddenTap() async {
    final appState = context.read<AppState>();

    if (!appState.developerToolsUnlocked) {
      _versionTapCount += 1;

      final remaining = _developerModeTapThreshold - _versionTapCount;
      if (remaining > 0) {
        if (remaining <= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mais $remaining toque${remaining == 1 ? '' : 's'} para habilitar a ferramenta do desenvolvedor.',
              ),
            ),
          );
        }
        return;
      }

      _versionTapCount = 0;
      await appState.unlockDeveloperTools();
      await appState.setDeveloperModeEnabled(true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ferramenta do desenvolvedor habilitada.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A ferramenta do desenvolvedor já está habilitada.',
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final appState = context.read<AppState>();
    appState.setUsuarioNomeCompleto(_nomeController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações atualizadas.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Meus dados',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome completo do usuário',
              border: OutlineInputBorder(),
            ),
          ),
          if (appState.developerToolsUnlocked &&
              appState.developerModeEnabled) ...[
            const Divider(height: 28),
            const Text(
              'Ferramentas do desenvolvedor',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Habilitar ferramenta do desenvolvedor'),
              subtitle: const Text(
                'Controla a exibição do ícone do hub técnico na Home.',
              ),
              value: appState.developerModeEnabled,
              onChanged: (value) async {
                if (!value) {
                  await appState.lockDeveloperTools();
                  return;
                }
                await appState.setDeveloperModeEnabled(true);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Permitir iniciar longe do local'),
              subtitle: const Text(
                'Quando desligado, o botão de vistoria depende da distância real até o imóvel.',
              ),
              value: appState.permitirIniciarLonge,
              onChanged: (value) async {
                await appState.setPermitirIniciarLonge(value);
              },
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _saveSettings,
            child: const Text('Salvar configurações'),
          ),
          const SizedBox(height: 24),
          Center(
            child: InkWell(
              onTap: _handleDeveloperModeHiddenTap,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Versão 1.0.0+1',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
