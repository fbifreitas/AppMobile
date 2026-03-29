import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home_location_snapshot.dart';
import '../models/operational_hub_item.dart';
import '../services/home_location_service.dart';
import '../services/location_service.dart';
import '../services/operational_hub_registry_service.dart';
import '../state/app_state.dart';
import '../state/field_operation_state.dart';
import '../widgets/home/location_status_card.dart';
import '../widgets/home/startup_status_card.dart';
import '../widgets/operational_hub_grid.dart';
import 'admin_remote_config_center_screen.dart';
import 'assistive_intelligence_center_screen.dart';
import 'checkin_screen.dart';
import 'clean_code_audit_center_screen.dart';
import 'data_governance_center_screen.dart';
import 'field_operations_center_screen.dart';
import 'fallback_audit_center_screen.dart';
import 'mock_data_control_screen.dart';
import 'observability_support_center_screen.dart';
import 'operational_snapshot_export_screen.dart';
import 'production_readiness_center_screen.dart';
import 'quality_stability_center_screen.dart';

class OperationalHubScreen extends StatefulWidget {
  const OperationalHubScreen({super.key});

  @override
  State<OperationalHubScreen> createState() => _OperationalHubScreenState();
}

class _OperationalHubScreenState extends State<OperationalHubScreen> {
  final HomeLocationService _homeLocationService = const HomeLocationService();

  HomeLocationSnapshot _locationSnapshot = HomeLocationSnapshot.initial();

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
    _enderecoController = TextEditingController(text: appState.enderecoBase);
    _latController = TextEditingController(
      text: appState.residenciaLat?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: appState.residenciaLng?.toString() ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLocation();
    });
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    if (!mounted) return;

    setState(() {
      _locationSnapshot = _locationSnapshot.copyWith(
        loading: true,
        clearErrorMessage: true,
      );
    });

    final updatedSnapshot = await _homeLocationService.refresh(
      current: _locationSnapshot,
      readCurrentLocation: () async {
        final position = await LocationService().getCurrentLocation();
        return HomeLocationPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
      writeLocation: (latitude, longitude) {
        context.read<AppState>().atualizarUltimaLocalizacao(
              latitude,
              longitude,
            );
      },
    );

    if (!mounted) return;

    setState(() {
      _locationSnapshot = updatedSnapshot;
    });
  }

  Future<void> _readCurrentLocationForTestConfig() async {
    setState(() {
      _loadingCurrentLocation = true;
      _comparisonText = null;
    });

    try {
      final pos = await LocationService().getCurrentLocation();
      final lat = pos.latitude;
      final lng = pos.longitude;

      final configuredLat = double.tryParse(
        _latController.text.replaceAll(',', '.'),
      );
      final configuredLng = double.tryParse(
        _lngController.text.replaceAll(',', '.'),
      );

      String? comparison;
      if (configuredLat != null && configuredLng != null) {
        final d = LocationService().calcularDistancia(
          lat1: lat,
          lon1: lng,
          lat2: configuredLat,
          lon2: configuredLng,
        );

        comparison = d < 1000
            ? 'Diferença entre localização atual e configurada: ${d.toStringAsFixed(0)}m'
            : 'Diferença entre localização atual e configurada: ${(d / 1000).toStringAsFixed(2)} km';
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

  void _saveTestAddressConfig() {
    final appState = context.read<AppState>();
    final lat = double.tryParse(_latController.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lngController.text.replaceAll(',', '.'));

    appState.setEnderecoBase(_enderecoController.text.trim());
    appState.setResidencia(lat: lat, lng: lng);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuração de endereço para teste atualizada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = const OperationalHubRegistryService().items();
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub operacional'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Centrais integradas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse o fluxo principal e os painéis técnicos a partir de um único ponto.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          StartupStatusCard(
            isLoadingJobs: appState.isLoadingJobs,
            jobsCount: appState.jobs.length,
            jobsLoadError: appState.jobsLoadError,
          ),
          const SizedBox(height: 12),
          LocationStatusCard(
            loading: _locationSnapshot.loading,
            errorMessage: _locationSnapshot.errorMessage,
            lastSyncAt: _locationSnapshot.lastSyncAt,
            latitude: appState.ultimaLatitude ?? _locationSnapshot.latitude,
            longitude: appState.ultimaLongitude ?? _locationSnapshot.longitude,
            onRefresh: _refreshLocation,
          ),
          const SizedBox(height: 12),
          _TestAddressConfigurationCard(
            enderecoController: _enderecoController,
            latController: _latController,
            lngController: _lngController,
            currentLat: _currentLat,
            currentLng: _currentLng,
            comparisonText: _comparisonText,
            loadingCurrentLocation: _loadingCurrentLocation,
            onReadCurrentLocation: _readCurrentLocationForTestConfig,
            onUseCurrentLocation: _useCurrentLocationAsConfigured,
            onSave: _saveTestAddressConfig,
          ),
          const SizedBox(height: 16),
          OperationalHubGrid(
            items: items,
            onTap: (item) => _open(context, item),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, OperationalHubItem item) {
    Widget destination;

    switch (item.id) {
      case 'checkin':
        destination = const CheckinScreen();
        break;
      case 'field_ops':
        destination = ChangeNotifierProvider<FieldOperationState>(
          create: (_) => FieldOperationState.demo(),
          child: const FieldOperationsCenterScreen(),
        );
        break;
      case 'assistive':
        destination = const AssistiveIntelligenceCenterScreen();
        break;
      case 'quality':
        destination = const QualityStabilityCenterScreen();
        break;
      case 'fallback_audit':
        destination = const FallbackAuditCenterScreen();
        break;
      case 'observability':
        destination = const ObservabilitySupportCenterScreen();
        break;
      case 'governance':
        destination = const DataGovernanceCenterScreen();
        break;
      case 'production':
        destination = const ProductionReadinessCenterScreen();
        break;
      case 'admin':
        destination = const AdminRemoteConfigCenterScreen();
        break;
      case 'clean_code':
        destination = const CleanCodeAuditCenterScreen();
        break;
      case 'export':
        destination = const OperationalSnapshotExportScreen();
        break;
      case 'mock_data':
        destination = const MockDataControlScreen();
        break;
      default:
        destination = const CheckinScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}

class _TestAddressConfigurationCard extends StatelessWidget {
  const _TestAddressConfigurationCard({
    required this.enderecoController,
    required this.latController,
    required this.lngController,
    required this.currentLat,
    required this.currentLng,
    required this.comparisonText,
    required this.loadingCurrentLocation,
    required this.onReadCurrentLocation,
    required this.onUseCurrentLocation,
    required this.onSave,
  });

  final TextEditingController enderecoController;
  final TextEditingController latController;
  final TextEditingController lngController;
  final String? currentLat;
  final String? currentLng;
  final String? comparisonText;
  final bool loadingCurrentLocation;
  final VoidCallback onReadCurrentLocation;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuração de Endereço para Teste',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: enderecoController,
              decoration: const InputDecoration(
                labelText: 'Meu Endereço Base',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude Configurada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude Configurada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loadingCurrentLocation ? null : onReadCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                loadingCurrentLocation
                    ? 'Lendo...'
                    : 'Ler Localização do Celular',
              ),
            ),
            if (currentLat != null && currentLng != null) ...[
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
                    Text('Latitude atual: $currentLat'),
                    const SizedBox(height: 4),
                    Text('Longitude atual: $currentLng'),
                    if (comparisonText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        comparisonText!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: onUseCurrentLocation,
                      child: const Text(
                        'Usar localização atual na configuração',
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (comparisonText != null) ...[
              const SizedBox(height: 12),
              Text(comparisonText!),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onSave,
              child: const Text('Salvar configuração de teste'),
            ),
          ],
        ),
      ),
    );
  }
}
