import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../config/inspection_menu_package.dart';
import '../models/flow_selection.dart';
import '../models/inspection_camera_menu_view_state.dart';
import '../models/inspection_camera_selector_section.dart';
import '../models/inspection_menu_intelligence_models.dart';
import '../models/overlay_camera_capture_result.dart';
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

  /// Canonical initial flow state — domain-agnostic contract.
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

  /// Canonical flow state — single source of truth for the capture flow.
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

  String? get _predictionSummary {
    final prediction = _predictedSelection;
    if (prediction == null || !prediction.hasAnyValue) return null;
    final parts = <String>[];
    if (prediction.elemento != null) parts.add(prediction.elemento!);
    if (prediction.material != null) parts.add(prediction.material!);
    if (prediction.estado != null) parts.add(prediction.estado!);
    if (parts.isEmpty) return null;
    return 'SugestÃ£o silenciosa com base em ${prediction.captures} captura(s): '
        '${parts.join(' â€¢ ')}';
  }

  // ── canonical accessors ────────────────────────────────────────────────────

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
        _error = 'Falha ao inicializar a cÃ¢mera: $error';
      });
    }
  }

  Future<void> _reloadMenus({bool initialLoad = false}) async {
    if (mounted) {
      setState(() => _loadingMenus = true);
    }

    final viewState = await _cameraMenuResolver.resolve(
      propertyType: widget.tipoImovel,
      subtipo: widget.subtipoImovel,
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

  Future<void> _persistCameraStage() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final draft = appState.inspectionRecoveryDraft;
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
          cameFromCheckinStep1: widget.cameFromCheckinStep1,
          selection: _flowState.currentSelection,
        ),
        step1Payload:
            draft?.payload['step1'] != null ? appState.step1Payload : const {},
        step2Payload:
            draft?.payload['step2'] != null ? appState.step2Payload : const {},
      ),
    );
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
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Ative o GPS do aparelho.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('PermissÃ£o de localizaÃ§Ã£o nÃ£o concedida.');
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

    if (_targetItem == null || _targetItem!.trim().isEmpty) {
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
      final sel = _flowState.currentSelection;
      final result = _batchService.buildCaptureResult(
        filePath: file.path,
        macroLocal: sel.subjectContext,
        ambiente: sel.targetItem!,
        elemento: sel.targetQualifier,
        material: _domainAdapter.inspectionMaterialOf(sel),
        estado: sel.targetCondition,
        applicableClassificationLevels: _selectorSections
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
            result.usedSuggestion
                ? 'Foto adicionada ao lote com sugestÃ£o silenciosa.'
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
    final appState = Provider.of<AppState>(context, listen: false);
    final hasPersistedPhotos = _batchFlowUseCase.hasPersistedPhotos(appState);
    if (hasPersistedPhotos) {
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
              title: 'Comandos rÃ¡pidos por voz',
              subtitle:
                  'Ex.: capturar foto, abrir Ã¡rea, abrir local, abrir elemento.',
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
    List<ConfigLevelDefinition> levels,
  ) {
    return _cameraLevelPresentationService.resolveLabelsByLevel(
      levels: levels,
      surface: InspectionSurfaceKeys.camera,
    );
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
    );

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
                        OverlayCameraGlassButton(
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
                          OverlayCameraGlassButton(
                            icon: Icons.mic_none,
                            onTap: _openVoiceSheet,
                          ),
                        if (widget.showVoiceActions)
                          const SizedBox(width: 8),
                        OverlayCameraGlassButton(
                          icon: Icons.checklist_outlined,
                          onTap: presentation.canOpenChecklist ? _finalizeBatch : null,
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
                        // Painel de seletores (colapsÃ¡vel)
                        if (!_selectorsCollapsed)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OverlayCameraSelectorPanel(
                                  sections: _selectorSections,
                                  onSelectSubjectContext: _selectSubjectContext,
                                  onSelectTargetItem: _selectTargetItem,
                                  onDuplicateTargetItem: _duplicateTargetItem,
                                  onSelectTargetQualifier:
                                      _selectTargetQualifier,
                                  onSelectMaterial: _selectMaterial,
                                  onSelectTargetCondition:
                                      _selectTargetCondition,
                                  onVoiceSelection: ({
                                    required String title,
                                    required List<String> values,
                                    required String? selected,
                                    required Future<void> Function(String value)
                                    onSelect,
                                  }) {
                                    return _selectFromVoiceSheet(
                                      title: title,
                                      values: values,
                                      selected: selected,
                                      onSelect: onSelect,
                                    );
                                  },
                                ),
                                if (presentation.showContextSuggestion) ...[
                                  const SizedBox(height: 8),
                                  OverlayCameraHintCard(
                                    text: _contextSuggestionSummary!,
                                  ),
                                ],
                                if (presentation.showRecentAmbientes) ...[
                                  const SizedBox(height: 8),
                                  OverlayCameraQuickSuggestionCard(
                                    title: 'Locais mais usados nesta Ã¡rea',
                                    values: _recentAmbientes,
                                    selected: _targetItem,
                                    onSelect: (value) => _selectTargetItem(value),
                                  ),
                                ],
                                if (presentation.showPredictionSuggestion) ...[
                                  const SizedBox(height: 8),
                                  OverlayCameraHintCard(
                                    text: _predictionSummary!,
                                  ),
                                ],
                                if (presentation.showRecentElementos) ...[
                                  const SizedBox(height: 8),
                                  OverlayCameraQuickSuggestionCard(
                                    title: 'Mais usados neste contexto',
                                    values: _recentElementos,
                                    selected: _targetQualifier,
                                    onSelect: (value) =>
                                        _selectTargetQualifier(value),
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
                        presentation.batchSummary,
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
                ),
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
