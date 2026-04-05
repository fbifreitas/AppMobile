import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import '../models/checkin_step2_model.dart';
import '../models/overlay_camera_capture_result.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_environment_instance_service.dart';
import '../services/inspection_menu_service.dart';
import '../services/inspection_requirement_policy_service.dart';
import '../services/inspection_semantic_field_service.dart';
import '../services/voice_command_catalog_service.dart';
import '../services/voice_command_parser_service.dart';
import '../services/voice_input_service.dart';
import '../state/app_state.dart';
import '../widgets/voice_action_bar.dart';
import '../widgets/voice_selector_sheet.dart';
import 'inspection_review_screen.dart';

class OverlayCameraScreen extends StatefulWidget {
  final String title;
  final String tipoImovel;
  final String subtipoImovel;
  final bool singleCaptureMode;
  final String? preselectedMacroLocal;
  final String? initialAmbiente;
  final String? initialElemento;
  final String? initialMaterial;
  final String? initialEstado;
  final bool cameFromCheckinStep1;
  final bool skipDeviceInitialization;
  final bool showVoiceActions;
  final bool useTestMenuData;
  final List<String>? testCameraLevelOrder;
  final List<String> testMacroLocais;
  final List<String> testAmbientes;
  final List<String> testElementos;
  final List<String> testMateriais;
  final List<String> testEstados;

  const OverlayCameraScreen({
    super.key,
    required this.title,
    required this.tipoImovel,
    required this.subtipoImovel,
    this.singleCaptureMode = false,
    this.preselectedMacroLocal,
    this.initialAmbiente,
    this.initialElemento,
    this.initialMaterial,
    this.initialEstado,
    this.cameFromCheckinStep1 = false,
    this.skipDeviceInitialization = false,
    this.showVoiceActions = true,
    this.useTestMenuData = false,
    this.testCameraLevelOrder,
    this.testMacroLocais = const <String>[],
    this.testAmbientes = const <String>[],
    this.testElementos = const <String>[],
    this.testMateriais = const <String>[],
    this.testEstados = const <String>[],
  });

  @override
  State<OverlayCameraScreen> createState() => _OverlayCameraScreenState();
}

class _OverlayCameraScreenState extends State<OverlayCameraScreen> {
  static const List<String> _defaultCameraLevels = <String>[
    'macroLocal',
    'ambiente',
    'elemento',
    'material',
    'estado',
  ];

  final InspectionMenuService _menuService = InspectionMenuService.instance;
  final InspectionEnvironmentInstanceService _environmentInstanceService =
      InspectionEnvironmentInstanceService.instance;
  final InspectionRequirementPolicyService _requirementPolicy =
      InspectionRequirementPolicyService.instance;
  final InspectionSemanticFieldService _semanticFieldService =
      InspectionSemanticFieldService.instance;
  final VoiceInputService _voiceService = VoiceInputService();
  final VoiceCommandParserService _voiceCommandParser =
      VoiceCommandParserService();
  final VoiceCommandCatalogService _voiceCommandCatalog =
      const VoiceCommandCatalogService();

  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  bool _loadingMenus = true;
  String? _error;

  String? _macroLocal;
  String? _ambiente;
  String? _elemento;
  String? _material;
  String? _estado;

  List<String> _macroLocais = const [];
  List<String> _ambientesAtuais = const [];
  List<String> _elementosAtuais = const [];
  List<String> _materiaisAtuais = const [];
  List<String> _estadosAtuais = const [];
  List<String> _recentAmbientes = const [];
  List<String> _recentElementos = const [];
  List<String> _cameraLevelOrder = List<String>.from(_defaultCameraLevels);
  Map<String, String> _cameraLevelLabels = const <String, String>{};

  PredictedSelection? _predictedSelection;
  String? _contextSuggestionSummary;
  final List<OverlayCameraCaptureResult> _captures = [];
  bool _hasPreviousPhotos = false;
  bool _selectorsCollapsed = false;

  String? get _predictionSummary {
    final prediction = _predictedSelection;
    if (prediction == null || !prediction.hasAnyValue) return null;
    final parts = <String>[];
    if (prediction.elemento != null) parts.add(prediction.elemento!);
    if (prediction.material != null) parts.add(prediction.material!);
    if (prediction.estado != null) parts.add(prediction.estado!);
    if (parts.isEmpty) return null;
    return 'Sugestão silenciosa com base em ${prediction.captures} captura(s): '
        '${parts.join(' • ')}';
  }

  bool get _showMacroLocalSelector => widget.preselectedMacroLocal == null;

  bool get _hasAnyCaptures => _captures.isNotEmpty || _hasPreviousPhotos;

  @override
  void initState() {
    super.initState();
    _macroLocal = widget.preselectedMacroLocal;
    _ambiente = widget.initialAmbiente;
    _elemento = widget.initialElemento;
    _material = widget.initialMaterial;
    _estado = widget.initialEstado;
    _setup();
    if (widget.cameFromCheckinStep1) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadPreviousPhotosState(),
      );
    }
  }

  Future<void> _setup() async {
    try {
      if (widget.useTestMenuData) {
        if (!mounted) return;
        setState(() {
          _cameraLevelOrder = _normalizeCameraLevels(
            widget.testCameraLevelOrder ?? _defaultCameraLevels,
          );
          _macroLocais = List<String>.from(widget.testMacroLocais);
          _ambientesAtuais = List<String>.from(widget.testAmbientes);
          _elementosAtuais = List<String>.from(widget.testElementos);
          _materiaisAtuais = List<String>.from(widget.testMateriais);
          _estadosAtuais = List<String>.from(widget.testEstados);
          _loadingMenus = false;
          _initializing = false;
        });
        return;
      }

      await _menuService.ensureLoaded();
      final configuredLevels = await _menuService.getCameraLevelOrder(
        propertyType: widget.tipoImovel,
        subtipo: widget.subtipoImovel,
      );
      final configuredLevelDefinitions = await _menuService.getCameraLevels(
        propertyType: widget.tipoImovel,
        subtipo: widget.subtipoImovel,
      );
      _cameraLevelOrder = _normalizeCameraLevels(configuredLevels);
      _cameraLevelLabels = _resolveCameraLevelLabels(configuredLevelDefinitions);
      await _reloadMenus(initialLoad: true);

      if (widget.skipDeviceInitialization) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
        });
        return;
      }

      await _ensureLocationReady();

      final cameras = await availableCameras();
      final back = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selected = back.isNotEmpty ? back.first : cameras.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Falha ao inicializar a câmera: $error';
      });
    }
  }

  Future<void> _reloadMenus({bool initialLoad = false}) async {
    if (mounted) {
      setState(() => _loadingMenus = true);
    }

    final macroLocals = await _menuService.getMacroLocals(
      propertyType: widget.tipoImovel,
    );

    String? macroLocal = _macroLocal;
    String? contextSuggestionSummary;

    if (macroLocal == null && !_showMacroLocalSelector) {
      macroLocal = widget.preselectedMacroLocal;
    }

    if (macroLocal == null && !_isCameraLevelEnabled('macroLocal')) {
      macroLocal = macroLocals.isNotEmpty ? macroLocals.first : null;
    }

    if ((macroLocal == null || macroLocal.trim().isEmpty) &&
        _showMacroLocalSelector) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: widget.tipoImovel,
        availableMacroLocals: macroLocals,
      );
      if (suggestedContext?.macroLocal != null) {
        macroLocal = suggestedContext!.macroLocal!;
        contextSuggestionSummary =
            'Área da foto sugerida com base no histórico: $macroLocal';
      }
    }

    if (macroLocal != null && !macroLocals.contains(macroLocal)) {
      macroLocal = macroLocals.isNotEmpty ? macroLocals.first : null;
    }

    final ambientes =
        macroLocal == null
            ? const <String>[]
            : await _menuService.getAmbientes(
              propertyType: widget.tipoImovel,
              macroLocal: macroLocal,
            );

    final recentAmbientes =
        macroLocal == null
            ? const <String>[]
            : await _menuService.getRecentAmbienteSuggestions(
              propertyType: widget.tipoImovel,
              macroLocal: macroLocal,
              availableAmbientes: ambientes,
            );

    String? ambiente = _ambiente;
    if (ambiente != null && !ambientes.contains(ambiente)) {
      ambiente = null;
    }

    if ((ambiente == null || ambiente.trim().isEmpty) && macroLocal != null) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: widget.tipoImovel,
        macroLocal: macroLocal,
        availableAmbientes: ambientes,
      );
      if (widget.initialAmbiente == null &&
          suggestedContext?.ambiente != null) {
        ambiente = suggestedContext!.ambiente!;
        contextSuggestionSummary =
            'Contexto sugerido com base no histórico: $macroLocal • $ambiente';
      }
    }

    if (initialLoad &&
        ambiente == null &&
        ambientes.isNotEmpty &&
        !_showMacroLocalSelector) {
      ambiente = ambientes.first;
    }

    final elementos =
        (macroLocal == null || ambiente == null)
            ? const <String>[]
            : await _menuService.getElementos(
              propertyType: widget.tipoImovel,
              macroLocal: macroLocal,
              ambiente: ambiente,
            );

    final recentElementos =
        (macroLocal == null || ambiente == null)
            ? const <String>[]
            : await _menuService.getRecentElementSuggestions(
              propertyType: widget.tipoImovel,
              macroLocal: macroLocal,
              ambiente: ambiente,
              availableElementos: elementos,
            );

    String? elemento = _elemento;
    if (elemento != null && !elementos.contains(elemento)) {
      elemento = elementos.isNotEmpty ? elementos.first : null;
    }

    PredictedSelection? prediction;
    if (macroLocal != null && ambiente != null) {
      prediction = await _menuService.getPrediction(
        propertyType: widget.tipoImovel,
        macroLocal: macroLocal,
        ambiente: ambiente,
        availableElementos: elementos,
      );
    }

    if (elemento == null &&
        widget.initialElemento == null &&
        prediction?.elemento != null) {
      final candidate = prediction!.elemento!;
      if (elementos.contains(candidate)) {
        elemento = candidate;
      }
    }

    final materiaisDisponiveis =
        (macroLocal == null || ambiente == null || elemento == null)
            ? const <String>[]
            : await _menuService.getMateriais(
              propertyType: widget.tipoImovel,
              macroLocal: macroLocal,
              ambiente: ambiente,
              elemento: elemento,
            );
    final estadosDisponiveis =
        (macroLocal == null || ambiente == null || elemento == null)
            ? const <String>[]
            : await _menuService.getEstados(
              propertyType: widget.tipoImovel,
              macroLocal: macroLocal,
              ambiente: ambiente,
              elemento: elemento,
            );

    if (macroLocal != null && ambiente != null) {
      prediction = await _menuService.getPrediction(
        propertyType: widget.tipoImovel,
        macroLocal: macroLocal,
        ambiente: ambiente,
        availableElementos: elementos,
        availableMateriais: materiaisDisponiveis,
        availableEstados: estadosDisponiveis,
      );
    }

    String? material = _material;
    if (material != null && !materiaisDisponiveis.contains(material)) {
      material = null;
    }
    if (material == null && prediction?.material != null) {
      final candidate = prediction!.material!;
      if (materiaisDisponiveis.contains(candidate)) {
        material = candidate;
      }
    }

    String? estado = _estado;
    if (estado != null && !estadosDisponiveis.contains(estado)) {
      estado = null;
    }
    if (estado == null && prediction?.estado != null) {
      final candidate = prediction!.estado!;
      if (estadosDisponiveis.contains(candidate)) {
        estado = candidate;
      }
    }

    if (!mounted) return;
    setState(() {
      _macroLocais = macroLocals;
      _ambientesAtuais = ambientes;
      _elementosAtuais = elementos;
      _materiaisAtuais = materiaisDisponiveis;
      _estadosAtuais = estadosDisponiveis;
      _recentAmbientes = recentAmbientes;
      _recentElementos = recentElementos;
      _predictedSelection = prediction;
      _contextSuggestionSummary = contextSuggestionSummary;
      _macroLocal = macroLocal;
      _ambiente = ambiente;
      _elemento = elemento;
      _material = material;
      _estado = estado;
      _loadingMenus = false;
    });
  }

  Future<void> _ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Ative o GPS do aparelho.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização não concedida.');
    }
  }

  Future<void> _selectMacroLocal(String value) async {
    await _menuService.registerUsage(
      scope: 'camera.${widget.tipoImovel.toLowerCase()}.macro',
      value: value,
    );
    setState(() {
      _macroLocal = value;
      _ambiente = null;
      _elemento = null;
      _material = null;
      _estado = null;
    });
    await _reloadMenus();
  }

  Future<void> _selectAmbiente(String value) async {
    await _menuService.registerUsage(
      scope: 'camera.${widget.tipoImovel.toLowerCase()}.$_macroLocal.ambiente',
      value: value,
    );
    setState(() {
      _ambiente = value;
      _elemento = null;
      _material = null;
      _estado = null;
    });
    await _reloadMenus();
  }

  Future<void> _duplicateCurrentAmbiente() async {
    final selectedAmbiente = _ambiente;
    if (selectedAmbiente == null || selectedAmbiente.trim().isEmpty) {
      return;
    }

    final nextLabel = _environmentInstanceService.nextDisplayLabel(
      selectedLabel: selectedAmbiente,
      existingLabels: _ambientesAtuais,
    );
    if (nextLabel.trim().isEmpty) {
      return;
    }

    setState(() {
      final nextAmbientes = List<String>.from(_ambientesAtuais);
      if (!nextAmbientes.contains(nextLabel)) {
        nextAmbientes.add(nextLabel);
      }
      _ambientesAtuais = nextAmbientes;
      _ambiente = nextLabel;
      _elemento = null;
      _material = null;
      _estado = null;
    });

    if (widget.useTestMenuData) {
      return;
    }

    await _menuService.registerUsage(
      scope: 'camera.${widget.tipoImovel.toLowerCase()}.$_macroLocal.ambiente',
      value: nextLabel,
    );

    await _reloadMenus();
  }

  Future<void> _selectElemento(String value) async {
    await _menuService.registerUsage(
      scope:
          'camera.${widget.tipoImovel.toLowerCase()}.$_macroLocal.$_ambiente.elemento',
      value: value,
    );
    setState(() {
      _elemento = value;
      _material = null;
      _estado = null;
    });
    await _reloadMenus();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_ambiente == null || _ambiente!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o local da foto antes de capturar.'),
        ),
      );
      return;
    }

    try {
      setState(() => _capturing = true);
      await _ensureLocationReady();
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final file = await _controller!.takePicture();
      if (!mounted) return;

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final hadSilentSuggestion =
          (_contextSuggestionSummary != null) ||
          (_predictedSelection != null && _predictedSelection!.hasAnyValue);

      final result = OverlayCameraCaptureResult(
        filePath: file.path,
        macroLocal: _macroLocal,
        ambiente: _ambiente!,
        ambienteBase: _environmentInstanceService.baseLabelOf(_ambiente),
        ambienteInstanceIndex:
            _environmentInstanceService.parse(_ambiente).instanceIndex,
        elemento: _elemento,
        material: _material,
        estado: _estado,
        capturedAt: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        classificationConfirmed: false,
        learningPersisted: false,
        usedSuggestion: hadSilentSuggestion,
        suggestionSummary: _predictionSummary ?? _contextSuggestionSummary,
      );

      if (widget.singleCaptureMode) {
        navigator.pop(result);
        return;
      }

      setState(() => _captures.add(result));
      await _syncStep2DraftFromBatchCaptures();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hadSilentSuggestion
                ? 'Foto adicionada ao lote com sugestão silenciosa.'
                : 'Foto adicionada ao lote.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  void _loadPreviousPhotosState() {
    if (!mounted) return;
    final step2 = Provider.of<AppState>(context, listen: false).step2Payload;
    if (step2.isEmpty) return;
    final model = CheckinStep2Model.fromMap(step2);
    if (model.fotos.values.any((f) => f.hasImage)) {
      setState(() => _hasPreviousPhotos = true);
    }
  }

  void _openVoiceSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: VoiceActionBar(
              voiceService: _voiceService,
              parserService: _voiceCommandParser,
              commands: _voiceCommandCatalog.cameraCommands(),
              contextKey: 'camera',
              title: 'Comandos rápidos por voz',
              subtitle:
                  'Ex.: capturar foto, abrir área, abrir local, abrir elemento.',
              onCommand: _handleCameraVoiceCommand,
            ),
          ),
    );
  }

  void _finalizeBatch() async {
    if (!_hasAnyCaptures) return;

    await _syncStep2DraftFromBatchCaptures();

    if (!mounted) return;

    // Mescla captures de sessões anteriores (salvas no payload de recovery)
    // com as captures desta sessão. Desta forma, fotos capturadas em sessões
    // anteriores de câmera não são perdidas ao chegar na tela de revisão.
    final appState = Provider.of<AppState>(context, listen: false);
    final savedReview = appState.inspectionRecoveryPayload['review'];
    final previousCaptures = <OverlayCameraCaptureResult>[];
    if (savedReview is Map<String, dynamic>) {
      final rawCaptures = savedReview['captures'];
      if (rawCaptures is List) {
        for (final raw in rawCaptures) {
          if (raw is Map<String, dynamic>) {
            previousCaptures.add(OverlayCameraCaptureResult.fromMap(raw));
          }
        }
      }
    }

    // Captures novas substituem as anteriores com mesmo filePath;
    // as que não conflitam são preservadas.
    final currentPaths = _captures.map((c) => c.filePath).toSet();
    final mergedCaptures = [
      ...previousCaptures.where(
        (prev) => !currentPaths.contains(prev.filePath),
      ),
      ..._captures,
    ];

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => InspectionReviewScreen(
              captures: mergedCaptures,
              tipoImovel: '${widget.tipoImovel} • ${widget.subtipoImovel}',
              cameFromCheckinStep1: widget.cameFromCheckinStep1,
            ),
      ),
    );
  }

  Future<void> _syncStep2DraftFromBatchCaptures() async {
    if (!widget.cameFromCheckinStep1 || _captures.isEmpty || !mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final mergedStep2 = _buildStep2PayloadFromCaptures(
      existingStep2Payload: appState.step2Payload,
      captures: _captures,
      tipoImovel: widget.tipoImovel,
    );

    final draft = appState.inspectionRecoveryDraft;
    await appState.setInspectionRecoveryStage(
      stageKey: draft?.stageKey ?? 'checkin_step1',
      stageLabel: draft?.stageLabel ?? 'Check-in etapa 1',
      routeName: draft?.routeName ?? '/checkin',
      payload: {
        ...appState.inspectionRecoveryPayload,
        'step1': appState.step1Payload,
        'step2': mergedStep2,
      },
    );
  }

  Map<String, dynamic> _buildStep2PayloadFromCaptures({
    required Map<String, dynamic> existingStep2Payload,
    required List<OverlayCameraCaptureResult> captures,
    required String tipoImovel,
  }) {
    final tipo = TipoImovelExtension.fromString(tipoImovel);
    var model = CheckinDynamicConfigService.instance.restoreStep2Model(
      tipo: tipo,
      step2Payload: existingStep2Payload,
    );
    final appState = Provider.of<AppState>(context, listen: false);
    final config = CheckinDynamicConfigService.instance
        .resolveStoredStep2Config(
          tipo: tipo,
          inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
        );

    for (final campo in config.camposFotos) {
      final matchedCapture = _requirementPolicy.findMatchingCapture(
        captures: captures,
        field: campo,
      );

      if (matchedCapture != null) {
        model = model.setPhoto(
          fieldId: campo.id,
          titulo: campo.titulo,
          imagePath: matchedCapture.filePath,
          geoPoint: matchedCapture.toGeoPointData(),
        );
      }
    }

    return model.toMap();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _selectFromVoiceSheet({
    required String title,
    required List<String> values,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) async {
    if (values.isEmpty) return;

    final picked = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: values,
      title: title,
      currentValue: selected,
    );

    if (picked == null || picked.trim().isEmpty) return;
    if (!mounted) return;

    onSelect(picked);
  }

  Future<void> _handleCameraVoiceCommand(VoiceCommandMatch match) async {
    switch (match.commandId) {
      case 'capturar_foto':
        await _capture();
        return;
      case 'abrir_area':
        if (_showMacroLocalSelector && _isCameraLevelEnabled('macroLocal')) {
          await _selectFromVoiceSheet(
            title: _labelForCameraLevel('macroLocal'),
            values: _macroLocais,
            selected: _macroLocal,
            onSelect: _selectMacroLocal,
          );
        }
        return;
      case 'abrir_local':
        if (_isCameraLevelEnabled('ambiente') &&
            _macroLocal != null &&
            _ambientesAtuais.isNotEmpty) {
          await _selectFromVoiceSheet(
            title: _labelForCameraLevel('ambiente'),
            values: _ambientesAtuais,
            selected: _ambiente,
            onSelect: _selectAmbiente,
          );
        }
        return;
      case 'abrir_elemento':
        if (_isCameraLevelEnabled('elemento') &&
            _ambiente != null &&
            _elementosAtuais.isNotEmpty) {
          await _selectFromVoiceSheet(
            title: _labelForCameraLevel('elemento'),
            values: _elementosAtuais,
            selected: _elemento,
            onSelect: _selectElemento,
          );
        }
        return;
      case 'abrir_material':
        if (_isCameraLevelEnabled('material') &&
            _elemento != null &&
            _materiaisAtuais.isNotEmpty) {
          await _selectFromVoiceSheet(
            title: _labelForCameraLevel('material'),
            values: _materiaisAtuais,
            selected: _material,
            onSelect: (value) {
              setState(() {
                _material = value;
                _estado = null;
              });
            },
          );
        }
        return;
      case 'abrir_estado':
        if (_isCameraLevelEnabled('estado') &&
            _elemento != null &&
            (_materiaisAtuais.isEmpty || _material != null)) {
          await _selectFromVoiceSheet(
            title: _labelForCameraLevel('estado'),
            values: _estadosAtuais,
            selected: _estado,
            onSelect: (value) {
              setState(() => _estado = value);
            },
          );
        }
        return;
    }
  }

  List<String> _normalizeCameraLevels(List<String> rawLevels) {
    final normalized = <String>[];
    for (final raw in rawLevels) {
      final mapped = _mapCameraLevelId(raw);
      if (mapped == null) {
        continue;
      }
      if (!normalized.contains(mapped)) {
        normalized.add(mapped);
      }
    }

    if (normalized.isEmpty) {
      return List<String>.from(_defaultCameraLevels);
    }
    return normalized;
  }

  String? _mapCameraLevelId(String raw) {
    return _semanticFieldService.mapCameraLevelId(raw);
  }

  bool _isCameraLevelEnabled(String id) => _cameraLevelOrder.contains(id);

  String? get _newAmbienteActionLabel {
    final selectedAmbiente = _ambiente;
    if (selectedAmbiente == null || selectedAmbiente.trim().isEmpty) {
      return null;
    }

    final parsed = _environmentInstanceService.parse(selectedAmbiente);
    if (parsed.baseLabel.trim().isEmpty) {
      return null;
    }
    return 'Novo ${parsed.baseLabel}';
  }

  String _labelForCameraLevel(String levelId) {
    final configured = _cameraLevelLabels[levelId]?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    switch (levelId) {
      case 'macroLocal':
        return 'Área da foto';
      case 'ambiente':
        return 'Local da foto';
      case 'elemento':
        return 'Elemento fotografado';
      case 'material':
        return 'Material';
      case 'estado':
        return 'Estado';
    }
    return levelId;
  }

  Map<String, String> _resolveCameraLevelLabels(
    List<ConfigLevelDefinition> levels,
  ) {
    if (levels.isEmpty) {
      return const <String, String>{};
    }

    final labels = <String, String>{};
    for (final level in levels) {
      final cameraLevelId =
          _semanticFieldService.mapCameraLevelId(level.id) ??
          _semanticFieldService.cameraLevelIdForSemantic(
            level.semanticKey ?? '',
          );
      if (cameraLevelId == null || cameraLevelId.trim().isEmpty) {
        continue;
      }
      labels[cameraLevelId] = _semanticFieldService.labelForLevel(
        level: level,
        surface: InspectionSurfaceKeys.camera,
      );
    }
    return labels;
  }

  List<Widget> _buildCameraSelectors() {
    final widgets = <Widget>[];

    for (final level in _cameraLevelOrder) {
      switch (level) {
        case 'macroLocal':
          if (_showMacroLocalSelector) {
            widgets.add(const SizedBox(height: 8));
            widgets.add(
              _carouselCard(
                title: _labelForCameraLevel('macroLocal'),
                values: _macroLocais,
                selected: _macroLocal,
                onSelect: _selectMacroLocal,
              ),
            );
          }
          break;
        case 'ambiente':
          if (_macroLocal != null) {
            widgets.add(const SizedBox(height: 8));
            widgets.add(
              _carouselCard(
                title: _labelForCameraLevel('ambiente'),
                values: _ambientesAtuais,
                selected: _ambiente,
                onSelect: _selectAmbiente,
              ),
            );
            if (_ambiente != null && _ambiente!.trim().isNotEmpty) {
              widgets.add(const SizedBox(height: 6));
              widgets.add(
                _contextActionRow(
                  currentLabel: _ambiente!,
                  onChange: () => _selectFromVoiceSheet(
                    title: _labelForCameraLevel('ambiente'),
                    values: _ambientesAtuais,
                    selected: _ambiente,
                    onSelect: _selectAmbiente,
                  ),
                  onDuplicate: _duplicateCurrentAmbiente,
                  duplicateLabel: _newAmbienteActionLabel ?? 'Novo ambiente',
                ),
              );
            }
          }
          break;
        case 'elemento':
          if (_ambiente != null && _elementosAtuais.isNotEmpty) {
            widgets.add(const SizedBox(height: 8));
            widgets.add(
              _carouselCard(
                title: _labelForCameraLevel('elemento'),
                values: _elementosAtuais,
                selected: _elemento,
                onSelect: _selectElemento,
              ),
            );
          }
          break;
        case 'material':
          if (_elemento != null && _materiaisAtuais.isNotEmpty) {
            widgets.add(const SizedBox(height: 8));
            widgets.add(
              _carouselCard(
                title: _labelForCameraLevel('material'),
                values: _materiaisAtuais,
                selected: _material,
                onSelect: (value) async {
                  setState(() {
                    _material = value;
                    _estado = null;
                  });
                },
              ),
            );
          }
          break;
        case 'estado':
          if (_elemento != null &&
              (_materiaisAtuais.isEmpty || _material != null)) {
            widgets.add(const SizedBox(height: 8));
            widgets.add(
              _carouselCard(
                title: _labelForCameraLevel('estado'),
                values: _estadosAtuais,
                selected: _estado,
                onSelect: (value) async {
                  setState(() => _estado = value);
                },
              ),
            );
          }
          break;
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing || _loadingMenus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!),
          ),
        ),
      );
    }

    final resumo = [
      if (_macroLocal != null) _macroLocal!,
      if (_ambiente != null) _ambiente!,
      if (_elemento != null) _elemento!,
      if (_material != null) _material!,
      if (_estado != null) _estado!,
    ].join(' > ');

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child:
                _controller == null
                    ? const SizedBox.shrink()
                    : CameraPreview(_controller!),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _glassButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.showVoiceActions)
                          _glassButton(
                            icon: Icons.mic_none,
                            onTap: _openVoiceSheet,
                          ),
                        if (widget.showVoiceActions)
                          const SizedBox(width: 8),
                        _glassButton(
                          icon: Icons.checklist_outlined,
                          onTap:
                              (!widget.singleCaptureMode && _hasAnyCaptures)
                                  ? _finalizeBatch
                                  : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab de colapso lateral
                        GestureDetector(
                          onTap:
                              () => setState(
                                () =>
                                    _selectorsCollapsed =
                                        !_selectorsCollapsed,
                              ),
                          child: Container(
                            width: 22,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                            child: Icon(
                              _selectorsCollapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        // Painel de seletores (colapsável)
                        if (!_selectorsCollapsed)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._buildCameraSelectors(),
                                if (_contextSuggestionSummary != null) ...[
                                  const SizedBox(height: 8),
                                  _hintCard(_contextSuggestionSummary!),
                                ],
                                if (_isCameraLevelEnabled('ambiente') &&
                                    _recentAmbientes.isNotEmpty &&
                                    _macroLocal != null) ...[
                                  const SizedBox(height: 8),
                                  _quickSuggestionCard(
                                    title: 'Locais mais usados nesta área',
                                    values: _recentAmbientes,
                                    selected: _ambiente,
                                    onSelect: _selectAmbiente,
                                  ),
                                ],
                                if (_predictionSummary != null) ...[
                                  const SizedBox(height: 8),
                                  _hintCard(_predictionSummary!),
                                ],
                                if (_isCameraLevelEnabled('elemento') &&
                                    _recentElementos.isNotEmpty &&
                                    _ambiente != null) ...[
                                  const SizedBox(height: 8),
                                  _quickSuggestionCard(
                                    title: 'Mais usados neste contexto',
                                    values: _recentElementos,
                                    selected: _elemento,
                                    onSelect: _selectElemento,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Capturas no lote: ${_captures.length}${resumo.isEmpty ? '' : ' • $resumo'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _circleAction(
                          icon: Icons.photo_library_outlined,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Galeria permanece no fluxo atual.',
                                ),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _capturing ? null : _capture,
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.96),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.18),
                                width: 3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child:
                                _capturing
                                    ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                    : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black12,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                        const Spacer(),
                        _buildFinalizeButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
              onTap == null
                  ? Colors.black.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _circleAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildFinalizeButton() {
    if (widget.singleCaptureMode) {
      return _circleAction(
        icon: Icons.fact_check_outlined,
        onTap: () => Navigator.of(context).pop(),
      );
    }

    if (!_hasAnyCaptures) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.fact_check_outlined,
          color: Colors.white38,
          size: 22,
        ),
      );
    }

    return GestureDetector(
      onTap: _finalizeBatch,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE65100),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revisar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  _captures.isNotEmpty
                      ? '${_captures.length} nova(s)'
                      : 'fotos anteriores',
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _hintCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _quickSuggestionCard({
    required String title,
    required List<String> values,
    required String? selected,
    required Future<void> Function(String value) onSelect,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            ...values.map((value) {
              final active = value == selected;
              return GestureDetector(
                onTap: () => onSelect(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: active ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _carouselCard({
    required String title,
    required List<String> values,
    required String? selected,
    required Future<void> Function(String value) onSelect,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (values.isNotEmpty)
                    IconButton(
                      tooltip: 'Selecionar por voz',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: const Icon(
                        Icons.mic_none,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed:
                          () => _selectFromVoiceSheet(
                            title: title,
                            values: values,
                            selected: selected,
                            onSelect: onSelect,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = values[index];
                  final active = value == selected;
                  return GestureDetector(
                    onTap: () => onSelect(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: active ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contextActionRow({
    required String currentLabel,
    required Future<void> Function() onChange,
    required Future<void> Function() onDuplicate,
    required String duplicateLabel,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              currentLabel,
              key: const ValueKey('camera_current_ambiente_label'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            OutlinedButton(
              onPressed: onChange,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              child: const Text('Trocar'),
            ),
            FilledButton(
              onPressed: onDuplicate,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              child: Text(duplicateLabel),
            ),
          ],
        ),
      ),
    );
  }
}
