import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/location_service.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _enderecoController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  String? _currentLat;
  String? _currentLng;
  String? _comparisonText;
  bool _loadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _nomeController = TextEditingController(text: appState.usuarioNomeCompleto);
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
    _nomeController.dispose();
    _enderecoController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _readCurrentLocation() async {
    setState(() {
      _loadingCurrentLocation = true;
      _comparisonText = null;
    });

    try {
      final pos = await LocationService().getCurrentLocation();
      final lat = pos.latitude;
      final lng = pos.longitude;

      final configuredLat =
          double.tryParse(_latController.text.replaceAll(',', '.'));
      final configuredLng =
          double.tryParse(_lngController.text.replaceAll(',', '.'));

      String? comparison;
      if (configuredLat != null && configuredLng != null) {
        final distanceMeters = LocationService().calcularDistancia(
          lat1: lat,
          lon1: lng,
          lat2: configuredLat,
          lon2: configuredLng,
        );

        comparison = distanceMeters < 1000
            ? 'Diferença entre localização atual e configurada: ${distanceMeters.toStringAsFixed(0)}m'
            : 'Diferença entre localização atual e configurada: ${(distanceMeters / 1000).toStringAsFixed(2)} km';
      }

      if (!mounted) return;
      setState(() {
        _currentLat = lat.toStringAsFixed(6);
        _currentLng = lng.toStringAsFixed(6);
        _comparisonText = comparison;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _comparisonText = 'Não foi possível ler a localização atual: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingCurrentLocation = false);
      }
    }
  }

  void _useCurrentLocationAsConfigured() {
    if (_currentLat == null || _currentLng == null) return;
    _latController.text = _currentLat!;
    _lngController.text = _currentLng!;
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Permitir iniciar longe do local'),
            subtitle: const Text(
              'Quando desligado, o botão de vistoria depende da distância real até o imóvel.',
            ),
            value: appState.permitirIniciarLonge,
            onChanged: (value) {
              appState.setPermitirIniciarLonge(value);
            },
          ),
          const Divider(height: 28),
          const Text(
            'Meus dados',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome completo do usuário',
              border: OutlineInputBorder(),
            ),
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
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Latitude configurada',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lngController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Longitude configurada',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loadingCurrentLocation ? null : _readCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _loadingCurrentLocation
                        ? 'Lendo...'
                        : 'Ler localização do celular',
                  ),
                ),
              ),
            ],
          ),
          if (_currentLat != null && _currentLng != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.35),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latitude atual: $_currentLat'),
                  const SizedBox(height: 4),
                  Text('Longitude atual: $_currentLng'),
                  if (_comparisonText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _comparisonText!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _useCurrentLocationAsConfigured,
                    child: const Text('Usar localização atual na configuração'),
                  ),
                ],
              ),
            ),
          ] else if (_comparisonText != null) ...[
            const SizedBox(height: 12),
            Text(_comparisonText!),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(_latController.text.replaceAll(',', '.'));
              final lng = double.tryParse(_lngController.text.replaceAll(',', '.'));

              appState.setUsuarioNomeCompleto(_nomeController.text.trim());
              appState.setEnderecoBase(_enderecoController.text.trim());
              appState.setResidencia(lat: lat, lng: lng);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações atualizadas.')),
              );
            },
            child: const Text('Salvar configurações'),
          ),
        ],
      ),
    );
  }
}