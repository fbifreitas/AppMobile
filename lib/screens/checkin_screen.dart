import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import '../models/checkin_step2_model.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_checkin_camera_use_case.dart';
import '../services/inspection_checkin_step1_state_service.dart';
import '../services/inspection_capture_context_resolver.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/inspection_recovery_stage_service.dart';
import '../services/mobile_job_action_service.dart';
import '../services/inspection_semantic_field_service.dart';
import '../services/location_service.dart';
import '../services/voice_input_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/checkin/checkin_property_client_card.dart';
import '../widgets/checkin/checkin_question_accordion.dart';
import '../widgets/checkin/checkin_step1_question_flow.dart';
import '../widgets/checkin/checkin_step1_section_header.dart';
import '../widgets/voice_selector_sheet.dart';

class CheckinScreen extends StatefulWidget {
  final InspectionFlowCoordinator flowCoordinator;
  final MobileJobActionService jobActionService;

  const CheckinScreen({
    super.key,
    this.flowCoordinator = const DefaultInspectionFlowCoordinator(),
    this.jobActionService = const MobileJobActionService(),
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  static const String _contextLevelId = 'contexto';
  static const String _questionClienteId = 'cliente_presente';
  static const String _questionTipoId = 'tipo_imovel';
  static const String _questionSubtipoId = 'subtipo_imovel';

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
  final InspectionSemanticFieldService _semanticFieldService =
      InspectionSemanticFieldService.instance;
  final InspectionCaptureContextResolver _captureContextResolver =
      InspectionCaptureContextResolver.instance;
  final InspectionCheckinCameraUseCase _checkinCameraUseCase =
      InspectionCheckinCameraUseCase.instance;
  final InspectionCheckinStep1StateService _step1StateService =
      InspectionCheckinStep1StateService.instance;
  final InspectionRecoveryStageService _recoveryStageService =
      InspectionRecoveryStageService.instance;

  List<String> _tipos = const <String>[];
  Map<String, List<String>> _subtiposPorTipo = const {};
  List<String> _contextos = const <String>[];
  List<ConfigLevelDefinition> _step1Levels = const [];
  Map<String, List<ConfigLevelDefinition>> _step1LevelsByTipoSubtipo = const {};
  CheckinStep1UiConfig _step1Ui = const CheckinStep1UiConfig();

  final VoiceInputService _voiceService = VoiceInputService();
  bool _hydrated = false;
  bool _loadingDynamicConfig = false;
  bool _loadingStep2Policy = false;
  bool _submittingClientAbsent = false;
  bool _step1SectionExpanded = true;
  String? _expandedQuestionId = _questionClienteId;
  CheckinStep2Config? _step2RuntimeConfig;

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
      _step1Ui = dynamicConfig.ui;

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
    await _loadStep2RuntimeConfigForSelection();
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

    clientePresente =
        payload['contactPresent'] as bool? ?? payload['clientePresente'] as bool?;
    tipoImovel =
        payload['assetType'] as String? ?? payload['tipoImovel'] as String?;
    subtipoImovel =
        payload['assetSubtype'] as String? ??
        payload['subtipoImovel'] as String?;
    porOndeComecar =
        payload['entryPoint'] as String? ?? payload['porOndeComecar'] as String?;

    final rawLevels = payload['niveis'];
    if (rawLevels is Map) {
      _niveisSelecionados = rawLevels.map(
        (key, value) => MapEntry('$key', '$value'),
      );
    }

    if (porOndeComecar != null && porOndeComecar!.trim().isNotEmpty) {
      _niveisSelecionados[_contextLevelId] = porOndeComecar!.trim();
    }

    _loadStep2RuntimeConfigForSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appStateRead = context.read<AppState>();
      final jobId = appStateRead.jobAtual?.id;
      if (jobId == null) return;
      appStateRead.setInspectionRecoverySnapshot(
        _recoveryStageService.checkinStep1(
          jobId: jobId,
          inspectionRecoveryPayload: appStateRead.inspectionRecoveryPayload,
          step1Payload: appStateRead.step1Payload,
          step2Payload: appStateRead.step2Payload,
        ),
      );
    });
  }

  Future<void> _loadStep2RuntimeConfigForSelection() async {
    final selectedTipo = tipoImovel;
    if (selectedTipo == null || selectedTipo.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _step2RuntimeConfig = null;
        _loadingStep2Policy = false;
      });
      return;
    }

    final tipo = TipoImovelExtension.fromString(selectedTipo);
    final fallback = CheckinStep2Configs.byTipo(tipo);

    setState(() {
      _step2RuntimeConfig = null;
      _loadingStep2Policy = true;
    });
    final config = await _dynamicConfigService.loadStep2Config(
      tipo: tipo,
      fallback: fallback,
    );

    if (!mounted) return;
    setState(() {
      _step2RuntimeConfig = config;
      _loadingStep2Policy = false;
    });
  }

  CheckinStep2Config? _resolveCurrentStep2Config() {
    final selectedTipo = tipoImovel;
    if (selectedTipo == null || selectedTipo.trim().isEmpty) {
      return null;
    }
    return _step2RuntimeConfig ??
        CheckinStep2Configs.byTipo(TipoImovelExtension.fromString(selectedTipo));
  }

  bool _shouldShowStep2Action() {
    if (_loadingStep2Policy) {
      return false;
    }
    return _step2RuntimeConfig?.visivelNoFluxo == true;
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
          semanticKey: InspectionSemanticFieldKeys.captureContext,
          aliases: const <String>[
            'porOndeComecar',
            'area_foto',
            'macroLocal',
          ],
          labelsBySurface: const <String, String>{
            InspectionSurfaceKeys.checkinStep1: 'Por onde deseja começar?',
            InspectionSurfaceKeys.camera: 'Onde estou?',
          },
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
    return _step1StateService.optionsForLevel(
      level: level,
      contextLevelId: _contextLevelId,
      fallbackContextos: _contextos,
    );
  }

  String _labelForStep1Level(ConfigLevelDefinition level) {
    return _semanticFieldService.labelForLevel(
      level: level,
      surface: InspectionSurfaceKeys.checkinStep1,
    );
  }

  void _sanitizeSelectedLevels() {
    _niveisSelecionados = _step1StateService.sanitizeSelectedLevels(
      activeLevels: _resolveActiveStep1Levels(),
      selectedLevels: _niveisSelecionados,
      contextLevelId: _contextLevelId,
      fallbackContextos: _contextos,
    );
    porOndeComecar = _niveisSelecionados[_contextLevelId] ?? porOndeComecar;
  }

  bool _hasRequiredLevelsSelected() {
    return _step1StateService.hasRequiredLevelsSelected(
      activeLevels: _resolveActiveStep1Levels(),
      selectedLevels: _niveisSelecionados,
    );
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
            CheckinPropertyClientCard(job: job),
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
            CheckinStep1QuestionFlow(
              clientePresente: clientePresente,
              tipoImovel: tipoImovel,
              subtipoImovel: subtipoImovel,
              contextLevelId: _contextLevelId,
              questionClienteId: _questionClienteId,
              questionTipoId: _questionTipoId,
              questionSubtipoId: _questionSubtipoId,
              niveisSelecionados: _niveisSelecionados,
              tipos: _tipos,
              subtipos: subtipos,
              activeLevels:
                  clientePresente == true
                      ? _resolveActiveStep1Levels()
                      : const <ConfigLevelDefinition>[],
              submittingClientAbsent: _submittingClientAbsent,
              step1SectionExpanded: _step1SectionExpanded,
              resolvedExpandedId: _resolvedExpandedQuestionId(<String>[
                _questionClienteId,
                if (clientePresente == true) _questionTipoId,
                if (clientePresente == true && tipoImovel != null)
                  _questionSubtipoId,
                for (final level
                    in (clientePresente == true
                        ? _resolveActiveStep1Levels()
                        : const <ConfigLevelDefinition>[]))
                  _levelQuestionId(level.id),
              ]),
              answered: _step1AnsweredQuestions(
                clientePresente == true
                    ? _resolveActiveStep1Levels()
                    : const <ConfigLevelDefinition>[],
              ),
              total: _step1TotalQuestions(
                clientePresente == true
                    ? _resolveActiveStep1Levels()
                    : const <ConfigLevelDefinition>[],
              ),
              isDone: (() {
                final activeLevels =
                    clientePresente == true
                        ? _resolveActiveStep1Levels()
                        : const <ConfigLevelDefinition>[];
                final total = _step1TotalQuestions(activeLevels);
                final answered = _step1AnsweredQuestions(activeLevels);
                return total > 0 && answered == total;
              })(),
              step1Ui: _step1Ui,
              labelForStep1Level: _labelForStep1Level,
              levelQuestionId: _levelQuestionId,
              optionsForLevel: _optionsForLevel,
              shouldShowStep2Action: _shouldShowStep2Action,
              onSectionTap: () {
                setState(() => _step1SectionExpanded = !_step1SectionExpanded);
              },
              onToggleQuestion: _toggleQuestion,
              onClienteVoiceTap: _selectClientePresenteByVoice,
              onTipoVoiceTap: _selectTipoByVoice,
              onSubtipoVoiceTap: _selectSubtipoByVoice,
              onLevelVoiceTap: _selectLevelByVoice,
              onClientePresenteYes: () async {
                setState(() {
                  clientePresente = true;
                  _expandedQuestionId = _questionTipoId;
                });
                await _persistStep1();
              },
              onClientePresenteNo: _handleClienteAusenteSelection,
              onTipoSelected: (tipo) async {
                setState(() {
                  tipoImovel = tipo;
                  subtipoImovel = null;
                  _sanitizeSelectedLevels();
                  _expandedQuestionId = _questionSubtipoId;
                });
                await _loadStep2RuntimeConfigForSelection();
                await _persistStep1();
              },
              onSubtipoSelected: (subtipo) async {
                final activeLevels =
                    clientePresente == true
                        ? _resolveActiveStep1Levels()
                        : const <ConfigLevelDefinition>[];
                setState(() {
                  subtipoImovel = subtipo;
                  _sanitizeSelectedLevels();
                  _expandedQuestionId =
                      activeLevels.isEmpty
                          ? null
                          : _levelQuestionId(activeLevels.first.id);
                });
                await _persistStep1();
              },
              onLevelSelected: (level, option) async {
                setState(() {
                  _niveisSelecionados[level.id] = option;
                  if (level.id == _contextLevelId) {
                    porOndeComecar = option;
                  }
                  _sanitizeSelectedLevels();
                  _expandedQuestionId = _resolveNextPendingQuestionId();
                });
                await _persistStep1();
              },
              step2Action: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      tipoImovel == null
                          ? null
                          : () async {
                            final appStateRead = context.read<AppState>();
                            final flowCoordinator = widget.flowCoordinator;
                            final jobId = appStateRead.jobAtual?.id;
                            if (jobId == null) return;

                            await appStateRead.setInspectionRecoverySnapshot(
                              _recoveryStageService.checkinStep2(
                                jobId: jobId,
                                inspectionRecoveryPayload:
                                    appStateRead.inspectionRecoveryPayload,
                                step1Payload: appStateRead.step1Payload,
                                step2Payload: appStateRead.step2Payload,
                              ),
                            );

                            if (!context.mounted) return;

                            flowCoordinator.openCheckinStep2(
                              context,
                              tipoImovel: tipoImovel!,
                              initialData: _readInitialStep2(appStateRead),
                              onContinue: (model) async {
                                await appStateRead.persistStep2Draft(model.toMap());
                              },
                            );
                          },
                  child: Text(
                    _step1Ui.botaoEtapa2Label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadingDynamicConfig ? null : _handleConfirm,
                child: Text(
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

  // ignore: unused_element
  Widget _buildPropertyAndClientCard(job) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DADOS IMÓVEL E CLIENTE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            job.titulo,
            style: const TextStyle(
              fontSize: 16,
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
          const SizedBox(height: 10),
          Text(
            'Cliente: ${job.nomeCliente.isEmpty ? 'Não informado' : job.nomeCliente}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Contato: ${job.telefoneCliente?.isNotEmpty == true ? job.telefoneCliente : 'Não informado'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStep1QuestionFlow(List<String> subtipos) {
    final activeLevels =
        clientePresente == true
            ? _resolveActiveStep1Levels()
            : const <ConfigLevelDefinition>[];
    final total = _step1TotalQuestions(activeLevels);
    final answered = _step1AnsweredQuestions(activeLevels);
    final isDone = total > 0 && answered == total;
    final statusColor = isDone ? AppColors.success : AppColors.warning;
    final statusBg = isDone ? AppColors.successLight : AppColors.warningLight;

    final levelIds = <String>[
      for (final level in activeLevels) _levelQuestionId(level.id),
    ];
    final visibleQuestionIds = <String>[
      _questionClienteId,
      if (clientePresente == true) _questionTipoId,
      if (clientePresente == true && tipoImovel != null) _questionSubtipoId,
      ...levelIds,
    ];
    final resolvedExpandedId = _resolvedExpandedQuestionId(visibleQuestionIds);

    final widgets = <Widget>[];
    widgets.add(
      CheckinStep1SectionHeader(
        answered: answered,
        total: total,
        isDone: isDone,
        expanded: _step1SectionExpanded,
        statusColor: statusColor,
        statusBackground: statusBg,
        onTap: () {
          setState(() => _step1SectionExpanded = !_step1SectionExpanded);
        },
      ),
    );

    if (_step1SectionExpanded) {
      final step1Cards = <Widget>[];
      if (_step1Ui.clientePresenteVisible) {
        step1Cards.add(
        CheckinQuestionAccordion(
          question: 'Cliente está presente?',
          answer: clientePresente == null ? null : (clientePresente! ? 'Sim' : 'Não'),
          expanded: resolvedExpandedId == _questionClienteId,
          onToggle: () => _toggleQuestion(_questionClienteId),
          onVoiceTap: _selectClientePresenteByVoice,
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sim'),
                selected: clientePresente == true,
                onSelected: _submittingClientAbsent ? null : (_) async {
                  setState(() {
                    clientePresente = true;
                    _expandedQuestionId = _questionTipoId;
                  });
                  await _persistStep1();
                },
              ),
              ChoiceChip(
                label: const Text('Não'),
                selected: clientePresente == false,
                onSelected:
                    _submittingClientAbsent
                        ? null
                        : (_) async => _handleClienteAusenteSelection(),
              ),
            ],
          ),
        ),
        );
      }

      if (clientePresente == true && _step1Ui.menuTipoVisible) {
        step1Cards.add(const SizedBox(height: 10));
        step1Cards.add(
          CheckinQuestionAccordion(
            question: 'Tipo de imóvel',
            answer: tipoImovel,
            expanded: resolvedExpandedId == _questionTipoId,
            onToggle: () => _toggleQuestion(_questionTipoId),
            onVoiceTap: _selectTipoByVoice,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tipos
                  .map(
                    (tipo) => ChoiceChip(
                      label: Text(tipo),
                      selected: tipoImovel == tipo,
                      onSelected: (_) async {
                        setState(() {
                          tipoImovel = tipo;
                          subtipoImovel = null;
                          _sanitizeSelectedLevels();
                          _expandedQuestionId = _questionSubtipoId;
                        });
                        await _loadStep2RuntimeConfigForSelection();
                        await _persistStep1();
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      }

      if (clientePresente == true &&
          tipoImovel != null &&
          _step1Ui.menuSubtipoVisible) {
        step1Cards.add(const SizedBox(height: 10));
        step1Cards.add(
          CheckinQuestionAccordion(
            question: 'Subtipo',
            answer: subtipoImovel,
            expanded: resolvedExpandedId == _questionSubtipoId,
            onToggle: () => _toggleQuestion(_questionSubtipoId),
            onVoiceTap: _selectSubtipoByVoice,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subtipos
                  .map(
                    (subtipo) => ChoiceChip(
                      label: Text(subtipo),
                      selected: subtipoImovel == subtipo,
                      onSelected: (_) async {
                        setState(() {
                          subtipoImovel = subtipo;
                          _sanitizeSelectedLevels();
                          _expandedQuestionId =
                              activeLevels.isEmpty
                                  ? null
                                  : _levelQuestionId(activeLevels.first.id);
                        });
                        await _persistStep1();
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      }

      if (clientePresente == true && subtipoImovel != null) {
        var hasPending = false;
        for (final level in activeLevels) {
          final questionId = _levelQuestionId(level.id);
          final options = _optionsForLevel(level);
          final selected = _niveisSelecionados[level.id];
          final answeredLevel = selected != null && selected.trim().isNotEmpty;

          if (!answeredLevel && hasPending) {
            break;
          }

          step1Cards.add(const SizedBox(height: 10));
          step1Cards.add(
            CheckinQuestionAccordion(
              question: _labelForStep1Level(level),
              answer: selected,
              expanded: resolvedExpandedId == questionId,
              onToggle: () => _toggleQuestion(questionId),
              onVoiceTap: () => _selectLevelByVoice(level, options),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options
                    .map(
                      (option) => ChoiceChip(
                        label: Text(option),
                        selected: selected == option,
                        onSelected: (_) async {
                          setState(() {
                            _niveisSelecionados[level.id] = option;
                            if (level.id == _contextLevelId) {
                              porOndeComecar = option;
                            }
                            _sanitizeSelectedLevels();
                            _expandedQuestionId = _resolveNextPendingQuestionId();
                          });
                          await _persistStep1();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          );

          if (!answeredLevel) {
            hasPending = true;
          }
        }
      }

      final shouldShowStep2Action = _shouldShowStep2Action();

      if (clientePresente == true &&
          shouldShowStep2Action &&
          _step1Ui.botaoEtapa2Visible) {
        step1Cards.add(const SizedBox(height: 16));
        step1Cards.add(
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  tipoImovel == null
                      ? null
                      : () async {
                        final appStateRead = context.read<AppState>();
                        final flowCoordinator = widget.flowCoordinator;
                        final jobId = appStateRead.jobAtual?.id;
                        if (jobId == null) return;

                        await appStateRead.setInspectionRecoverySnapshot(
                          _recoveryStageService.checkinStep2(
                            jobId: jobId,
                            inspectionRecoveryPayload:
                                appStateRead.inspectionRecoveryPayload,
                            step1Payload: appStateRead.step1Payload,
                            step2Payload: appStateRead.step2Payload,
                          ),
                        );

                        if (!mounted) return;

                        flowCoordinator.openCheckinStep2(
                          context,
                          tipoImovel: tipoImovel!,
                          initialData: _readInitialStep2(appStateRead),
                          onContinue: (model) async {
                            await appStateRead.persistStep2Draft(model.toMap());
                          },
                        );
                      },
              child: Text(
                _step1Ui.botaoEtapa2Label,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        );
      }

      widgets.add(const SizedBox(height: 12));
      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: step1Cards,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _toggleQuestion(String questionId) {
    setState(() {
      _expandedQuestionId = _expandedQuestionId == questionId ? null : questionId;
    });
  }

  int _step1TotalQuestions(List<ConfigLevelDefinition> activeLevels) {
    return _step1StateService.totalQuestions(
      clientePresente: clientePresente,
      activeLevels: activeLevels,
    );
  }

  int _step1AnsweredQuestions(List<ConfigLevelDefinition> activeLevels) {
    return _step1StateService.answeredQuestions(
      clientePresente: clientePresente,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      activeLevels: activeLevels,
      selectedLevels: _niveisSelecionados,
    );
  }

  String _levelQuestionId(String levelId) => 'level_$levelId';

  String? _resolvedExpandedQuestionId(List<String> visibleQuestionIds) {
    return _step1StateService.resolveExpandedQuestionId(
      currentExpandedQuestionId: _expandedQuestionId,
      visibleQuestionIds: visibleQuestionIds,
      nextPendingQuestionId: _resolveNextPendingQuestionId(),
    );
  }

  String? _resolveNextPendingQuestionId() {
    return _step1StateService.resolveNextPendingQuestionId(
      clientePresente: clientePresente,
      questionClienteId: _questionClienteId,
      questionTipoId: _questionTipoId,
      questionSubtipoId: _questionSubtipoId,
      levelQuestionId: _levelQuestionId,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      activeLevels: _resolveActiveStep1Levels(),
      selectedLevels: _niveisSelecionados,
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
    if (selected == 'Sim') {
      setState(() {
        clientePresente = true;
        _expandedQuestionId = _questionTipoId;
      });
      await _persistStep1();
      return;
    }

    await _handleClienteAusenteSelection();
  }

  Future<void> _handleClienteAusenteSelection() async {
    if (_submittingClientAbsent) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Confirmar ausência do cliente'),
                content: const Text(
                  'Essa ação vai avisar o backoffice para reagendar a vistoria e retirar este job da sua fila ativa. Deseja continuar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    final appState = context.read<AppState>();
    final currentJob = appState.jobAtual;
    if (currentJob == null) return;

    setState(() => _submittingClientAbsent = true);
    final result = await widget.jobActionService.requestSchedulingAfterClientAbsent(
      jobId: currentJob.id,
    );

    if (!mounted) return;
    setState(() => _submittingClientAbsent = false);

    if (!result.success) {
      _mostrarInfo(result.message);
      return;
    }

    await appState.marcarJobAguardandoAgendamento(
      jobId: currentJob.id,
      titulo: currentJob.titulo,
      endereco: currentJob.endereco,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    Navigator.of(context).maybePop();
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
      title: _labelForStep1Level(level),
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

  Future<void> _handleConfirm() async {
    if (_loadingStep2Policy) {
      _mostrarInfo(
        'Aguarde a configuracao operacional da Etapa 2 carregar para continuar.',
      );
      return;
    }

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
    if (!mounted) return;

    final step2Config = _resolveCurrentStep2Config();
    if (step2Config == null) {
      _mostrarInfo(
        'Selecione o tipo do imovel para carregar a configuracao operacional antes de continuar.',
      );
      return;
    }
    final initialSelection = _captureContextResolver.resolveFromStep1(
      levels: _resolveActiveStep1Levels(),
      selectedLevels: _niveisSelecionados,
    );

    if (!mounted) return;
    final appState = context.read<AppState>();
    await _checkinCameraUseCase.openFromStep1(
      context,
      flowCoordinator: widget.flowCoordinator,
      appState: appState,
      tipoImovel: tipoImovel!,
      subtipoImovel: subtipoImovel!,
      initialSelection: initialSelection,
    );
    if (!mounted) return;
    await _persistStep1();
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
