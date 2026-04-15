import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/home_location_snapshot.dart';
import '../services/app_navigation_coordinator.dart';
import '../services/home_location_service.dart';
import '../services/inspection_export_service.dart';
import '../services/location_service.dart';
import '../services/operational_hub_registry_service.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../widgets/home/location_status_card.dart';
import '../widgets/home/startup_status_card.dart';
import '../widgets/operational_hub_grid.dart';

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
    final strings = AppStrings.of(context);
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
                ? strings.tr(
                  'Diferenca entre localizacao atual e configurada: ${d.toStringAsFixed(0)}m',
                  'Difference between current and configured location: ${d.toStringAsFixed(0)}m',
                )
                : strings.tr(
                  'Diferenca entre localizacao atual e configurada: ${(d / 1000).toStringAsFixed(2)} km',
                  'Difference between current and configured location: ${(d / 1000).toStringAsFixed(2)} km',
                );
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
        _comparisonText = strings.tr(
          'Nao foi possivel ler a localizacao atual: $e',
          'Could not read the current location: $e',
        );
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
    final strings = AppStrings.of(context);
    final lat = double.tryParse(_latController.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lngController.text.replaceAll(',', '.'));

    appState.setEnderecoBase(_enderecoController.text.trim());
    appState.setResidencia(lat: lat, lng: lng);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.tr(
            'Configuracao de endereco para teste atualizada.',
            'Test address configuration updated.',
          ),
        ),
      ),
    );
  }

  Future<void> _resetOnboardingMock() async {
    final authState = context.read<AuthState>();
    final strings = AppStrings.of(context);
    await authState.resetOnboardingForMock();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.tr(
            'Onboarding mock resetado. Reinicie o cadastro para validar o fluxo PJ.',
            'Mock onboarding reset. Restart registration to validate the business flow.',
          ),
        ),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final items = const OperationalHubRegistryService().items();
    final appState = context.watch<AppState>();
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Hub operacional', 'Operational hub')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.tr('Centrais integradas', 'Integrated centers'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              'Acesse o fluxo principal e os paineis tecnicos a partir de um unico ponto.',
              'Access the main flow and technical panels from a single place.',
            ),
            style: const TextStyle(fontSize: 12),
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
                  Text(
                    strings.tr(
                      'Ferramentas operacionais de mock',
                      'Mock operational tools',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.tr(
                      'Use para reiniciar o onboarding sem reinstalar o app.',
                      'Use this to restart onboarding without reinstalling the app.',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resetOnboardingMock,
                    icon: const Icon(Icons.restart_alt_outlined),
                    label: Text(
                      strings.tr(
                        'Resetar mock de onboarding',
                        'Reset onboarding mock',
                      ),
                    ),
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
    final strings = AppStrings.of(context);
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
            ? strings.tr(
              'Salvo. Diretorio externo indisponivel; usando interno automaticamente.',
              'Saved. External directory unavailable; using internal automatically.',
            )
            : strings.tr(
              'Configuracao de exportacao salva.',
              'Export configuration saved.',
            );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _purgeNow() async {
    final strings = AppStrings.of(context);
    final retentionDays = int.tryParse(_retentionController.text.trim()) ?? 30;
    if (retentionDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              'Retencao definida como 0: nenhum arquivo e excluido automaticamente.',
              'Retention set to 0: no file is deleted automatically.',
            ),
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
              ? strings.tr(
                'Nenhum arquivo removido (todos dentro do periodo de $retentionDays dias).',
                'No file removed (all within the $retentionDays-day period).',
              )
              : strings.tr(
                '$deleted arquivo(s) removido(s) com mais de $retentionDays dia(s).',
                '$deleted file(s) removed with more than $retentionDays day(s).',
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.tr('Exportacao da vistoria', 'Inspection export'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              strings.tr(
                'Configuracao do destino dos JSONs exportados.',
                'Configuration of the destination for exported JSON files.',
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else ...[
              DropdownButtonFormField<InspectionExportDirectoryMode>(
                initialValue: _exportMode,
                decoration: InputDecoration(
                  labelText: strings.tr(
                    'Destino da exportacao JSON',
                    'JSON export destination',
                  ),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: InspectionExportDirectoryMode.internal,
                    child: Text(
                      strings.tr(
                        'Interno (recomendado)',
                        'Internal (recommended)',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: InspectionExportDirectoryMode.external,
                    child: Text(
                      strings.tr(
                        'Externo (quando disponivel)',
                        'External (when available)',
                      ),
                    ),
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
                decoration: InputDecoration(
                  labelText: strings.tr(
                    'Subdiretorio de exportacao',
                    'Export subdirectory',
                  ),
                  border: const OutlineInputBorder(),
                  helperText: strings.tr(
                    'Exemplo: inspection_exports ou operacao/json/vistorias',
                    'Example: inspection_exports or operacao/json/vistorias',
                  ),
                ),
              ),
              if (_exportMode == InspectionExportDirectoryMode.external &&
                  !_usingExternalBase)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    strings.tr(
                      'Neste dispositivo, o diretorio externo pode nao estar disponivel. O app fara fallback automatico para o diretorio interno.',
                      'On this device, the external directory may be unavailable. The app will automatically fall back to the internal directory.',
                    ),
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(height: 28),
              Text(
                strings.tr('Retencao de arquivos', 'File retention'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                strings.tr(
                  'Defina por quantos dias os JSONs exportados sao mantidos. Use 0 para nunca limpar automaticamente.',
                  'Define how many days exported JSON files are kept. Use 0 to never clean automatically.',
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _retentionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.tr(
                    'Dias de retencao (0 = nunca limpar)',
                    'Retention days (0 = never clean)',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _saveSettings,
                    child: Text(
                      strings.tr(
                        'Salvar configuracao',
                        'Save configuration',
                      ),
                    ),
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
                    label: Text(strings.tr('Limpar agora', 'Clean now')),
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
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.tr(
                'Configuracao de Endereco para Teste',
                'Test Address Configuration',
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: enderecoController,
              decoration: InputDecoration(
                labelText: strings.tr(
                  'Meu Endereco Base',
                  'My Base Address',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: strings.tr(
                  'Latitude Configurada',
                  'Configured Latitude',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: strings.tr(
                  'Longitude Configurada',
                  'Configured Longitude',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loadingCurrentLocation ? null : onReadCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                loadingCurrentLocation
                    ? strings.tr('Lendo...', 'Reading...')
                    : strings.tr(
                      'Ler Localizacao do Celular',
                      'Read Device Location',
                    ),
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
                    Text(
                      strings.tr(
                        'Latitude atual: $currentLat',
                        'Current latitude: $currentLat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.tr(
                        'Longitude atual: $currentLng',
                        'Current longitude: $currentLng',
                      ),
                    ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onSave,
                  child: Text(
                    strings.tr(
                      'Salvar configuracao de teste',
                      'Save test configuration',
                    ),
                  ),
                ),
                if (currentLat != null && currentLng != null)
                  OutlinedButton(
                    onPressed: onUseCurrentLocation,
                    child: Text(
                      strings.tr(
                        'Usar localizacao atual',
                        'Use current location',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
