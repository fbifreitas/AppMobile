import 'package:camera/camera.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../config/inspection_menu_package.dart';
import '../l10n/app_strings.dart';
import '../models/flow_selection.dart';
import '../models/inspection_camera_menu_view_state.dart';
import '../models/inspection_camera_selector_section.dart';
import '../models/inspection_menu_intelligence_models.dart';
import '../models/overlay_camera_capture_result.dart';
import '../models/smart_execution_plan.dart';
import '../services/inspection_camera_batch_flow_use_case.dart';
import '../services/inspection_camera_batch_service.dart';
import '../services/inspection_capture_flow_transition_service.dart';
import '../services/inspection_camera_menu_resolver.dart';
import '../services/inspection_domain_adapter.dart';
import '../services/inspection_camera_level_presentation_service.dart';
import '../services/inspection_camera_presentation_service.dart';
import '../services/inspection_camera_selector_section_service.dart';
import '../services/inspection_camera_voice_command_service.dart';
import '../services/inspection_context_actions_service.dart';
import '../services/inspection_environment_instance_service.dart';
import '../services/inspection_recovery_route_service.dart';
import '../services/inspection_recovery_stage_service.dart';
import '../services/inspection_menu_service.dart';
import '../services/inspection_semantic_field_service.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/voice_command_catalog_service.dart';
import '../services/voice_command_parser_service.dart';
import '../services/voice_input_service.dart';
import '../state/app_state.dart';
import '../widgets/camera/overlay_camera_selector_panel.dart';
import '../widgets/camera/overlay_camera_support_widgets.dart';
import '../widgets/voice_action_bar.dart';
import '../widgets/voice_selector_sheet.dart';
import 'inspection_review_screen.dart';

class OverlayCameraScreen extends StatefulWidget {
  final String title;
  final String tipoImovel;
  final String subtipoImovel;
  final bool singleCaptureMode;
  final bool freeCaptureMode;

  /// Canonical initial flow state - domain-agnostic contract.
  /// Inspection domain values are derived internally via [InspectionDomainAdapter].
  final FlowSelectionState? initialFlowState;

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
    this.freeCaptureMode = false,
    this.initialFlowState,
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

  static const Map<String, String> _planDrivenLevelLabels = <String, String>{
    'macroLocal': 'Área da foto',
    'ambiente': 'Local da foto',
    'elemento': 'Elemento fotografado',
    'material': 'Material',
    'estado': 'Estado',
  };

  final InspectionMenuService _menuService = InspectionMenuService.instance;
  final InspectionEnvironmentInstanceService _environmentInstanceService =
      InspectionEnvironmentInstanceService.instance;
  final InspectionContextActionsService _contextActionsService =
      InspectionContextActionsService.instance;
  final InspectionCameraLevelPresentationService _cameraLevelPresentationService =
      InspectionCameraLevelPresentationService.instance;
  final InspectionCameraSelectorSectionService _selectorSectionService =
      InspectionCameraSelectorSectionService.instance;
  late final InspectionCameraMenuResolver _cameraMenuResolver =
      InspectionCameraMenuResolver(menuService: _menuService);
  late final InspectionCaptureFlowTransitionService _flowTransitionService =
      InspectionCaptureFlowTransitionService(
        menuService: _menuService,
        environmentInstanceService: _environmentInstanceService,
        contextActionsService: _contextActionsService,
      );
  static const InspectionDomainAdapter _domainAdapter =
      InspectionDomainAdapter.instance;
  final InspectionCameraBatchService _batchService =
      InspectionCameraBatchService.instance;
  final InspectionCameraBatchFlowUseCase _batchFlowUseCase =
      InspectionCameraBatchFlowUseCase.instance;
  final InspectionRecoveryRouteService _recoveryRouteService =
      InspectionRecoveryRouteService.instance;
  final InspectionRecoveryStageService _recoveryStageService =
      InspectionRecoveryStageService.instance;
  final InspectionCameraPresentationService _presentationService =
      InspectionCameraPresentationService.instance;
  final InspectionCameraVoiceCommandService _voiceCommandService =
      InspectionCameraVoiceCommandService.instance;
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

  /// Canonical flow state - single source of truth for the capture flow.
  FlowSelectionState _flowState = FlowSelectionState.bootstrap();

  List<String> _macroLocais = const [];
  List<String> _ambientesAtuais = const [];
  List<String> _elementosAtuais = const [];
  List<String> _materiaisAtuais = const [];
  List<String> _estadosAtuais = const [];
  List<String> _recentAmbientes = const [];
  List<String> _recentElementos = const [];
  List<String> _cameraLevelOrder = List<String>.from(_defaultCameraLevels);
  Map<String, String> _cameraLevelLabels = const <String, String>{};
  List<InspectionCameraSelectorSection> _selectorSections =
      const <InspectionCameraSelectorSection>[];

  PredictedSelection? _predictedSelection;
  String? _contextSuggestionSummary;
  final List<OverlayCameraCaptureResult> _captures = [];
  bool _hasPreviousPhotos = false;
  bool _selectorsCollapsed = false;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;

  String? get _predictionSummary {
    final strings = AppStrings.of(context);
    final prediction = _predictedSelection;
    if (prediction == null || !prediction.hasAnyValue) return null;
    final parts = <String>[];
    if (prediction.elemento != null) parts.add(prediction.elemento!);
    if (prediction.material != null) parts.add(prediction.material!);
    if (prediction.estado != null) parts.add(prediction.estado!);
    if (parts.isEmpty) return null;
    return strings.tr(
      'Sugestao silenciosa com base em ${prediction.captures} captura(s): ${parts.join(' • ')}',
      'Silent suggestion based on ${prediction.captures} capture(s): ${parts.join(' • ')}',
    );
  }

  // Canonical accessors.

  bool get _showMacroLocalSelector =>
      _cameraLevelOrder.contains('macroLocal') || _macroLocais.isNotEmpty;

  bool get _hasAnyCaptures => _captures.isNotEmpty || _hasPreviousPhotos;

  String? get _subjectContext => _flowState.currentSelection.subjectContext;
  String? get _targetItem => _flowState.currentSelection.targetItem;
  String? get _targetQualifier => _flowState.currentSelection.targetQualifier;




  @override
  void initState() {
    super.initState();
    _flowState = widget.initialFlowState ?? FlowSelectionState.bootstrap();
    _hydrateCapturedBatchFromRecovery();
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
        final flowState = widget.initialFlowState ?? FlowSelectionState.bootstrap();
        final levelOrder = _normalizeCameraLevels(
          widget.testCameraLevelOrder ?? const <String>[],
        );
        final labels = _resolveCameraLevelLabels(const <ConfigLevelDefinition>[]);
        final macroLocais = List<String>.from(widget.testMacroLocais);
        final ambientes = List<String>.from(widget.testAmbientes);
        final elementos = List<String>.from(widget.testElementos);
        final materiais = List<String>.from(widget.testMateriais);
        final estados = List<String>.from(widget.testEstados);
        setState(() {
          _flowState = flowState;
          _cameraLevelOrder = levelOrder;
          _cameraLevelLabels = labels;
          _macroLocais = macroLocais;
          _ambientesAtuais = ambientes;
          _elementosAtuais = elementos;
          _materiaisAtuais = materiais;
          _estadosAtuais = estados;
          _selectorSections = _selectorSectionService.buildSections(
            levelOrder: _cameraLevelOrder,
            labelsByLevel: _cameraLevelLabels,
            selectionState: _flowState,
            macroLocais: _macroLocais,
            ambientes: _ambientesAtuais,
            elementos: _elementosAtuais,
            materiais: _materiaisAtuais,
            estados: _estadosAtuais,
          );
          _loadingMenus = false;
          _initializing = false;
        });
        return;
      }

      await _menuService.ensureLoaded();
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      final executionPlan = appState.currentExecutionPlan;
      final configuredLevels = await _menuService.getCameraLevelOrder(
        propertyType: widget.tipoImovel,
        subtipo: widget.subtipoImovel,
      );
      final configuredLevelDefinitions = await _menuService.getCameraLevels(
        propertyType: widget.tipoImovel,
        subtipo: widget.subtipoImovel,
      );
      if (widget.freeCaptureMode) {
        _cameraLevelOrder = const <String>[];
        _cameraLevelLabels = const <String, String>{};
        _macroLocais = const <String>[];
        _ambientesAtuais = const <String>[];
        _elementosAtuais = const <String>[];
        _materiaisAtuais = const <String>[];
        _estadosAtuais = const <String>[];
        _selectorSections = const <InspectionCameraSelectorSection>[];
        _loadingMenus = false;
      } else {
        _cameraLevelOrder = _resolveCameraLevelOrder(
          configuredLevels,
          executionPlan: executionPlan,
        );
        _cameraLevelLabels = _resolveCameraLevelLabels(
          configuredLevelDefinitions,
          executionPlan: executionPlan,
        );
        await _reloadMenus(initialLoad: true);
      }

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
      await _loadZoomBounds(controller);

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
      final strings = AppStrings.of(context);
      setState(() {
        _initializing = false;
        _loadingMenus = false;
        _error = strings.tr(
          'Falha ao inicializar a camera: $error',
          'Failed to initialize camera: $error',
        );
      });
    }
  }

  Future<void> _reloadMenus({bool initialLoad = false}) async {
    if (mounted) {
      setState(() => _loadingMenus = true);
    }

    final developerMockDocument =
        await CheckinDynamicConfigService.instance.loadDeveloperMockDocument();
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final executionPlan =
        developerMockDocument == null
            ? appState.currentExecutionPlan
            : null;

    final viewState = await _cameraMenuResolver.resolve(
      propertyType: widget.tipoImovel,
      subtipo: widget.subtipoImovel,
      executionPlan: executionPlan,
      currentKnownAmbientes: _ambientesAtuais,
      showMacroLocalSelector: _showMacroLocalSelector,
      initialLoad: initialLoad,
      initialSuggestedSelection: _flowState.initialSuggestedSelection,
      currentSelection: _flowState.currentSelection,
    );

    if (!mounted) return;
    setState(() {
      _applyResolvedMenuViewState(viewState);
      _loadingMenus = false;
    });
    await _persistCameraStage();
  }

  Future<void> _loadZoomBounds(CameraController controller) async {
    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final normalizedMin = minZoom.isFinite ? minZoom : 1.0;
      final normalizedMax = maxZoom.isFinite ? maxZoom : normalizedMin;
      final preferredZoom = math.max(1.0, normalizedMin);
      final clampedPreferred = preferredZoom.clamp(normalizedMin, normalizedMax);
      await controller.setZoomLevel(clampedPreferred);
      if (!mounted) return;
      setState(() {
        _minZoomLevel = normalizedMin;
        _maxZoomLevel = normalizedMax;
        _currentZoomLevel = clampedPreferred;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _minZoomLevel = 1.0;
        _maxZoomLevel = 1.0;
        _currentZoomLevel = 1.0;
      });
    }
  }

  bool get _canZoom => _maxZoomLevel > (_minZoomLevel + 0.05);

  Future<void> _setZoomLevel(double value) async {
    final controller = _controller;
    if (controller == null || !_canZoom) {
      return;
    }
    final clamped = value.clamp(_minZoomLevel, _maxZoomLevel);
    await controller.setZoomLevel(clamped);
    if (!mounted) return;
    setState(() => _currentZoomLevel = clamped);
  }

  Future<void> _persistCameraStage() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final jobId = appState.jobAtual?.id;
    if (jobId == null) return;
    await appState.setInspectionRecoverySnapshot(
      _recoveryStageService.camera(
        jobId: jobId,
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
        cameraStagePayload: _recoveryRouteService.buildCameraStagePayload(
          title: widget.title,
          tipoImovel: widget.tipoImovel,
          subtipoImovel: widget.subtipoImovel,
          singleCaptureMode: widget.singleCaptureMode,
          freeCaptureMode: widget.freeCaptureMode,
          cameFromCheckinStep1: widget.cameFromCheckinStep1,
          selection: _flowState.currentSelection,
          captures: _captures,
        ),
        step1Payload: appState.step1Payload,
        step2Payload: appState.step2Payload,
      ),
    );
  }

  void _hydrateCapturedBatchFromRecovery() {
    if (!widget.cameFromCheckinStep1) {
      return;
    }
    final appState = Provider.of<AppState>(context, listen: false);
    final rawCameraStage = appState.inspectionRecoveryPayload['cameraStage'];
    if (rawCameraStage is! Map) {
      return;
    }
    final rawCaptures = rawCameraStage['captures'];
    if (rawCaptures is! List) {
      return;
    }
    final restored = <OverlayCameraCaptureResult>[];
    for (final rawCapture in rawCaptures) {
      if (rawCapture is Map<String, dynamic>) {
        restored.add(OverlayCameraCaptureResult.fromMap(rawCapture));
        continue;
      }
      if (rawCapture is Map) {
        restored.add(
          OverlayCameraCaptureResult.fromMap(
            rawCapture.map((key, value) => MapEntry('$key', value)),
          ),
        );
      }
    }
    if (restored.isEmpty) {
      return;
    }
    _captures
      ..clear()
      ..addAll(restored);
    _hasPreviousPhotos = true;
  }

  void _applyResolvedMenuViewState(InspectionCameraMenuViewState viewState) {
    _macroLocais = viewState.macroLocais;
    _ambientesAtuais = viewState.ambientes;
    _elementosAtuais = viewState.elementos;
    _materiaisAtuais = viewState.materiais;
    _estadosAtuais = viewState.estados;
    _recentAmbientes = viewState.recentAmbientes;
    _recentElementos = viewState.recentElementos;
    _predictedSelection = viewState.prediction;
    _contextSuggestionSummary = viewState.contextSuggestionSummary;
    _flowState = _flowState.copyWith(
      currentSelection: viewState.currentSelection,
    );
    _selectorSections = _selectorSectionService.buildSections(
      levelOrder: _cameraLevelOrder,
      labelsByLevel: _cameraLevelLabels,
      selectionState: _flowState,
      macroLocais: _macroLocais,
      ambientes: _ambientesAtuais,
      elementos: _elementosAtuais,
      materiais: _materiaisAtuais,
      estados: _estadosAtuais,
    );
  }

  void _rebuildSelectorSections() {
    _selectorSections = _selectorSectionService.buildSections(
      levelOrder: _cameraLevelOrder,
      labelsByLevel: _cameraLevelLabels,
      selectionState: _flowState,
      macroLocais: _macroLocais,
      ambientes: _ambientesAtuais,
      elementos: _elementosAtuais,
      materiais: _materiaisAtuais,
      estados: _estadosAtuais,
    );
  }

  Future<void> _ensureLocationReady() async {
    final strings = AppStrings.of(context);
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(
        strings.tr(
          'Ative o GPS do aparelho.',
          'Enable the device GPS.',
        ),
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        strings.tr(
          'Permissao de localizacao nao concedida.',
          'Location permission not granted.',
        ),
      );
    }
  }

  Future<void> _selectSubjectContext(String value) async {
    final result = await _flowTransitionService.selectSubjectContext(
      propertyType: widget.tipoImovel,
      selectionState: _flowState,
      value: value,
    );
    setState(() {
      _flowState = result.selectionState;
      _rebuildSelectorSections();
    });
    await _reloadMenus();
  }

  Future<void> _selectTargetItem(String value) async {
    final result = await _flowTransitionService.selectTargetItem(
      propertyType: widget.tipoImovel,
      selectionState: _flowState,
      value: value,
    );
    setState(() {
      _flowState = result.selectionState;
      _rebuildSelectorSections();
    });
    await _reloadMenus();
  }

  Future<void> _duplicateTargetItem() async {
    final result = await _flowTransitionService.duplicateTargetItem(
      propertyType: widget.tipoImovel,
      selectionState: _flowState,
      selectedAmbiente: _targetItem,
      existingAmbientes: _ambientesAtuais,
      useTestMenuData: widget.useTestMenuData,
    );
    if (result == null) return;

    setState(() {
      _ambientesAtuais = result.ambientes ?? _ambientesAtuais;
      _flowState = result.selectionState;
      _rebuildSelectorSections();
    });

    if (widget.useTestMenuData) return;

    await _reloadMenus();
  }

  Future<void> _selectTargetQualifier(String value) async {
    final result = await _flowTransitionService.selectTargetQualifier(
      propertyType: widget.tipoImovel,
      selectionState: _flowState,
      value: value,
    );
    setState(() {
      _flowState = result.selectionState;
      _rebuildSelectorSections();
    });
    await _reloadMenus();
  }

  Future<void> _selectMaterial(String value) async {
    final result = _flowTransitionService.selectMaterial(
      selectionState: _flowState,
      value: value,
    );
    setState(() {
      _flowState = result.selectionState;
      _rebuildSelectorSections();
    });
  }

  Future<void> _selectTargetCondition(String value) async {
    final result = _flowTransitionService.selectTargetCondition(
      selectionState: _flowState,
      value: value,
    );
    setState(() {
      _flowState = result.selectionState;
      _rebuildSelectorSections();
    });
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final strings = AppStrings.of(context);

    if (!widget.freeCaptureMode &&
        (_targetItem == null || _targetItem!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              'Selecione o local da foto antes de capturar.',
              'Select the photo location before capturing.',
            ),
          ),
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
      final sel = _flowState.currentSelection;
      final freeCaptureLabel = strings.tr('Captura livre', 'Free capture');
      final result = _batchService.buildCaptureResult(
        filePath: file.path,
        macroLocal: widget.freeCaptureMode ? null : sel.subjectContext,
        ambiente:
            (widget.freeCaptureMode
                ? (sel.targetItem?.trim().isNotEmpty == true
                      ? sel.targetItem!
                      : freeCaptureLabel)
                : sel.targetItem!),
        elemento: widget.freeCaptureMode ? null : sel.targetQualifier,
        material: widget.freeCaptureMode ? null : _domainAdapter.inspectionMaterialOf(sel),
        estado: widget.freeCaptureMode ? null : sel.targetCondition,
        applicableClassificationLevels: widget.freeCaptureMode
            ? const <String>[]
            : _selectorSections
                .where(
                  (section) =>
                      (section.levelId == 'elemento' ||
                          section.levelId == 'material' ||
                          section.levelId == 'estado') &&
                      section.values.isNotEmpty,
                )
                .map((section) => section.levelId)
                .toList(),
        capturedAt: DateTime.now(),
        position: position,
        predictionSummary: _predictionSummary,
        contextSuggestionSummary: _contextSuggestionSummary,
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
            strings.tr(
              'Foto adicionada ao lote.',
              'Photo added to the batch.',
            ),
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
    final appState = Provider.of<AppState>(context, listen: false);
    final hasPersistedPhotos = _batchFlowUseCase.hasPersistedPhotos(appState);
    if (hasPersistedPhotos) {
      setState(() => _hasPreviousPhotos = true);
    }
  }

  // ignore: unused_element
  void _openVoiceSheet() {
    final strings = AppStrings.of(context);
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
              title: strings.tr('Comandos rapidos por voz', 'Quick voice commands'),
              subtitle: strings.tr(
                'Ex.: capturar foto, abrir area, abrir local, abrir elemento.',
                'Example: capture photo, open area, open location, open element.',
              ),
              onCommand: _handleCameraVoiceCommand,
            ),
          ),
    );
  }

  void _finalizeBatch() async {
    if (!_hasAnyCaptures) return;

    await _syncStep2DraftFromBatchCaptures();

    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final mergedCaptures = _batchFlowUseCase.mergeReviewCaptures(
      currentCaptures: _captures,
      appState: appState,
    );

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => InspectionReviewScreen(
              captures: mergedCaptures,
              tipoImovel: '${widget.tipoImovel} â€¢ ${widget.subtipoImovel}',
              cameFromCheckinStep1: widget.cameFromCheckinStep1,
            ),
      ),
    );
  }

  Future<void> _syncStep2DraftFromBatchCaptures() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    await _batchFlowUseCase.syncStep2DraftFromBatchCaptures(
      appState: appState,
      captures: _captures,
      tipoImovel: widget.tipoImovel,
      cameFromCheckinStep1: widget.cameFromCheckinStep1,
    );
    await _persistCameraStage();
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
    if (_voiceCommandService.isCaptureCommand(match.commandId)) {
      await _capture();
      return;
    }

    final levelId = _voiceCommandService.selectorLevelForCommand(match.commandId);
    if (levelId == null) return;

    final section = _selectorSection(levelId);
    if (section == null) return;

    switch (levelId) {
      case 'macroLocal':
        await _selectFromVoiceSheet(
          title: section.title,
          values: section.values,
          selected: section.selected,
          onSelect: _selectSubjectContext,
        );
        return;
      case 'ambiente':
        await _selectFromVoiceSheet(
          title: section.title,
          values: section.values,
          selected: section.selected,
          onSelect: _selectTargetItem,
        );
        return;
      case 'elemento':
        await _selectFromVoiceSheet(
          title: section.title,
          values: section.values,
          selected: section.selected,
          onSelect: _selectTargetQualifier,
        );
        return;
      case 'material':
        await _selectFromVoiceSheet(
          title: section.title,
          values: section.values,
          selected: section.selected,
          onSelect: _selectMaterial,
        );
        return;
      case 'estado':
        await _selectFromVoiceSheet(
          title: section.title,
          values: section.values,
          selected: section.selected,
          onSelect: _selectTargetCondition,
        );
        return;
    }
  }

  List<String> _normalizeCameraLevels(List<String> rawLevels) =>
      _cameraLevelPresentationService.normalizeLevelOrder(rawLevels);

  List<String> _resolveCameraLevelOrder(
    List<String> rawLevels, {
    required SmartExecutionPlan? executionPlan,
  }) {
    final fallback = _normalizeCameraLevels(rawLevels);
    final profiles = _safeCompositionProfiles(executionPlan);
    if (profiles.isEmpty) {
      return fallback;
    }

    final derived = <String>['macroLocal', 'ambiente'];
    final hasElements = profiles.any(
      (profile) => profile.elements.isNotEmpty,
    );
    final hasMaterials = profiles.any(
      (profile) => profile.elements.any((element) => element.materials.isNotEmpty),
    );
    final hasStates = profiles.any(
      (profile) => profile.elements.any((element) => element.states.isNotEmpty),
    );

    if (hasElements) {
      derived.add('elemento');
    }
    if (hasMaterials) {
      derived.add('material');
    }
    if (hasStates) {
      derived.add('estado');
    }

    return derived.isNotEmpty ? derived : fallback;
  }

  bool _hasSelectorSection(String levelId) =>
      _selectorSections.any((section) => section.levelId == levelId);

  InspectionCameraSelectorSection? _selectorSection(String levelId) {
    for (final section in _selectorSections) {
      if (section.levelId == levelId) {
        return section;
      }
    }
    return null;
  }

  Map<String, String> _resolveCameraLevelLabels(
    List<ConfigLevelDefinition> levels, {
    SmartExecutionPlan? executionPlan,
  }) {
    final labels = _cameraLevelPresentationService.resolveLabelsByLevel(
      levels: levels,
      surface: InspectionSurfaceKeys.camera,
    );
    if (_safeCompositionProfiles(executionPlan).isEmpty) {
      return labels;
    }
    return <String, String>{
      ..._planDrivenLevelLabels,
      ...labels,
    };
  }

  List<SmartExecutionCameraEnvironmentProfile> _safeCompositionProfiles(
    SmartExecutionPlan? executionPlan,
  ) {
    final profiles = executionPlan?.compositionProfiles;
    if (profiles == null || profiles.isEmpty) {
      return const <SmartExecutionCameraEnvironmentProfile>[];
    }
    return profiles.whereType<SmartExecutionCameraEnvironmentProfile>().toList(
      growable: false,
    );
  }

  Widget _buildSelectorColumn({
    required AppStrings strings,
    required InspectionCameraPresentationData presentation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverlayCameraSelectorPanel(
          sections: _selectorSections,
          onSelectSubjectContext: _selectSubjectContext,
          onSelectTargetItem: _selectTargetItem,
          onDuplicateTargetItem: _duplicateTargetItem,
          onSelectTargetQualifier: _selectTargetQualifier,
          onSelectMaterial: _selectMaterial,
          onSelectTargetCondition: _selectTargetCondition,
          onVoiceSelection: ({
            required String title,
            required List<String> values,
            required String? selected,
            required Future<void> Function(String value) onSelect,
          }) {
            return _selectFromVoiceSheet(
              title: title,
              values: values,
              selected: selected,
              onSelect: onSelect,
            );
          },
        ),
        if (presentation.showRecentAmbientes) ...[
          const SizedBox(height: 8),
          OverlayCameraQuickSuggestionCard(
            title: strings.tr(
              'Locais mais usados nesta area',
              'Most used locations in this area',
            ),
            values: _recentAmbientes,
            selected: _targetItem,
            onSelect: (value) => _selectTargetItem(value),
          ),
        ],
        if (presentation.showRecentElementos) ...[
          const SizedBox(height: 8),
          OverlayCameraQuickSuggestionCard(
            title: strings.tr(
              'Mais usados neste contexto',
              'Most used in this context',
            ),
            values: _recentElementos,
            selected: _targetQualifier,
            onSelect: (value) => _selectTargetQualifier(value),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectorToggle() {
    return GestureDetector(
      onTap: () => setState(() => _selectorsCollapsed = !_selectorsCollapsed),
      child: Container(
        width: 36,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          MediaQuery.of(context).orientation == Orientation.landscape
              ? (_selectorsCollapsed ? Icons.chevron_right : Icons.chevron_left)
              : (_selectorsCollapsed ? Icons.expand_more : Icons.expand_less),
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildZoomCard() {
    if (!_canZoom) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.zoom_in, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '${_currentZoomLevel.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                trackHeight: 2.5,
              ),
              child: Slider(
                min: _minZoomLevel,
                max: _maxZoomLevel,
                value: _currentZoomLevel.clamp(_minZoomLevel, _maxZoomLevel),
                onChanged: (value) => _setZoomLevel(value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeZoomRail() {
    if (!_canZoom) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_currentZoomLevel.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 108,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                  trackHeight: 2.5,
                ),
                child: Slider(
                  min: _minZoomLevel,
                  max: _maxZoomLevel,
                  value: _currentZoomLevel.clamp(_minZoomLevel, _maxZoomLevel),
                  onChanged: (value) => _setZoomLevel(value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
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
        child: _capturing
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3),
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
    );
  }

  Widget _buildInfoOverlay(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFreeCaptureInfoCard(AppStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.tr('Modo de captura livre', 'Free capture mode'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.tr(
              'Capture as fotos livremente no app. A classificacao e as obrigatoriedades serao tratadas depois na web.',
              'Capture photos freely in the app. Classification and mandatory rules will be handled later on the web.',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final appState = context.watch<AppState?>();
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
    if (_initializing || _loadingMenus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sel = _flowState.currentSelection;
    final material = _domainAdapter.inspectionMaterialOf(sel);
    final resumo = [
      if (sel.subjectContext != null) sel.subjectContext!,
      if (sel.targetItem != null) sel.targetItem!,
      if (sel.targetQualifier != null) sel.targetQualifier!,
      if (material != null) material,
      if (sel.targetCondition != null) sel.targetCondition!,
    ].join(' > ');
    final presentation = _presentationService.build(
      capturesCount: _captures.length,
      hasPreviousPhotos: _hasPreviousPhotos,
      hasSelectorAmbiente: _hasSelectorSection('ambiente'),
      hasSelectorElemento: _hasSelectorSection('elemento'),
      hasMacroLocal: _subjectContext != null,
      hasAmbiente: _targetItem != null,
      singleCaptureMode: widget.singleCaptureMode,
      resumo: resumo,
      contextSuggestionSummary: _contextSuggestionSummary,
      predictionSummary: _predictionSummary,
      recentAmbientes: _recentAmbientes,
      recentElementos: _recentElementos,
      requiredEvidenceCount: widget.freeCaptureMode
          ? 0
          : (appState?.currentExecutionPlan?.requiredEvidenceCount ?? 0),
    );
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final selectorPanelWidth = isLandscape
        ? math.min(media.size.width * 0.42, 320.0)
        : math.min(media.size.width * 0.84, 360.0);
    const controlBarExtent = 52.0;
    final bottomControlExtent = math.max(media.size.height * 0.18, 170.0);
    final leftRailWidth = isLandscape ? controlBarExtent : 0.0;
    final zoomRailWidth = isLandscape ? 52.0 : 0.0;
    final actionRailWidth = isLandscape ? 86.0 : 0.0;
    final rightRailWidth = isLandscape
        ? math.min(bottomControlExtent, 176.0)
        : 0.0;
    final previewAspectRatio = isLandscape ? 4 / 3 : 3 / 4;
    final topInset = media.padding.top;
    final portraitTopChrome = topInset + controlBarExtent;
    final portraitBottomChrome = bottomControlExtent + media.padding.bottom;

    Widget buildPortraitBottomControls() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildZoomCard(),
          const SizedBox(height: 10),
          _buildInfoOverlay(presentation.batchSummary),
          const SizedBox(height: 10),
          Row(
            children: [
              _circleAction(
                icon: Icons.photo_library_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.tr(
                          'Galeria permanece no fluxo atual.',
                          'Gallery remains in the current flow.',
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              _buildCaptureButton(),
              const Spacer(),
              OverlayCameraFinalizeButton(
                singleCaptureMode: widget.singleCaptureMode,
                hasAnyCaptures: _hasAnyCaptures,
                finalizeSubtitle: presentation.finalizeSubtitle,
                onFinalize: _finalizeBatch,
                onSingleCaptureClose: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      );
    }

    Widget buildLandscapeActionRail() {
      return SizedBox(
        width: actionRailWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleAction(
              icon: Icons.photo_library_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      strings.tr(
                        'Galeria permanece no fluxo atual.',
                        'Gallery remains in the current flow.',
                      ),
                    ),
                  ),
                );
              },
            ),
            _buildCaptureButton(),
            OverlayCameraFinalizeButton(
              singleCaptureMode: widget.singleCaptureMode,
              hasAnyCaptures: _hasAnyCaptures,
              finalizeSubtitle: presentation.finalizeSubtitle,
              onFinalize: _finalizeBatch,
              onSingleCaptureClose: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    Widget buildSelectorOverlay() {
      if (widget.freeCaptureMode) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLandscape
                ? math.min(media.size.width * 0.56, 520.0)
                : selectorPanelWidth,
          ),
          child: _buildFreeCaptureInfoCard(strings),
        );
      }
      final selectorBody = !_selectorsCollapsed
          ? Container(
              constraints: BoxConstraints(
                maxHeight: isLandscape
                    ? math.min(
                        media.size.height - media.padding.vertical - 32,
                        media.size.height * 0.72,
                      )
                    : math.max(
                        180,
                        media.size.height -
                            portraitTopChrome -
                            portraitBottomChrome -
                            40,
                      ),
              ),
              width: isLandscape
                  ? math.min(media.size.width * 0.56, 520.0)
                  : selectorPanelWidth,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12, right: 8),
                    child: _buildSelectorColumn(
                      strings: strings,
                      presentation: presentation,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!_selectorsCollapsed)
            selectorBody,
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black),
          ),
          if (isLandscape)
            Positioned(
              left: leftRailWidth + 6,
              right: rightRailWidth + 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: AspectRatio(
                  aspectRatio: previewAspectRatio,
                  child: _controller == null
                      ? const SizedBox.shrink()
                      : CameraPreview(_controller!),
                ),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              top: portraitTopChrome,
              bottom: portraitBottomChrome,
              child: Center(
                child: AspectRatio(
                  aspectRatio: previewAspectRatio,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _controller == null
                        ? const SizedBox.shrink()
                        : CameraPreview(_controller!),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: isLandscape
                    ? const SizedBox.shrink()
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OverlayCameraGlassButton(
                              icon: Icons.arrow_back_ios_new,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          if (!widget.freeCaptureMode)
                            Align(
                              alignment: Alignment.center,
                              child: _buildSelectorToggle(),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          if (isLandscape)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: leftRailWidth,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      OverlayCameraGlassButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (!widget.freeCaptureMode) _buildSelectorToggle(),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          if (!isLandscape)
            Positioned(
              top: topInset + 8,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: buildSelectorOverlay(),
                ),
              ),
            ),
          if (isLandscape)
            Positioned(
              top: 4,
              left: leftRailWidth + 10,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: buildSelectorOverlay(),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: isLandscape
                    ? const SizedBox.shrink()
                    : buildPortraitBottomControls(),
              ),
            ),
          ),
          if (isLandscape)
            Positioned(
              left: leftRailWidth + 18,
              right: rightRailWidth + 18,
              bottom: media.padding.bottom + 12,
              child: _buildInfoOverlay(presentation.batchSummary),
            ),
          if (isLandscape)
            Positioned(
              right: actionRailWidth + 20,
              top: 0,
              bottom: 0,
              width: zoomRailWidth,
              child: SafeArea(
                child: Center(
                  child: _buildLandscapeZoomRail(),
                ),
              ),
            ),
          if (isLandscape)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              width: actionRailWidth,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: buildLandscapeActionRail(),
                ),
              ),
            ),
        ],
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

}
