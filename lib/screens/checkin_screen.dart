import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/inspection_menu_package.dart';
import '../models/checkin_step2_model.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/location_service.dart';
import '../services/voice_input_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/voice_selector_sheet.dart';

class CheckinScreen extends StatefulWidget {
  final InspectionFlowCoordinator flowCoordinator;

  const CheckinScreen({
    super.key,
    this.flowCoordinator = const DefaultInspectionFlowCoordinator(),
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  static const String _contextLevelId = 'contexto';

  bool? clientePresente;
  String? tipoImovel;
  String? subtipoImovel;
  String? porOndeComecar;
  Map<String, String> _niveisSelecionados = {};

  static const List<String> _defaultTipos = <String>[
    'Urbano',
    'Rural',
    'Comercial',
    'Industrial',
  ];

  static const Map<String, List<String>> _defaultSubtiposPorTipo = {
    'Urbano': ['Apartamento', 'Casa', 'Sobrado', 'Terreno'],
    'Rural': ['Sítio', 'Chácara', 'Fazenda'],
    'Comercial': ['Loja', 'Sala comercial', 'Galpão'],
    'Industrial': ['Fábrica', 'Armazém', 'Planta industrial'],
  };

  static const List<String> _defaultContextos = <String>[
    'Rua',
    'Área externa',
    'Área interna',
  ];

  final CheckinDynamicConfigService _dynamicConfigService =
      CheckinDynamicConfigService.instance;

  List<String> _tipos = List<String>.from(_defaultTipos);
  Map<String, List<String>> _subtiposPorTipo =
      Map<String, List<String>>.fromEntries(
        _defaultSubtiposPorTipo.entries.map(
          (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
        ),
      );
  List<String> _contextos = List<String>.from(_defaultContextos);
  List<ConfigLevelDefinition> _step1Levels = const [];
  Map<String, List<ConfigLevelDefinition>> _step1LevelsByTipoSubtipo = const {};

  final VoiceInputService _voiceService = VoiceInputService();
  bool _hydrated = false;
  bool _loadingDynamicConfig = false;

  @override
  void initState() {
    super.initState();
    _loadDynamicStep1Config();
  }

  Future<void> _loadDynamicStep1Config() async {
    setState(() => _loadingDynamicConfig = true);
    final dynamicConfig = await _dynamicConfigService.loadStep1Config(
      fallbackTipos: _defaultTipos,
      fallbackSubtiposPorTipo: _defaultSubtiposPorTipo,
      fallbackContextos: _defaultContextos,
    );
    if (!mounted) return;

    setState(() {
      _tipos = dynamicConfig.tipos;
      _subtiposPorTipo = dynamicConfig.subtiposPorTipo;
      _contextos = dynamicConfig.contextos;
      _step1Levels = dynamicConfig.levels;
      _step1LevelsByTipoSubtipo = dynamicConfig.levelsByTipoSubtipo;

      if (tipoImovel != null && !_tipos.contains(tipoImovel)) {
        tipoImovel = null;
        subtipoImovel = null;
      }

      final allowedSubtipos =
          tipoImovel == null
              ? const <String>[]
              : (_subtiposPorTipo[tipoImovel] ?? const <String>[]);
      if (subtipoImovel != null && !allowedSubtipos.contains(subtipoImovel)) {
        subtipoImovel = null;
      }

      if (porOndeComecar != null && !_contextos.contains(porOndeComecar)) {
        porOndeComecar = null;
      }

      _sanitizeSelectedLevels();

      _loadingDynamicConfig = false;
    });

    await _persistStep1();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  void _hydrateFromDraft(AppState appState) {
    if (_hydrated) return;
    _hydrated = true;

    final payload = appState.step1Payload;
    if (payload.isEmpty) return;

    clientePresente = payload['clientePresente'] as bool?;
    tipoImovel = payload['tipoImovel'] as String?;
    subtipoImovel = payload['subtipoImovel'] as String?;
    porOndeComecar = payload['porOndeComecar'] as String?;

    final rawLevels = payload['niveis'];
    if (rawLevels is Map) {
      _niveisSelecionados = rawLevels.map(
        (key, value) => MapEntry('$key', '$value'),
      );
    }

    if (porOndeComecar != null && porOndeComecar!.trim().isNotEmpty) {
      _niveisSelecionados[_contextLevelId] = porOndeComecar!.trim();
    }
  }

  Future<void> _persistStep1() async {
    final appState = context.read<AppState>();
    await appState.persistStep1Draft(
      clientePresente: clientePresente,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      porOndeComecar: porOndeComecar,
      niveis: _niveisSelecionados,
    );
  }

  List<ConfigLevelDefinition> _resolveActiveStep1Levels() {
    if (_step1Levels.isEmpty) {
      return <ConfigLevelDefinition>[
        ConfigLevelDefinition(
          id: _contextLevelId,
          label: 'Por onde deseja começar?',
          required: true,
          dependsOn: null,
          options: _contextos,
        ),
      ];
    }

    if (tipoImovel == null || subtipoImovel == null) {
      return _step1Levels;
    }

    final typedKey =
        '${tipoImovel!.trim().toLowerCase()}::${subtipoImovel!.trim().toLowerCase()}';
    final bySubtype = _step1LevelsByTipoSubtipo[typedKey];
    if (bySubtype != null && bySubtype.isNotEmpty) {
      return bySubtype;
    }
    return _step1Levels;
  }

  List<String> _optionsForLevel(ConfigLevelDefinition level) {
    if (level.id == _contextLevelId) {
      return level.options.isNotEmpty ? level.options : _contextos;
    }
    return level.options;
  }

  void _sanitizeSelectedLevels() {
    final activeLevels = _resolveActiveStep1Levels();
    final activeIds = activeLevels.map((level) => level.id).toSet();
    final next = <String, String>{};

    for (final entry in _niveisSelecionados.entries) {
      if (!activeIds.contains(entry.key)) {
        continue;
      }

      final level = activeLevels.firstWhere((item) => item.id == entry.key);
      final options = _optionsForLevel(level);
      if (options.isNotEmpty && !options.contains(entry.value)) {
        continue;
      }

      if (level.dependsOn != null && level.dependsOn!.trim().isNotEmpty) {
        final parentValue = next[level.dependsOn!.trim()];
        if (parentValue == null || parentValue.isEmpty) {
          continue;
        }
      }

      next[entry.key] = entry.value;
    }

    _niveisSelecionados = next;
    porOndeComecar = _niveisSelecionados[_contextLevelId] ?? porOndeComecar;
  }

  bool _hasRequiredLevelsSelected() {
    final activeLevels = _resolveActiveStep1Levels();
    for (final level in activeLevels.where((item) => item.required)) {
      final selected = _niveisSelecionados[level.id];
      if (selected == null || selected.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  CheckinStep2Model? _readInitialStep2(AppState appState) {
    final payload = appState.step2Payload;
    if (payload.isEmpty) return null;
    try {
      return CheckinStep2Model.fromMap(payload);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final job = appState.jobAtual;

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-in Vistoria')),
        body: const Center(child: Text('Nenhum job selecionado')),
      );
    }

    _hydrateFromDraft(appState);

    final subtipos =
        tipoImovel == null
            ? const <String>[]
            : (_subtiposPorTipo[tipoImovel] ?? const <String>[]);

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Vistoria')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Text(
              job.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job.endereco,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: LocationService().getCurrentLocation(),
              builder: (context, snapshot) {
                String texto = 'Validando GPS...';
                Color cor = AppColors.warning;
                Color fundo = AppColors.warningLight;

                if (snapshot.hasData &&
                    job.latitude != null &&
                    job.longitude != null) {
                  final pos = snapshot.data!;
                  final distancia = LocationService().calcularDistancia(
                    lat1: pos.latitude,
                    lon1: pos.longitude,
                    lat2: job.latitude!,
                    lon2: job.longitude!,
                  );

                  final raio = appState.resolveInspectionRadiusMeters(job);

                  if (distancia <= raio) {
                    texto = 'GPS confirmado no local';
                    cor = AppColors.success;
                    fundo = AppColors.successLight;
                  } else {
                    texto =
                        'Você ainda não está no raio do local (${distancia.toStringAsFixed(0)}m de ${raio.toStringAsFixed(0)}m)';
                    cor = AppColors.danger;
                    fundo = AppColors.dangerLight;
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: fundo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: cor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          texto,
                          style: TextStyle(
                            color: cor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirWhatsApp(job.telefoneCliente),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ligar(job.telefoneCliente),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Ligar', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionTitle(
              label: 'Cliente está presente?',
              onVoiceTap: _selectClientePresenteByVoice,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Sim'),
                  selected: clientePresente == true,
                  onSelected: (_) async {
                    setState(() => clientePresente = true);
                    await _persistStep1();
                  },
                ),
                ChoiceChip(
                  label: const Text('Não'),
                  selected: clientePresente == false,
                  onSelected: (_) async {
                    setState(() => clientePresente = false);
                    await _persistStep1();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (clientePresente == true) ...[
              _buildSectionTitle(
                label: 'Tipo de imóvel',
                onVoiceTap: _selectTipoByVoice,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _tipos.map((tipo) {
                      return ChoiceChip(
                        label: Text(tipo),
                        selected: tipoImovel == tipo,
                        onSelected: (_) async {
                          setState(() {
                            tipoImovel = tipo;
                            subtipoImovel = null;
                            _sanitizeSelectedLevels();
                          });
                          await _persistStep1();
                        },
                      );
                    }).toList(),
              ),
              if (tipoImovel != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle(
                  label: 'Subtipo',
                  onVoiceTap: _selectSubtipoByVoice,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      subtipos.map((subtipo) {
                        return ChoiceChip(
                          label: Text(subtipo),
                          selected: subtipoImovel == subtipo,
                          onSelected: (_) async {
                            setState(() {
                              subtipoImovel = subtipo;
                              _sanitizeSelectedLevels();
                            });
                            await _persistStep1();
                          },
                        );
                      }).toList(),
                ),
              ],
              ..._buildDynamicStep1Levels(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      tipoImovel == null
                          ? null
                          : () async {
                            final appStateRead = context.read<AppState>();
                            final flowCoordinator = widget.flowCoordinator;

                            await appStateRead.setInspectionRecoveryStage(
                              stageKey: 'checkin_step2',
                              stageLabel: 'Check-in etapa 2',
                              routeName: '/checkin_step2',
                              payload: {
                                ...appStateRead.inspectionRecoveryPayload,
                                'step1': appStateRead.step1Payload,
                                'step2': appStateRead.step2Payload,
                              },
                            );

                            if (!context.mounted) return;

                            flowCoordinator.openCheckinStep2(
                              context,
                              tipoImovel: tipoImovel!,
                              initialData: _readInitialStep2(appStateRead),
                              onContinue: (model) async {
                                await context
                                    .read<AppState>()
                                    .persistStep2Draft(model.toMap());
                              },
                            );
                          },
                  child: const Text(
                    'Ir para etapa 2 do check-in',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadingDynamicConfig ? null : _handleConfirm,
                child: const Text(
                  'Confirmar e abrir a câmera',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String label,
    required Future<void> Function() onVoiceTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Selecionar por voz',
          onPressed: onVoiceTap,
          icon: const Icon(Icons.mic_none, size: 18),
        ),
      ],
    );
  }

  Future<void> _selectClientePresenteByVoice() async {
    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: const ['Sim', 'Não'],
      title: 'Cliente está presente?',
      currentValue:
          clientePresente == null ? null : (clientePresente! ? 'Sim' : 'Não'),
    );
    if (selected == null || !mounted) return;
    setState(() => clientePresente = selected == 'Sim');
    await _persistStep1();
  }

  Future<void> _selectTipoByVoice() async {
    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: _tipos,
      title: 'Tipo de imóvel',
      currentValue: tipoImovel,
    );
    if (selected == null || !mounted) return;
    setState(() {
      tipoImovel = selected;
      subtipoImovel = null;
    });
    await _persistStep1();
  }

  Future<void> _selectSubtipoByVoice() async {
    final subtipos =
        tipoImovel == null
            ? const <String>[]
            : (_subtiposPorTipo[tipoImovel] ?? const <String>[]);
    if (subtipos.isEmpty) {
      _mostrarInfo('Selecione o tipo de imóvel antes do subtipo.');
      return;
    }

    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: subtipos,
      title: 'Subtipo',
      currentValue: subtipoImovel,
    );
    if (selected == null || !mounted) return;
    setState(() => subtipoImovel = selected);
    await _persistStep1();
  }

  Future<void> _selectLevelByVoice(
    ConfigLevelDefinition level,
    List<String> options,
  ) async {
    if (options.isEmpty) {
      _mostrarInfo('Nível "${level.label}" sem opções configuradas.');
      return;
    }

    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: options,
      title: level.label,
      currentValue: _niveisSelecionados[level.id],
    );
    if (selected == null || !mounted) return;

    setState(() {
      _niveisSelecionados[level.id] = selected;
      if (level.id == _contextLevelId) {
        porOndeComecar = selected;
      }
      _sanitizeSelectedLevels();
    });
    await _persistStep1();
  }

  List<Widget> _buildDynamicStep1Levels() {
    final activeLevels = _resolveActiveStep1Levels();
    if (activeLevels.isEmpty) {
      return const [];
    }

    final widgets = <Widget>[];
    for (final level in activeLevels) {
      widgets.add(const SizedBox(height: 16));

      final dependency = level.dependsOn?.trim();
      final dependencySatisfied =
          dependency == null ||
          dependency.isEmpty ||
          (_niveisSelecionados[dependency]?.trim().isNotEmpty ?? false);
      final options = _optionsForLevel(level);

      widgets.add(
        _buildSectionTitle(
          label: level.label,
          onVoiceTap: () => _selectLevelByVoice(level, options),
        ),
      );
      widgets.add(const SizedBox(height: 8));

      if (!dependencySatisfied) {
        widgets.add(
          Text(
            'Selecione primeiro $dependency.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        );
        continue;
      }

      if (options.isEmpty) {
        widgets.add(
          Text(
            'Sem opções configuradas para este nível.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: _niveisSelecionados[level.id] == option,
                  onSelected: (_) async {
                    setState(() {
                      _niveisSelecionados[level.id] = option;
                      if (level.id == _contextLevelId) {
                        porOndeComecar = option;
                      }
                      _sanitizeSelectedLevels();
                    });
                    await _persistStep1();
                  },
                );
              }).toList(),
        ),
      );
    }

    return widgets;
  }

  Future<void> _handleConfirm() async {
    if (clientePresente != true ||
        tipoImovel == null ||
        subtipoImovel == null ||
        !_hasRequiredLevelsSelected()) {
      _mostrarInfo(
        'Preencha presença, tipo, subtipo e os níveis obrigatórios.',
      );
      return;
    }

    await _persistStep1();

    final initialMacroLocal = _resolveInitialMacroLocal();
    final initialAmbiente = _resolveInitialAmbiente();
    final initialElemento = _resolveInitialElemento();
    final initialMaterial = _resolveInitialMaterial();
    final initialEstado = _resolveInitialEstado();

    if (!mounted) return;
    await widget.flowCoordinator.openOverlayCamera(
      context,
      title: 'COLETA',
      tipoImovel: tipoImovel!,
      subtipoImovel: subtipoImovel!,
      preselectedMacroLocal: initialMacroLocal,
      initialAmbiente: initialAmbiente,
      initialElemento: initialElemento,
      initialMaterial: initialMaterial,
      initialEstado: initialEstado,
      cameFromCheckinStep1: true,
    );
  }

  String? _resolveInitialMacroLocal() {
    return _resolveFirstLevelValue(const <String>[
      'macroLocal',
      'macro_local',
      'area_foto',
      'areaFoto',
      _contextLevelId,
      'porOndeComecar',
    ]);
  }

  String? _resolveInitialAmbiente() {
    return _resolveFirstLevelValue(const <String>[
      'ambiente',
      'local_foto',
      'localFoto',
      'local',
      'cameraAmbiente',
    ]);
  }

  String? _resolveInitialElemento() {
    return _resolveFirstLevelValue(const <String>[
      'elemento',
      'cameraElementoInicial',
      'item',
    ]);
  }

  String? _resolveInitialMaterial() {
    return _resolveFirstLevelValue(const <String>['material', 'materiais']);
  }

  String? _resolveInitialEstado() {
    return _resolveFirstLevelValue(const <String>['estado', 'condicao']);
  }

  String? _resolveFirstLevelValue(List<String> aliases) {
    for (final key in aliases) {
      final direct = _niveisSelecionados[key];
      if (direct != null && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final fallback =
          _niveisSelecionados.entries
              .firstWhere(
                (entry) => entry.key.trim().toLowerCase() == key.toLowerCase(),
                orElse: () => const MapEntry('', ''),
              )
              .value;
      if (fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
    }

    return null;
  }

  Future<void> _abrirWhatsApp(String? telefone) async {
    if (telefone == null || telefone.isEmpty) return;
    final somenteNumeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$somenteNumeros');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _ligar(String? telefone) async {
    if (telefone == null || telefone.isEmpty) return;
    final uri = Uri.parse('tel:$telefone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _mostrarInfo(String msg) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Atenção'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
