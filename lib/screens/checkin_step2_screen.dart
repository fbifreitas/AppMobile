import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/checkin_step2_config.dart';
import '../models/inspection_camera_flow_request.dart';
import '../models/inspection_capture_context.dart';
import '../models/checkin_step2_model.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/inspection_menu_service.dart';
import '../services/voice_input_service.dart';
import '../state/app_state.dart';
import '../widgets/voice_selector_sheet.dart';
import '../widgets/voice_text_field.dart';

class CheckinStep2Screen extends StatefulWidget {
  final String tipoImovel;
  final CheckinStep2Model? initialData;
  final ValueChanged<CheckinStep2Model>? onContinue;
  final InspectionFlowCoordinator flowCoordinator;

  const CheckinStep2Screen({
    super.key,
    required this.tipoImovel,
    this.initialData,
    this.onContinue,
    this.flowCoordinator = const DefaultInspectionFlowCoordinator(),
  });

  @override
  State<CheckinStep2Screen> createState() => _CheckinStep2ScreenState();
}

class _CheckinStep2ScreenState extends State<CheckinStep2Screen> {
  late final TipoImovel _tipo;
  late CheckinStep2Config _config;
  late CheckinStep2Model _model;

  final Map<String, TextEditingController> _obsControllers = {};
  final CheckinDynamicConfigService _dynamicConfigService =
      CheckinDynamicConfigService.instance;
  final InspectionMenuService _menuService = InspectionMenuService.instance;
  final VoiceInputService _voiceService = VoiceInputService();

  List<CheckinStep2PhotoFieldConfig> _camposFotosOrdenados = [];
  bool _busy = false;
  bool _loadingMenus = true;
  String? _busyFieldId;
  bool _photosSectionExpanded = false;
  bool _optionsSectionExpanded = false;
  final Map<String, bool> _expandedOptionGroupIds = <String, bool>{};
  final Map<String, bool> _expandedObservationGroupIds = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _tipo = TipoImovelExtension.fromString(widget.tipoImovel);
    _config = CheckinStep2Configs.byTipo(_tipo);

    final appState = context.read<AppState>();
    final persisted = appState.step2Payload;
    if (widget.initialData != null) {
      _model = widget.initialData!;
    } else if (persisted.isNotEmpty) {
      try {
        _model = CheckinStep2Model.fromMap(persisted);
      } catch (_) {
        _model = CheckinStep2Model.empty(_tipo);
      }
    } else {
      _model = CheckinStep2Model.empty(_tipo);
    }

    _camposFotosOrdenados = List.from(_config.camposFotos);

    for (final grupo in _config.gruposOpcoes) {
      _obsControllers[grupo.id] = TextEditingController(
        text: _model.respostas[grupo.id]?.observacao ?? '',
      );
      _expandedOptionGroupIds[grupo.id] = false;
      _expandedObservationGroupIds[grupo.id] = false;
    }

    _loadDynamicConfigAndMenus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _persistCurrentModel(stageLabel: 'Check-in etapa 2');
    });
  }

  Future<void> _persistCurrentModel({
    String stageLabel = 'Check-in etapa 2',
  }) async {
    if (!mounted) return;
    final appState = context.read<AppState>();
    await appState.setInspectionRecoveryStage(
      stageKey: 'checkin_step2',
      stageLabel: stageLabel,
      routeName: '/checkin_step2',
      payload: {
        ...appState.inspectionRecoveryPayload,
        'step1': appState.step1Payload,
        'step2': _model.toMap(),
        'step2Config': _dynamicConfigService.serializeStep2Config(_config),
      },
    );
  }

  Future<void> _loadDynamicConfigAndMenus() async {
    setState(() => _loadingMenus = true);

    final resolvedConfig = await _dynamicConfigService.loadStep2Config(
      tipo: _tipo,
      fallback: _config,
    );
    if (!mounted) return;

    _syncObservationControllers(resolvedConfig);
    _config = resolvedConfig;

    await _prepareMenus();
    await _persistCurrentModel(stageLabel: 'Check-in etapa 2');
  }

  void _syncObservationControllers(CheckinStep2Config newConfig) {
    final nextGroupIds =
        newConfig.gruposOpcoes.map((group) => group.id).toSet();

    for (final entry in List<MapEntry<String, TextEditingController>>.from(
      _obsControllers.entries,
    )) {
      if (!nextGroupIds.contains(entry.key)) {
        entry.value.dispose();
        _obsControllers.remove(entry.key);
        _expandedOptionGroupIds.remove(entry.key);
        _expandedObservationGroupIds.remove(entry.key);
      }
    }

    for (final group in newConfig.gruposOpcoes) {
      _obsControllers.putIfAbsent(
        group.id,
        () => TextEditingController(
          text: _model.respostas[group.id]?.observacao ?? '',
        ),
      );
      _expandedOptionGroupIds.putIfAbsent(group.id, () => false);
      _expandedObservationGroupIds.putIfAbsent(group.id, () => false);
    }
  }

  Future<void> _prepareMenus() async {
    final ordered = await _menuService.sortPhotoFields(
      tipoImovel: _tipo,
      defaults: _config.camposFotos,
    );
    if (!mounted) return;
    setState(() {
      _camposFotosOrdenados = ordered;
      _loadingMenus = false;
    });
  }

  @override
  void dispose() {
    for (final controller in _obsControllers.values) {
      controller.dispose();
    }
    _voiceService.dispose();
    super.dispose();
  }

  String _defaultSubtype() {
    switch (widget.tipoImovel.trim().toLowerCase()) {
      case 'rural':
        return 'Sítio';
      case 'comercial':
        return 'Loja';
      case 'industrial':
        return 'Fábrica';
      default:
        return 'Apartamento';
    }
  }

  Future<void> _handleCapture(CheckinStep2PhotoFieldConfig field) async {
    final messenger = ScaffoldMessenger.of(context);

    final maxFotos = _config.maxFotos;
    if (maxFotos != null && maxFotos > 0) {
      final currentCaptured = _capturedPhotosCount();
      final alreadyCaptured = _model.isPhotoCaptured(field.id);
      if (currentCaptured >= maxFotos && !alreadyCaptured) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Máximo de $maxFotos foto(s) atingido para esta vistoria.',
            ),
          ),
        );
        return;
      }
    }

    try {
      final buildContext = context;

      setState(() {
        _busy = true;
        _busyFieldId = field.id;
      });

      final flowCoordinator = widget.flowCoordinator;

      await _menuService.registerUsage(
        scope: 'checkin_step2.${_tipo.name}.field',
        value: field.id,
      );

      if (!buildContext.mounted) return;

      final result = await flowCoordinator.openOverlayCamera(
        buildContext,
        request: InspectionCameraFlowRequest.bootstrap(
          title: field.titulo,
          tipoImovel: widget.tipoImovel,
          subtipoImovel: _defaultSubtype(),
          singleCaptureMode: true,
          cameFromCheckinStep1: false,
          initialContext: InspectionCaptureContext(
            macroLocal: field.cameraMacroLocal,
            ambiente: field.cameraAmbiente,
            elemento: field.cameraElementoInicial,
          ),
        ),
      );

      if (!mounted || result == null) return;

      setState(() {
        _model = _model.setPhoto(
          fieldId: field.id,
          titulo: field.titulo,
          imagePath: result.filePath,
          geoPoint: result.toGeoPointData(),
          importedFromGallery: false,
        );
      });

      await _persistCurrentModel(stageLabel: 'Check-in etapa 2');

      messenger.showSnackBar(
        SnackBar(
          content: Text('Foto de "${field.titulo}" capturada com sucesso.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyFieldId = null;
        });
      }
    }
  }

  Future<void> _handleContinue() async {
    await _persistCurrentModel(stageLabel: 'Fluxo principal de coleta');
    widget.onContinue?.call(_model);

    if (!mounted) return;

    await widget.flowCoordinator.openOverlayCamera(
      context,
      request: InspectionCameraFlowRequest.bootstrap(
        title: 'COLETA',
        tipoImovel: widget.tipoImovel,
        subtipoImovel: _defaultSubtype(),
        cameFromCheckinStep1: true,
      ),
    );
  }

  Future<void> _selectGroupOptionByVoice(
    CheckinStep2OptionGroupConfig grupo,
  ) async {
    final labels = grupo.opcoes.map((opcao) => opcao.label).toList();
    if (labels.isEmpty) return;

    final respostaAtual = _model.respostas[grupo.id];
    final selectedLabel =
        (!grupo.multiplaEscolha &&
                respostaAtual != null &&
                respostaAtual.selectedOptionIds.isNotEmpty)
            ? grupo.opcoes
                .firstWhere(
                  (opcao) => opcao.id == respostaAtual.selectedOptionIds.first,
                  orElse: () => grupo.opcoes.first,
                )
                .label
            : null;

    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: labels,
      title: grupo.titulo,
      currentValue: selectedLabel,
    );

    if (selected == null || !mounted) return;

    final option = grupo.opcoes.firstWhere(
      (opcao) => opcao.label == selected,
      orElse: () => grupo.opcoes.first,
    );

    setState(() {
      _model = _model.toggleMultiOption(groupId: grupo.id, optionId: option.id);
    });

    await _persistCurrentModel(stageLabel: 'Check-in etapa 2');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Vistoria')),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotosSection(theme),
                        const SizedBox(height: 20),
                        _buildDynamicOptionsSection(theme),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                (_busy || _loadingMenus)
                                    ? null
                                    : _handleContinue,
                            child: const Text(
                              'Confirmar e abrir a câmera',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_busy || _loadingMenus)
              Container(
                color: Colors.black.withValues(alpha: 0.12),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final maxLabel =
        _config.maxFotos != null && _config.maxFotos! > 0
            ? 'máx ${_config.maxFotos}'
            : 'máx livre';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Etapa 2 da Vistoria',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_config.subtituloTela} ${_tipo.label}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preencha as evidências externas do imóvel. Mín ${_config.minFotos} • $maxLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(ThemeData theme) {
    final photoLimitReached = _isPhotoLimitReached();
    final captured = _capturedPhotosCount();
    final total = _camposFotosOrdenados.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.25),
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: _photosSectionExpanded,
            onExpansionChanged:
                (expanded) => setState(() => _photosSectionExpanded = expanded),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              'REGISTROS FOTOGRÁFICOS $captured/$total',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            children: [
              ..._camposFotosOrdenados.map(
                (field) => _PhotoCaptureCard(
                  titulo: field.titulo,
                  obrigatorio: field.obrigatorio,
                  capturado: _model.isPhotoCaptured(field.id),
                  icon: field.icon,
                  busy: _busy && _busyFieldId == field.id,
                  photoInfo: _model.fotos[field.id],
                  onCapture:
                      photoLimitReached && !_model.isPhotoCaptured(field.id)
                          ? null
                          : () => _handleCapture(field),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _capturedPhotosCount() {
    return _model.fotos.values.where((answer) => answer.hasImage).length;
  }

  bool _isPhotoLimitReached() {
    final maxFotos = _config.maxFotos;
    if (maxFotos == null || maxFotos <= 0) return false;
    return _capturedPhotosCount() >= maxFotos;
  }

  Widget _buildDynamicOptionsSection(ThemeData theme) {
    final total = _config.gruposOpcoes.length;
    final answered = _config.gruposOpcoes
        .where((grupo) => _isGroupAnswered(grupo.id))
        .length;
    final complete = total > 0 && answered == total;
    final statusColor =
        complete ? Colors.green.shade700 : Colors.orange.shade700;
    final statusBg =
        complete ? Colors.green.shade50 : Colors.orange.shade50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.25),
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: _optionsSectionExpanded,
            onExpansionChanged:
                (expanded) => setState(() => _optionsSectionExpanded = expanded),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              'INFRAESTRUTURA E SERVIÇOS $answered/$total ${complete ? 'OK' : 'NOK'}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            collapsedBackgroundColor: statusBg,
            backgroundColor: statusBg,
            children: [
              ..._config.gruposOpcoes.map(
                (grupo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOptionGroupCard(theme, grupo),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionGroupCard(
    ThemeData theme,
    CheckinStep2OptionGroupConfig grupo,
  ) {
    final resposta = _model.respostas[grupo.id];
    final answered = _isGroupAnswered(grupo.id);
    final expanded = _expandedOptionGroupIds[grupo.id] ?? false;
    final answerSummary = _groupAnswerSummary(grupo);
    final borderColor = answered
        ? Colors.green.withValues(alpha: 0.35)
        : theme.dividerColor.withValues(alpha: 0.20);
    final cardColor = answered
        ? Colors.green.withValues(alpha: 0.08)
        : theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedOptionGroupIds[grupo.id] = !expanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _toLevel3TitleCase(grupo.titulo),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (answerSummary != null)
                          TextSpan(
                            text: ' [$answerSummary]',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Selecionar por voz',
                  onPressed: () => _selectGroupOptionByVoice(grupo),
                  icon: const Icon(Icons.mic_none, size: 18),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: answered
                      ? Colors.green.shade700
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  grupo.opcoes.map((opcao) {
                    final selected =
                        resposta?.selectedOptionIds.contains(opcao.id) ?? false;
                    return FilterChip(
                      label: Text(opcao.label),
                      selected: selected,
                      onSelected: (_) async {
                        setState(() {
                          _model = _model.toggleMultiOption(
                            groupId: grupo.id,
                            optionId: opcao.id,
                          );
                        });
                        await _persistCurrentModel(
                          stageLabel: 'Check-in etapa 2',
                        );
                      },
                    );
                  }).toList(),
            ),
            if (grupo.permiteObservacao) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.25),
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: _expandedObservationGroupIds[grupo.id] ?? false,
                  onExpansionChanged: (expandedObs) {
                    setState(() {
                      _expandedObservationGroupIds[grupo.id] = expandedObs;
                    });
                  },
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: const Text(
                    'Observações',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  children: [
                    VoiceTextField(
                      controller: _obsControllers[grupo.id]!,
                      labelText: 'Observações',
                      minLines: 2,
                      maxLines: 3,
                      voiceService: _voiceService,
                      helperText: 'Toque no microfone para ditar a observação.',
                      onChanged: (value) async {
                        _model = _model.setObservacao(
                          groupId: grupo.id,
                          observacao: value,
                        );
                        await _persistCurrentModel(stageLabel: 'Check-in etapa 2');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _isGroupAnswered(String groupId) {
    final answer = _model.respostas[groupId];
    if (answer == null) return false;
    return answer.selectedOptionIds.isNotEmpty;
  }

  String _toLevel3TitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;

    const lowerWords = <String>{'de', 'da', 'das', 'do', 'dos', 'e'};
    final words = trimmed.split(RegExp(r'\s+'));

    return words.asMap().entries.map((entry) {
      final index = entry.key;
      final original = entry.value;
      final lower = original.toLowerCase();

      if (index > 0 && lowerWords.contains(lower)) {
        return lower;
      }

      if (original == original.toUpperCase() && original.length > 1) {
        return original;
      }

      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }

  String? _groupAnswerSummary(CheckinStep2OptionGroupConfig grupo) {
    final answer = _model.respostas[grupo.id];
    if (answer == null || answer.selectedOptionIds.isEmpty) {
      return null;
    }

    final labels = answer.selectedOptionIds
        .map(
          (id) => grupo.opcoes
              .firstWhere(
                (item) => item.id == id,
                orElse: () => CheckinStep2OptionItemConfig(id: id, label: id),
              )
              .label,
        )
        .toList();

    if (labels.isEmpty) return null;
    if (labels.length == 1) return labels.first;
    return '${labels.first} +${labels.length - 1}';
  }
}

class _PhotoCaptureCard extends StatelessWidget {
  final String titulo;
  final bool obrigatorio;
  final bool capturado;
  final bool busy;
  final IconData icon;
  final CheckinStep2PhotoAnswer? photoInfo;
  final VoidCallback? onCapture;

  const _PhotoCaptureCard({
    required this.titulo,
    required this.obrigatorio,
    required this.capturado,
    required this.busy,
    required this.icon,
    required this.photoInfo,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionColor =
        capturado
            ? (obrigatorio ? Colors.green : theme.colorScheme.primary)
            : theme.iconTheme.color ?? Colors.black;
    final subtitle =
        capturado
            ? 'Imagem capturada'
            : obrigatorio
            ? 'Foto obrigatória'
            : 'Foto opcional';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            capturado
                ? completionColor.withValues(alpha: 0.12)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              capturado
                  ? completionColor.withValues(alpha: 0.35)
                  : theme.dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                capturado
                    ? completionColor.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              capturado ? Icons.check_circle_outline : icon,
              color: capturado ? completionColor : theme.iconTheme.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          FilledButton(
            onPressed: busy ? null : onCapture,
            child: Text(
              capturado ? 'Refazer' : 'Capturar',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
