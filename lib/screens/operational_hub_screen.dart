import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home_location_snapshot.dart';
import '../services/app_navigation_coordinator.dart';
import '../services/home_location_service.dart';
import '../services/location_service.dart';
import '../services/operational_hub_registry_service.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../widgets/home/location_status_card.dart';
import '../widgets/home/startup_status_card.dart';
import '../widgets/operational_hub_grid.dart';
import '../services/inspection_export_service.dart';

class OperationalHubScreen extends StatefulWidget {
  final AppNavigationCoordinator navigationCoordinator;

  const OperationalHubScreen({
    super.key,
    this.navigationCoordinator = const DefaultAppNavigationCoordinator(),
  });

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

        comparison =
            d < 1000
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

  Future<void> _resetOnboardingMock() async {
    final authState = context.read<AuthState>();
    await authState.resetOnboardingForMock();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Onboarding mock resetado. Reinicie o cadastro para validar o fluxo PJ.',
        ),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final items = const OperationalHubRegistryService().items();
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Hub operacional')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Centrais integradas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ferramentas operacionais de mock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use para reiniciar o onboarding sem reinstalar o app.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resetOnboardingMock,
                    icon: const Icon(Icons.restart_alt_outlined),
                    label: const Text('Resetar mock de onboarding'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _ExportSettingsCard(),
          const SizedBox(height: 16),
          OperationalHubGrid(
            items: items,
            onTap:
                (item) => widget.navigationCoordinator.openOperationalHubItem(
                  context,
                  itemId: item.id,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExportSettingsCard extends StatefulWidget {
  const _ExportSettingsCard();

  @override
  State<_ExportSettingsCard> createState() => _ExportSettingsCardState();
}

class _ExportSettingsCardState extends State<_ExportSettingsCard> {
  final InspectionExportService _exportService = InspectionExportService();
  late TextEditingController _folderController;

  InspectionExportDirectoryMode _exportMode =
      InspectionExportDirectoryMode.internal;
  bool _loading = true;
  bool _usingExternalBase = false;
  late TextEditingController _retentionController;
  bool _purging = false;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(text: 'inspection_exports');
    _loadSettings();
    _retentionController = TextEditingController(text: '30');
  }

  @override
  void dispose() {
    _folderController.dispose();
    _retentionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _exportService.resolveEffectiveSettings();
      final retentionDays = await _exportService.loadRetentionDays();
      if (!mounted) return;
      setState(() {
        _exportMode = settings.mode;
        _usingExternalBase = settings.usingExternalBase;
        _folderController.text = settings.folderName;
        _retentionController.text = retentionDays.toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await _exportService.configureExportDirectory(
      mode: _exportMode,
      folderName: _folderController.text,
    );
    final retentionDays = int.tryParse(_retentionController.text.trim()) ?? 30;
    await _exportService.configureRetentionDays(retentionDays.clamp(0, 3650));
    final effectiveSettings = await _exportService.resolveEffectiveSettings();
    if (!mounted) return;
    setState(() {
      _usingExternalBase = effectiveSettings.usingExternalBase;
    });
    final message =
        effectiveSettings.mode == InspectionExportDirectoryMode.external &&
                !effectiveSettings.usingExternalBase
            ? 'Salvo. Diretório externo indisponível; usando interno automaticamente.'
            : 'Configuração de exportação salva.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _purgeNow() async {
    final retentionDays = int.tryParse(_retentionController.text.trim()) ?? 30;
    if (retentionDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Retenção definida como 0: nenhum arquivo é excluído automaticamente.',
          ),
        ),
      );
      return;
    }
    setState(() => _purging = true);
    final deleted = await _exportService.purgeOldExports(
      retentionDays: retentionDays,
    );
    if (!mounted) return;
    setState(() => _purging = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted == 0
              ? 'Nenhum arquivo removido (todos dentro do período de $retentionDays dias).'
              : '$deleted arquivo(s) removido(s) com mais de $retentionDays dia(s).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exportação da vistoria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configuração do destino dos JSONs exportados.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else ...[
              DropdownButtonFormField<InspectionExportDirectoryMode>(
                initialValue: _exportMode,
                decoration: const InputDecoration(
                  labelText: 'Destino da exportação JSON',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: InspectionExportDirectoryMode.internal,
                    child: Text('Interno (recomendado)'),
                  ),
                  DropdownMenuItem(
                    value: InspectionExportDirectoryMode.external,
                    child: Text('Externo (quando disponível)'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _exportMode = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _folderController,
                decoration: const InputDecoration(
                  labelText: 'Subdiretório de exportação',
                  border: OutlineInputBorder(),
                  helperText:
                      'Exemplo: inspection_exports ou operacao/json/vistorias',
                ),
              ),
              if (_exportMode == InspectionExportDirectoryMode.external &&
                  !_usingExternalBase)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Neste dispositivo, o diretório externo pode não estar disponível. O app fará fallback automático para o diretório interno.',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(height: 28),
              const Text(
                'Retenção de arquivos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Defina por quantos dias os JSONs exportados são mantidos. '
                'Use 0 para nunca limpar automaticamente.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _retentionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dias de retenção (0 = nunca limpar)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _saveSettings,
                    child: const Text('Salvar configuração'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _purging ? null : _purgeNow,
                    icon:
                        _purging
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text('Limpar agora'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
