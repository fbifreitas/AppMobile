import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _enderecoController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _enderecoController = TextEditingController(text: appState.enderecoBase);
    _latController = TextEditingController(
      text: appState.residenciaLat?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: appState.residenciaLng?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Modo desenvolvedor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Permitir iniciar longe do local'),
            subtitle: const Text(
              'Quando ligado, o botão da vistoria fica liberado mesmo fora do raio do imóvel.',
            ),
            value: appState.permitirIniciarLonge,
            onChanged: (value) {
              appState.setPermitirIniciarLonge(value);
            },
          ),
          const Divider(height: 32),
          const Text(
            'Dados mockados do vistoriador',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _enderecoController,
            decoration: const InputDecoration(
              labelText: 'Meu endereço base',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _latController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Latitude base',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lngController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Longitude base',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(_latController.text.replaceAll(',', '.'));
              final lng = double.tryParse(_lngController.text.replaceAll(',', '.'));

              appState.setEnderecoBase(_enderecoController.text.trim());
              appState.setResidencia(
                lat: lat,
                lng: lng,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações atualizadas.')),
              );
            },
            child: const Text('Salvar configurações'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Comportamento da distância',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'A distância é calculada com a geolocalização atual do aparelho. '
            'A tela também atualiza a localização ao abrir e ao puxar para atualizar.',
          ),
        ],
      ),
    );
  }
}