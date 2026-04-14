// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import '../models/flow_selection.dart';
import '../models/inspection_review_editor_models.dart';
import '../models/inspection_review_models.dart';
import '../models/inspection_review_operational_models.dart';
import '../models/overlay_camera_capture_result.dart';
import '../state/app_state.dart';
import '../models/technical_check_requirement_input.dart';
import '../models/technical_evidence_input.dart';
import '../models/technical_rule_result.dart';
import '../services/inspection_technical_summary_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../widgets/review/inspection_review_support_widgets.dart';
import '../widgets/review/inspection_review_section_widgets.dart';
import '../widgets/review/inspection_review_technical_widgets_i18n.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_camera_entry_policy_service.dart';
import '../services/inspection_capture_recovery_adapter.dart';
import '../services/inspection_finalize_use_case.dart';
import '../services/inspection_menu_service.dart';
import '../services/inspection_review_accordion_service.dart';
import '../services/inspection_review_presentation_service.dart';
import '../services/inspection_review_operational_service.dart';
import '../services/inspection_review_technical_presentation_service.dart';
import '../services/inspection_requirement_policy_service.dart';
import '../services/inspection_recovery_stage_service.dart';
import '../services/inspection_review_camera_use_case.dart';
import '../services/inspection_review_export_payload_service.dart';
import '../services/inspection_runtime_context_service.dart';
import '../services/inspection_review_state_service.dart';
import '../services/inspection_review_requirement_service.dart';
import '../services/inspection_semantic_field_service.dart';
import '../services/inspection_domain_adapter.dart';
import '../services/voice_input_service.dart';
import '../models/inspection_technical_summary.dart';
import '../l10n/app_strings.dart';

class InspectionReviewScreen extends StatefulWidget {
  final List<OverlayCameraCaptureResult> captures;
  final String tipoImovel;
  final bool cameFromCheckinStep1;
  final InspectionFlowCoordinator flowCoordinator;

  const InspectionReviewScreen({
    super.key,
    this.captures = const <OverlayCameraCaptureResult>[],
    this.tipoImovel = 'Urbano',
    this.cameFromCheckinStep1 = false,
    this.flowCoordinator = const DefaultInspectionFlowCoordinator(),
  });

  String get assetType => tipoImovel;

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

class _InspectionReviewScreenState extends State<InspectionReviewScreen> {
  late final List<InspectionReviewEditableCapture> _items;
  late List<OverlayCameraCaptureResult> _capturesCurrent;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _technicalJustificationController =
      TextEditingController();
  final FocusNode _technicalJustificationFocusNode = FocusNode();
  final InspectionTechnicalSummaryService _technicalSummaryService =
      const InspectionTechnicalSummaryService();
  final VoiceInputService _voiceService = VoiceInputService();
  final InspectionFinalizeUseCase _finalizeUseCase =
      InspectionFinalizeUseCase.instance;
  final CheckinDynamicConfigService _dynamicConfigService =
      CheckinDynamicConfigService.instance;
  final InspectionCameraEntryPolicyService _cameraEntryPolicy =
      InspectionCameraEntryPolicyService.instance;
  final InspectionMenuService _menuService = InspectionMenuService.instance;
  final InspectionCaptureRecoveryAdapter _captureRecoveryAdapter =
      InspectionCaptureRecoveryAdapter.instance;
  final InspectionRequirementPolicyService _requirementPolicy =
      InspectionRequirementPolicyService.instance;
  final InspectionReviewAccordionService _reviewAccordionService =
      InspectionReviewAccordionService.instance;
  final InspectionReviewPresentationService _reviewPresentationService =
      InspectionReviewPresentationService.instance;
  final InspectionReviewOperationalService _reviewOperationalService =
      InspectionReviewOperationalService.instance;
  final InspectionReviewTechnicalPresentationService
  _reviewTechnicalPresentationService =
      InspectionReviewTechnicalPresentationService.instance;
  final InspectionReviewRequirementService _reviewRequirementService =
      InspectionReviewRequirementService.instance;
  final InspectionRecoveryStageService _recoveryStageService =
      InspectionRecoveryStageService.instance;
  final InspectionReviewCameraUseCase _reviewCameraUseCase =
      InspectionReviewCameraUseCase.instance;
  final InspectionReviewStateService _reviewStateService =
      InspectionReviewStateService.instance;
  final InspectionReviewExportPayloadService _reviewExportPayloadService =
      InspectionReviewExportPayloadService.instance;
  final InspectionRuntimeContextService _runtimeContextService =
      InspectionRuntimeContextService.instance;
  final InspectionSemanticFieldService _semanticFieldService =
      InspectionSemanticFieldService.instance;
  static const InspectionDomainAdapter _domainAdapter =
      InspectionDomainAdapter.instance;

  final GlobalKey _checkinPendingSectionKey = GlobalKey();
  final GlobalKey _capturedPhotosSectionKey = GlobalKey();
  final GlobalKey _closingSectionKey = GlobalKey();

  String? _expandedSubtype;
  bool _technicalPendingSectionExpanded = false;
  bool _reviewSectionExpanded = false;
  bool _closingSectionExpanded = false;
  bool _checkinAccordionExpanded = false;
  bool _capturedAccordionExpanded = false;
  bool _technicalCheckinExpanded = false;
  bool _technicalCaptureExpanded = false;
  bool _technicalReviewExpanded = false;
  bool _technicalFinalizationExpanded = false;
  Map<String, String> _reviewLevelLabels = const <String, String>{};

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final resolvedCaptures = _captureRecoveryAdapter.resolveReviewCaptures(
      currentCaptures: widget.captures,
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
    );
    _capturesCurrent = List.of(resolvedCaptures);
    _items =
        resolvedCaptures
            .map(InspectionReviewEditableCapture.fromCapture)
            .toList();
    _hydrateReviewedItemsFromRecovery();
    _capturedAccordionExpanded = _items.any(
      (item) => (item.ambienteInstanceIndex ?? 1) > 1,
    );
    _loadReviewLabels();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _persistReviewState();
    });
  }

  Future<void> _loadReviewLabels() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final levels = await _menuService.getCameraLevels(
      propertyType: _resolvedAssetType().label,
      subtipo: _resolvedAssetSubtype(appState),
    );
    if (!mounted) return;

    setState(() {
      _reviewLevelLabels = _resolveReviewLevelLabels(levels);
    });
  }

  void _hydrateReviewedItemsFromRecovery() {
    final appState = Provider.of<AppState>(context, listen: false);
    final savedReview = appState.inspectionRecoveryPayload['review'];
    if (savedReview is! Map) return;

    final reviewedRaw = savedReview['capturesRevisadas'];
    if (reviewedRaw is! List) return;

    final reviewedByPath = <String, Map<String, dynamic>>{};
    for (final raw in reviewedRaw) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(
        raw.map((key, value) => MapEntry('$key', value)),
      );
      final filePath = '${map['filePath'] ?? ''}'.trim();
      if (filePath.isEmpty) continue;
      reviewedByPath[filePath] = map;
    }

    if (reviewedByPath.isEmpty) return;

    for (final item in _items) {
      final reviewed = reviewedByPath[item.filePath];
      if (reviewed == null) continue;

      final restored = FlowSelection.fromMap(reviewed);
      item.applySelection(
        item.selection.copyWith(
          subjectContext: restored.subjectContext,
          targetItem: restored.targetItem,
          targetItemBase: restored.targetItemBase,
          targetItemInstanceIndex: restored.targetItemInstanceIndex,
          targetQualifier: restored.targetQualifier,
          targetCondition: restored.targetCondition,
          domainAttributes: restored.domainAttributes.isEmpty
              ? null
              : restored.domainAttributes,
        ),
      );

      final isComplete = reviewed['isComplete'] == true;
      item.recalculateStatus(forceClassified: isComplete);
    }
  }

  Future<void> _persistReviewState() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final jobId = appState.jobAtual?.id;
    if (jobId == null) return;
    final step2Payload = _buildStep2PayloadFromCaptures(appState.step2Payload);
    final existingReviewPayload =
        appState.inspectionRecoveryPayload['review'] as Map?;
    final reviewPayload = _captureRecoveryAdapter.buildReviewPayload(
      tipoImovel: widget.assetType,
      currentCaptures: _capturesCurrent,
      reviewedCaptures: _serializeReviewedCaptures(),
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      existingReviewPayload:
          existingReviewPayload?.map(
            (key, value) => MapEntry('$key', value),
          ),
    );

    await appState.setInspectionRecoverySnapshot(
      _recoveryStageService.review(
        jobId: jobId,
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
        step1Payload: appState.step1Payload,
        step2Payload: step2Payload,
        reviewPayload: reviewPayload,
      ),
    );
  }

  List<Map<String, dynamic>> _serializeReviewedCaptures() {
    return _items
        .map(
          (item) => {
            'filePath': item.filePath,
            ...item.selection.toMap(includeCanonical: true, includeLegacy: true),
            'isComplete':
                item.status == InspectionReviewPhotoStatus.classified,
          },
        )
        .toList();
  }

  void _syncCapturesFromItems(
    Iterable<InspectionReviewEditableCapture> items, {
    bool classificationConfirmed = false,
  }) {
    _reviewStateService.syncCapturesFromItems(
      captures: _capturesCurrent,
      items: items,
      classificationConfirmed: classificationConfirmed,
    );
  }

  void _rebuildCapturesFromItems(
    Iterable<InspectionReviewEditableCapture> items,
  ) {
    _capturesCurrent = _reviewStateService.rebuildCapturesFromItems(
      captures: _capturesCurrent,
      items: items,
    );
  }

  Map<String, dynamic> _buildStep2PayloadFromCaptures(
    Map<String, dynamic> existingStep2Payload,
  ) {
    final appState = Provider.of<AppState>(context, listen: false);
    final tipo = _resolvedTipoImovel();
    var model = _dynamicConfigService.restoreStep2Model(
      tipo: tipo,
      step2Payload: existingStep2Payload,
    );
    final config = _resolveStep2ConfigForTipo(tipo, appState);

    for (final campo in config.photoFields) {
      if (model.isPhotoCaptured(campo.id)) continue;

      final matchedCapture = _requirementPolicy.findMatchingCapture(
        captures: _capturesCurrent,
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

  CheckinStep2Config _resolveStep2ConfigForTipo(
    TipoImovel tipo,
    AppState appState,
  ) {
    return _dynamicConfigService.resolveStoredStep2Config(
      tipo: tipo,
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
    );
  }

  TipoImovel _resolvedAssetType() {
    return _runtimeContextService.resolveAssetType(widget.assetType);
  }

  TipoImovel _resolvedTipoImovel() => _resolvedAssetType();

  String? _resolvedAssetSubtype(AppState appState) {
    return _runtimeContextService.resolveAssetSubtype(
      appState: appState,
      fallbackAssetType: _resolvedAssetType().label,
    );
  }

  String? _resolvedSubtipoImovel(AppState appState) =>
      _resolvedAssetSubtype(appState);

  Map<String, String> _resolveReviewLevelLabels(
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
        surface: InspectionSurfaceKeys.review,
      );
    }
    return labels;
  }

  String _labelForReviewField(String levelId) {
    final strings = AppStrings.of(context);
    final configured = _reviewLevelLabels[levelId]?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    switch (levelId) {
      case 'ambiente':
        return strings.subtypeTargetItem;
      case 'elemento':
        return strings.targetQualifier;
      case 'material':
        return strings.material;
      case 'estado':
        return strings.conditionState;
    }
    return levelId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _technicalJustificationController.dispose();
    _technicalJustificationFocusNode.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final checkinStatuses = _buildCheckinRequirements();
    final technicalSummary = _technicalSummaryService.build(
      tipoImovel: _resolvedTipoImovel().label,
      evidences: _buildTechnicalEvidenceInputs(),
      requirements: _buildTechnicalRequirementInputs(checkinStatuses),
      coverageRequirements: _buildTechnicalCoverageRequirements(),
    );
    final photoCountPolicyPending = _buildPhotoCountPolicyPending();
    final justificationMissing =
        technicalSummary.requiresJustification &&
        _technicalJustificationController.text.trim().isEmpty;
    final summary = _buildSummary(checkinStatuses);
    final operationalData = _reviewOperationalService.build(
      items: _items,
      checkinStatuses: checkinStatuses,
      technicalSummary: technicalSummary,
      justificationMissing: justificationMissing,
      photoCountPolicyPending: photoCountPolicyPending,
    );

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: Text(strings.finalInspectionReview)),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (operationalData.footerBlockingMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    operationalData.footerBlockingMessage!,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: operationalData.canFinalize
                      ? () => _finishInspection(context, 0)
                      : null,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text(
                    'Finalizar vistoria',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Text(
              operationalData.header.supportText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildCompositionCard(operationalData),
            const SizedBox(height: 12),
            _buildEvidenceCard(operationalData),
            const SizedBox(height: 12),
            _buildPendingCard(
              operationalData: operationalData,
            ),
            const SizedBox(height: 12),
            _buildFinalizationCard(
              context,
              summary,
              technicalSummary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionAccordion({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onExpansionChanged,
    required Widget child,
  }) {
    return InspectionReviewSectionAccordion(
      title: title,
      expanded: expanded,
      onExpansionChanged: onExpansionChanged,
      child: child,
    );
  }

  Widget _buildCompositionCard(InspectionReviewOperationalData operationalData) {
    return InspectionReviewCompositionCard(
      operationalData: operationalData,
      onEditComposition: _openCompositionEditor,
    );
  }

  Widget _buildEvidenceCard(InspectionReviewOperationalData operationalData) {
    return InspectionReviewEvidenceCard(
      operationalData: operationalData,
    );
  }

  Widget _buildPendingCard({
    required InspectionReviewOperationalData operationalData,
  }) {
    return InspectionReviewPendingCard(
      operationalData: operationalData,
      onPendingPressed: _handleOperationalPending,
    );
  }

  Widget _buildFinalizationCard(
    BuildContext context,
    InspectionReviewSummaryData summary,
    InspectionTechnicalSummary technicalSummary,
  ) {
    return InspectionReviewBlock(
      title: 'Fechamento técnico',
      child: _buildClosingCard(context, summary, technicalSummary),
    );
  }

  Widget _buildPendingSourceBadge(InspectionReviewPendingSource source) {
    final (label, backgroundColor, foregroundColor) =
        _pendingSourcePresentation(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }

  (String, Color, Color) _pendingSourcePresentation(
    InspectionReviewPendingSource source,
  ) {
    return switch (source) {
      InspectionReviewPendingSource.normativeMatrix => (
        'Etapa 2',
        Colors.blue.withValues(alpha: 0.12),
        Colors.blue.shade900,
      ),
      InspectionReviewPendingSource.captureTree => (
        'Captura',
        Colors.deepOrange.withValues(alpha: 0.12),
        Colors.deepOrange.shade900,
      ),
      InspectionReviewPendingSource.technicalRule => (
        'Regra t\u00e9cnica',
        Colors.purple.withValues(alpha: 0.12),
        Colors.purple.shade900,
      ),
      InspectionReviewPendingSource.finalization => (
        'Encerramento',
        Colors.brown.withValues(alpha: 0.12),
        Colors.brown.shade900,
      ),
    };
  }

  Future<void> _handleOperationalPending(
    InspectionReviewPendingEntry entry,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    switch (entry.target) {
      case InspectionReviewPendingActionTarget.capture:
        final requirement = _buildCheckinRequirements().cast<
          InspectionReviewRequirementStatus?
        >().firstWhere(
          (item) =>
              item != null &&
              item.field.evidenceContext == entry.subjectContext &&
              item.field.evidenceTargetItem == entry.targetItem &&
              item.field.evidenceTargetQualifier == entry.targetQualifier &&
              !item.isDone,
          orElse: () => null,
        );
        if (requirement != null) {
          await _captureMissingRequirement(requirement);
          return;
        }
        if (entry.technicalRule != null) {
          await _handlePendingShortcut(entry.technicalRule!);
          return;
        }
        await _openGenericPendingCapture(
          title: entry.title,
          initialSelection: FlowSelection(
            subjectContext:
                entry.subjectContext ??
                _cameraEntryPolicy
                    .resolveFallbackSelection(
                      step1Payload: appState.step1Payload,
                      inspectionRecoveryPayload:
                          appState.inspectionRecoveryPayload,
                    )
                    .subjectContext,
            targetItem: entry.targetItem,
            targetQualifier: entry.targetQualifier,
          ),
        );
        return;
      case InspectionReviewPendingActionTarget.fill:
      case InspectionReviewPendingActionTarget.editComposition:
        await _openCompositionEditor(focusFilePath: entry.filePath);
        return;
      case InspectionReviewPendingActionTarget.finalization:
        setState(() {
          _technicalPendingSectionExpanded = true;
          _closingSectionExpanded = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await _scrollToSection(_closingSectionKey);
        _technicalJustificationFocusNode.requestFocus();
        return;
    }
  }

  Widget _buildTechnicalPendingAccordionsSection({
    required BuildContext context,
    required InspectionTechnicalSummary technicalSummary,
    required List<InspectionReviewRequirementStatus> checkinStatuses,
  }) {
    final matrix = technicalSummary.pendingMatrix;
    if (!matrix.hasAny) {
      return const SizedBox.shrink();
    }

    final checkinTotal = checkinStatuses.length;
    final checkinDone = checkinStatuses.where((status) => status.isDone).length;

    final captureTotal = checkinTotal;
    final captureDone = checkinDone;

    final reviewTotal = _items.length;
    final reviewDone =
        _items
            .where(
              (item) =>
                  item.status == InspectionReviewPhotoStatus.classified,
            )
            .length;

    final finalizationTotal = matrix.finalization.isEmpty ? 1 : matrix.finalization.length;
    final finalizationDone = matrix.finalization.isEmpty ? 1 : 0;

    return InspectionTechnicalPendingAccordionsSection(
      technicalCheckinExpanded: _technicalCheckinExpanded,
      technicalCaptureExpanded: _technicalCaptureExpanded,
      technicalReviewExpanded: _technicalReviewExpanded,
      technicalFinalizationExpanded: _technicalFinalizationExpanded,
      checkinDone: checkinDone,
      checkinTotal: checkinTotal,
      captureDone: captureDone,
      captureTotal: captureTotal,
      reviewDone: reviewDone,
      reviewTotal: reviewTotal,
      finalizationDone: finalizationDone,
      finalizationTotal: finalizationTotal,
      checkinItems: matrix.checkin,
      captureItems: matrix.capture,
      reviewItems: matrix.review,
      finalizationItems: matrix.finalization,
      onCheckinExpansionChanged:
          (expanded) => setState(() => _technicalCheckinExpanded = expanded),
      onCaptureExpansionChanged:
          (expanded) => setState(() => _technicalCaptureExpanded = expanded),
      onReviewExpansionChanged:
          (expanded) => setState(() => _technicalReviewExpanded = expanded),
      onFinalizationExpansionChanged:
          (expanded) => setState(() => _technicalFinalizationExpanded = expanded),
      describeItem: _friendlyDescription,
      onPendingPressed: (item) => _handlePendingShortcut(item),
    );
  }

  String _friendlyDescription(TechnicalRuleResult item) {
    return _reviewTechnicalPresentationService.friendlyDescription(item);
  }

  List<TechnicalEvidenceInput> _buildTechnicalEvidenceInputs() {
    return _items
        .map(
          (item) => TechnicalEvidenceInput(
            subtipo: item.ambiente,
            elemento: item.elemento,
            material: item.material,
            estado: item.estado,
            observacao: null,
            filePath: item.filePath,
            applicableClassificationLevels: item.applicableClassificationLevels,
          ),
        )
        .toList();
  }

  List<InspectionNormativeRequirementInput> _buildTechnicalRequirementInputs(
    List<InspectionReviewRequirementStatus> statuses,
  ) {
    return statuses
        .map(
          (item) => InspectionNormativeRequirementInput(
            title: item.field.titulo,
            fulfilled: item.isDone,
            blockingOnFinish: true,
            blockingOnCapture: false,
          ),
        )
        .toList();
  }

  List<InspectionCaptureCoverageRequirementInput>
      _buildTechnicalCoverageRequirements() {
    final appState = Provider.of<AppState>(context, listen: false);
    final config = _resolveStep2ConfigForTipo(_resolvedTipoImovel(), appState);
    if (!_shouldEnforceStep2Requirements(config)) {
      return const <InspectionCaptureCoverageRequirementInput>[];
    }

    return config.photoFields
        .where((field) => field.obrigatorio)
        .map(
          (field) => InspectionCaptureCoverageRequirementInput(
            title: field.titulo,
            subtipo: field.evidenceTargetItem,
            elemento: field.evidenceTargetQualifier,
          ),
        )
        .toList();
  }

  Future<void> _handlePendingShortcut(TechnicalRuleResult item) async {
    final shortcut = _reviewPresentationService.buildPendingShortcut(
      stage: item.stage.name,
      subtipo: item.subtipo,
    );

    setState(() {
      _technicalPendingSectionExpanded =
          shortcut.expandTechnicalPending || _technicalPendingSectionExpanded;
      _reviewSectionExpanded = shortcut.expandReview || _reviewSectionExpanded;
      _checkinAccordionExpanded =
          shortcut.expandCheckinAccordion || _checkinAccordionExpanded;
      _capturedAccordionExpanded =
          shortcut.expandCapturedAccordion || _capturedAccordionExpanded;
      _closingSectionExpanded =
          shortcut.expandClosing || _closingSectionExpanded;
      if (shortcut.expandedSubtype != null) {
        _expandedSubtype = shortcut.expandedSubtype;
      }
    });

    if (shortcut.scrollDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: shortcut.scrollDelayMs));
    }

    switch (shortcut.target) {
      case InspectionReviewShortcutTargetData.checkinPending:
        await _scrollToSection(_checkinPendingSectionKey);
        break;
      case InspectionReviewShortcutTargetData.capturedPhotos:
        await _scrollToSection(_capturedPhotosSectionKey);
        break;
      case InspectionReviewShortcutTargetData.closing:
        await _scrollToSection(_closingSectionKey);
        break;
    }

    if (!mounted) return;
    if (shortcut.snackbarMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shortcut.snackbarMessage),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
  }

  Widget _buildReviewAccordionsSection({
    required BuildContext context,
    required List<InspectionReviewRequirementStatus> checkinStatuses,
  }) {
    final groupedRequirements = _groupCheckinRequirements(checkinStatuses);
    final accordionData = _reviewAccordionService.build(
      items:
          _items
              .map(
                (item) => InspectionReviewCaptureItemData(
                  filePath: item.filePath,
                  ambiente: item.ambiente,
                  elemento: item.elemento,
                  status: switch (item.status) {
                    InspectionReviewPhotoStatus.pending =>
                      InspectionReviewCaptureStatusData.pending,
                    InspectionReviewPhotoStatus.suggested =>
                      InspectionReviewCaptureStatusData.suggested,
                    InspectionReviewPhotoStatus.classified =>
                      InspectionReviewCaptureStatusData.classified,
                  },
                ),
              )
              .toList(),
      checkinStatuses:
          checkinStatuses
              .map(
                (status) => InspectionReviewRequirementStatusData(
                  field: status.field,
                  isDone: status.isDone,
                ),
              )
              .toList(),
      groupedRequirements:
          groupedRequirements
              .map(
                (group) => InspectionReviewRequirementGroupData(
                  title: group.title,
                  icon: group.icon,
                  doneCount: group.doneCount,
                  totalCount: group.totalCount,
                  pendingStatus:
                      group.pendingStatus == null
                          ? null
                          : InspectionReviewRequirementStatusData(
                            field: group.pendingStatus!.field,
                            isDone: group.pendingStatus!.isDone,
                          ),
                  statuses:
                      group.statuses
                          .map(
                            (status) => InspectionReviewRequirementStatusData(
                              field: status.field,
                              isDone: status.isDone,
                            ),
                          )
                          .toList(),
                ),
              )
              .toList(),
      normalizeComparableText: _requirementPolicy.normalizeComparableText,
    );
    final mandatoryGroups = _buildGroupsForItems(
      _items
          .where(
            (item) => accordionData.mandatoryCapturedPaths.contains(item.filePath),
          )
          .toList(),
    );
    final visibleGroupedRequirements =
        groupedRequirements.where((group) {
          return accordionData.visibleRequirementGroups.any(
            (visible) =>
                visible.title == group.title &&
                visible.doneCount == group.doneCount &&
                visible.totalCount == group.totalCount,
          );
        }).toList();
    final capturedGroups = _buildGroupsForItems(
      _items
          .where(
            (item) => !accordionData.mandatoryCapturedPaths.contains(item.filePath),
          )
          .toList(),
    );
    final mandatorySection = _reviewPresentationService.buildMandatorySection(
      checkinPendencias: accordionData.checkinPendencias,
      requiredDone: accordionData.requiredDone,
      requiredTotal: accordionData.requiredTotal,
      hasCheckinPending: accordionData.hasCheckinPending,
    );
    final capturedSection = _reviewPresentationService.buildCapturedSection(
      capturedPendencias: accordionData.capturedPendencias,
      capturedClassified: accordionData.capturedClassified,
      capturedTotal: accordionData.capturedTotal,
      hasCapturedPending: accordionData.hasCapturedPending,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewAccordion(
          key: _checkinPendingSectionKey,
          title: 'Fotos Obrigat\u00F3rias do Check-In',
          isOk: mandatorySection.isOk,
          subtitle: mandatorySection.subtitle,
          expanded: _checkinAccordionExpanded,
          onExpansionChanged:
              (expanded) =>
                  setState(() => _checkinAccordionExpanded = expanded),
          child: InspectionReviewMandatoryAccordionContent(
            mandatoryGroups: mandatoryGroups,
            visibleGroupedRequirements: visibleGroupedRequirements,
            expandedSubtype: _expandedSubtype,
            onExpandedSubtypeChanged: (value) {
              setState(() {
                _expandedSubtype = value;
              });
            },
            onChanged: () => setState(() {}),
            onApplySubtype: _applySubtype,
            onApplySimilar: _applySimilar,
            onAcceptSuggestions: _acceptSuggestions,
            onEditItem: _editItem,
            onCaptureMissingRequirement: _captureMissingRequirement,
          ),
        ),
        const SizedBox(height: 12),
        _buildReviewAccordion(
          key: _capturedPhotosSectionKey,
          title: 'Fotos Capturadas',
          isOk: capturedSection.isOk,
          subtitle: capturedSection.subtitle,
          expanded: _capturedAccordionExpanded,
          onExpansionChanged:
              (expanded) =>
                  setState(() => _capturedAccordionExpanded = expanded),
          child: InspectionReviewCapturedAccordionContent(
            capturedGroups: capturedGroups,
            expandedSubtype: _expandedSubtype,
            onExpandedSubtypeChanged: (value) {
              setState(() {
                _expandedSubtype = value;
              });
            },
            onChanged: () => setState(() {}),
            onApplySubtype: _applySubtype,
            onApplySimilar: _applySimilar,
            onAcceptSuggestions: _acceptSuggestions,
            onEditItem: _editItem,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewAccordion({
    required GlobalKey key,
    required String title,
    required bool isOk,
    required String subtitle,
    required bool expanded,
    required ValueChanged<bool> onExpansionChanged,
    required Widget child,
  }) {
    return InspectionReviewAccordion(
      keyValue: key,
      title: title,
      isOk: isOk,
      subtitle: subtitle,
      expanded: expanded,
      onExpansionChanged: onExpansionChanged,
      child: child,
    );
  }

  Widget _buildClosingCard(
    BuildContext context,
    InspectionReviewSummaryData summary,
    InspectionTechnicalSummary technicalSummary,
  ) {
    final annotationRequired = technicalSummary.requiresJustification;
    final annotationDone =
        !annotationRequired || _technicalJustificationController.text.trim().isNotEmpty;
    final appState = Provider.of<AppState>(context, listen: false);
    final config = _resolveStep2ConfigForTipo(
      _resolvedTipoImovel(),
      appState,
    );
    final photoPolicyMessage = summary.photoCountPolicyPending > 0
        ? _reviewTechnicalPresentationService.photoCountPolicyMessage(
            config: config,
            totalCaptures: _capturesCurrent.length,
          )
        : null;
    final blockingMessage = _reviewTechnicalPresentationService
        .closingBlockingMessage(
          technicalSummary: technicalSummary,
          justificationText: _technicalJustificationController.text,
        );
    return InspectionReviewClosingCard(
      sectionKey: _closingSectionKey,
      annotationRequired: annotationRequired,
      annotationDone: annotationDone,
      technicalJustificationController: _technicalJustificationController,
      technicalJustificationFocusNode: _technicalJustificationFocusNode,
      voiceService: _voiceService,
      onTechnicalJustificationChanged: (_) => setState(() {}),
      noteController: _noteController,
      onObservationChanged: (_) => setState(() {}),
      totalPending: summary.totalPending,
      photoPolicyMessage: photoPolicyMessage,
      blockingMessage: blockingMessage,
    );
  }

  Widget _buildClosingAccordion({
    required String title,
    required bool expanded,
    required bool isDone,
    required ValueChanged<bool> onExpansionChanged,
    required Widget child,
  }) {
    return InspectionReviewClosingAccordion(
      title: title,
      expanded: expanded,
      isDone: isDone,
      onExpansionChanged: onExpansionChanged,
      child: child,
    );
  }

  InspectionReviewSummaryData _buildSummary(
    List<InspectionReviewRequirementStatus> checkinStatuses,
  ) {
    return _reviewPresentationService.buildSummary(
      itemStatuses:
          _items
              .map(
                (item) => switch (item.status) {
                  InspectionReviewPhotoStatus.pending =>
                    InspectionReviewItemStatusData.pending,
                  InspectionReviewPhotoStatus.suggested =>
                    InspectionReviewItemStatusData.suggested,
                  InspectionReviewPhotoStatus.classified =>
                    InspectionReviewItemStatusData.classified,
                },
              )
              .toList(),
      missingCheckin: checkinStatuses.where((item) => !item.isDone).length,
      photoCountPolicyPending: _buildPhotoCountPolicyPending(),
    );
  }

  int _buildPhotoCountPolicyPending() {
    final appState = Provider.of<AppState>(context, listen: false);
    final tipo = _resolvedTipoImovel();
    final config = _resolveStep2ConfigForTipo(tipo, appState);
    if (!_shouldEnforceStep2Requirements(config)) {
      return 0;
    }
    final persistedModel = _dynamicConfigService.restoreStep2Model(
      tipo: tipo,
      step2Payload: appState.step2Payload,
    );
    final mandatoryStatuses = _requirementPolicy.evaluateMandatoryFieldStatuses(
      fields: config.photoFields,
      persistedModel: persistedModel,
      captures: _capturesCurrent,
    );

    final requiredCount = mandatoryStatuses.length;
    if (requiredCount == 0) {
      return 0;
    }

    final doneCount = mandatoryStatuses.where((status) => status.isDone).length;
    final missingCount = requiredCount - doneCount;
    return missingCount > 0 ? missingCount : 0;
  }

  List<InspectionReviewNodeGroup> _buildGroupsForItems(
    List<InspectionReviewEditableCapture> sourceItems,
  ) {
    final grouped = _reviewPresentationService.buildGroups(
      sourceItems
          .map(
            (item) => InspectionReviewGroupingItemData(
              ambiente: item.ambiente,
              status: switch (item.status) {
                InspectionReviewPhotoStatus.pending =>
                  InspectionReviewItemStatusData.pending,
                InspectionReviewPhotoStatus.suggested =>
                  InspectionReviewItemStatusData.suggested,
                InspectionReviewPhotoStatus.classified =>
                  InspectionReviewItemStatusData.classified,
              },
            ),
          )
          .toList(),
    );

    return grouped.map((group) {
      final items =
          sourceItems.where((item) {
            final ambiente =
                item.ambiente.trim().isEmpty ? 'Sem subtipo' : item.ambiente;
            return ambiente == group.title;
          }).toList();
      return InspectionReviewNodeGroup(
        title: group.title,
        items: items,
        pending: group.pending,
        suggested: group.suggested,
        classified: group.classified,
      );
    }).toList();
  }

  List<InspectionReviewRequirementStatus> _buildCheckinRequirements() {
    final appState = Provider.of<AppState>(context, listen: false);
    final tipo = _resolvedTipoImovel();
    final persistedStep2Model = _dynamicConfigService.restoreStep2Model(
      tipo: tipo,
      step2Payload: appState.step2Payload,
    );

    final config = _resolveStep2ConfigForTipo(tipo, appState);
    if (!_shouldEnforceStep2Requirements(config)) {
      return const <InspectionReviewRequirementStatus>[];
    }

    return _reviewRequirementService
        .buildStatuses(
          fields: config.photoFields,
          captures: _capturesCurrent,
          persistedModel: persistedStep2Model,
        )
        .map(
          (status) => InspectionReviewRequirementStatus(
            field: status.field,
            isDone: status.isDone,
          ),
        )
        .toList();
  }

  bool _shouldEnforceStep2Requirements(CheckinStep2Config config) {
    if (!config.visivelNoFluxo) {
      return false;
    }
    if (!(config.obrigatoriaNoFluxo || config.obrigatoriaParaEntrega)) {
      return false;
    }
    return true;
  }

  List<InspectionReviewRequirementGroupStatus> _groupCheckinRequirements(
    List<InspectionReviewRequirementStatus> statuses,
  ) {
    return _reviewRequirementService
        .groupStatuses(
          statuses
              .map(
                (status) => InspectionReviewRequirementStatusData(
                  field: status.field,
                  isDone: status.isDone,
                ),
              )
              .toList(),
        )
        .map(
          (group) => InspectionReviewRequirementGroupStatus(
            title: group.title,
            icon: group.icon,
            doneCount: group.doneCount,
            totalCount: group.totalCount,
            pendingStatus:
                group.pendingStatus == null
                    ? null
                    : InspectionReviewRequirementStatus(
                      field: group.pendingStatus!.field,
                      isDone: group.pendingStatus!.isDone,
                    ),
            statuses:
                group.statuses
                    .map(
                      (status) => InspectionReviewRequirementStatus(
                        field: status.field,
                        isDone: status.isDone,
                      ),
                    )
                    .toList(),
          ),
        )
        .toList();
  }

  String _normalizeComparableText(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) return '';
    return text
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â£', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©', 'e')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âª', 'e')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­', 'i')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â³', 'o')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â´', 'o')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âµ', 'o')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº', 'u')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§', 'c')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢', '');
  }

  Future<void> _captureMissingRequirement(
    InspectionReviewRequirementStatus status,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final result = await _reviewCameraUseCase.captureRequirement(
      context,
      flowCoordinator: widget.flowCoordinator,
      appState: appState,
      tipoImovel: widget.assetType,
      subtipoImovel:
          _resolvedSubtipoImovel(appState) ?? _resolvedTipoImovel().label,
      title: status.field.titulo,
      initialSelection: FlowSelection(
        subjectContext: status.field.evidenceContext,
        targetItem: status.field.evidenceTargetItem,
        targetQualifier: status.field.evidenceTargetQualifier,
      ),
      currentCaptures: _capturesCurrent,
    );
    if (!mounted) return;
    if (result == null) {
      await _persistReviewState();
      return;
    }
    _reviewStateService.appendCapture(
      captures: _capturesCurrent,
      items: _items,
      capture: result,
    );
    setState(() {
    });
    await _persistReviewState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${status.field.titulo} registrado com sucesso.')),
    );
  }

  Future<void> _openGenericPendingCapture({
    required String title,
    FlowSelection? initialSelection,
  }) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final result = await _reviewCameraUseCase.captureGenericPending(
      context,
      flowCoordinator: widget.flowCoordinator,
      appState: appState,
      tipoImovel: _resolvedTipoImovel().label,
      subtipoImovel:
          _resolvedSubtipoImovel(appState) ?? _resolvedTipoImovel().label,
      title: title,
      initialSelection: initialSelection,
      currentCaptures: _capturesCurrent,
    );
    if (!mounted) return;
    if (result == null) {
      await _persistReviewState();
      return;
    }

    _reviewStateService.appendCapture(
      captures: _capturesCurrent,
      items: _items,
      capture: result,
    );
    setState(() {
    });
    await _persistReviewState();
  }

  void _applySubtype(InspectionReviewNodeGroup group) {
    setState(() {
      _reviewStateService.applySubtype(group);
      _syncCapturesFromItems(group.items, classificationConfirmed: true);
    });
    _persistReviewState();
  }

  void _acceptSuggestions(InspectionReviewNodeGroup group) {
    setState(() {
      _reviewStateService.acceptSuggestions(group);
      _syncCapturesFromItems(group.items, classificationConfirmed: true);
    });
    _persistReviewState();
  }

  void _applySimilar(
    InspectionReviewNodeGroup group,
    InspectionReviewEditableCapture source,
  ) {
    setState(() {
      _reviewStateService.applySimilar(group, source);
      _syncCapturesFromItems(group.items, classificationConfirmed: true);
    });
    _persistReviewState();
  }

  Future<void> _editItem(InspectionReviewEditableCapture item) async {
    final edited = await _showClassificationEditor(context: context, item: item);
    if (edited != true || !mounted) {
      return;
    }
    setState(() {
      _rebuildCapturesFromItems(_items);
    });
    await _persistReviewState();
  }

  Future<bool?> _showClassificationEditor({
    required BuildContext context,
    required InspectionReviewEditableCapture item,
  }) async {
    final catalog = await _loadReviewEditorCatalog(item);
    if (!context.mounted) {
      return false;
    }

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (sheetContext) {
        final itemSelection = item.selection;
        String? macroLocal = itemSelection.subjectContext;
        String? elemento = itemSelection.targetQualifier;
        String? material = itemSelection.attributeText('inspection.material');
        String? estado = itemSelection.targetCondition;
        String? ambiente = itemSelection.targetItem;
        var ambientes = List<String>.from(catalog.ambientes);
        var elementos = List<String>.from(catalog.elementos);
        var materiais = List<String>.from(catalog.materiais);
        var estados = List<String>.from(catalog.estados);
        final macroLocais = List<String>.from(catalog.macroLocais);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final mediaQuery = MediaQuery.of(context);
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 4,
                  bottom:
                      mediaQuery.viewInsets.bottom +
                      mediaQuery.viewPadding.bottom +
                      16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classificar evidÃªncia',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ReviewEditorDropdown(
                        label: 'Contexto da captura',
                        value: macroLocais.contains(macroLocal)
                            ? macroLocal
                            : null,
                        items: macroLocais,
                        onChanged: (value) async {
                          macroLocal = value;
                          final refreshed = await _loadReviewEditorCatalog(
                            item.clone()
                              ..macroLocal = macroLocal
                              ..ambiente = ambiente ?? item.ambiente
                              ..elemento = elemento
                              ..material = material
                              ..estado = estado,
                          );
                          setSheetState(() {
                            ambientes = refreshed.ambientes;
                            elementos = refreshed.elementos;
                            materiais = refreshed.materiais;
                            estados = refreshed.estados;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ReviewEditorDropdown(
                        label: _labelForReviewField('ambiente'),
                        value: ambientes.contains(ambiente) ? ambiente : null,
                        items: ambientes,
                        onChanged: (value) async {
                          ambiente = value;
                          final refreshed = await _loadReviewEditorCatalog(
                            item.clone()
                              ..macroLocal = macroLocal
                              ..ambiente = ambiente ?? item.ambiente
                              ..elemento = elemento
                              ..material = material
                              ..estado = estado,
                          );
                          setSheetState(() {
                            elementos = refreshed.elementos;
                            materiais = refreshed.materiais;
                            estados = refreshed.estados;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ReviewEditorDropdown(
                        label: _labelForReviewField('elemento'),
                        value: elementos.contains(elemento) ? elemento : null,
                        items: elementos,
                        onChanged: (value) async {
                          elemento = value;
                          final refreshed = await _loadReviewEditorCatalog(
                            item.clone()
                              ..macroLocal = macroLocal
                              ..ambiente = ambiente ?? item.ambiente
                              ..elemento = elemento
                              ..material = material
                              ..estado = estado,
                          );
                          setSheetState(() {
                            materiais = refreshed.materiais;
                            estados = refreshed.estados;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ReviewEditorDropdown(
                        label: _labelForReviewField('material'),
                        value: materiais.contains(material) ? material : null,
                        items: materiais,
                        onChanged:
                            (value) => setSheetState(() => material = value),
                      ),
                      const SizedBox(height: 10),
                      ReviewEditorDropdown(
                        label: _labelForReviewField('estado'),
                        value: estados.contains(estado) ? estado : null,
                        items: estados,
                        onChanged:
                            (value) => setSheetState(() => estado = value),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            item.applySelection(
                              item.selection.copyWith(
                                subjectContext: macroLocal,
                                targetItem: ambiente,
                                targetQualifier: elemento,
                                targetCondition: estado,
                                domainAttributes: <String, dynamic>{
                                  ...item.selection.domainAttributes,
                                  if (material != null)
                                    'inspection.material': material,
                                  if (material == null)
                                    ...Map.fromEntries(
                                      item.selection.domainAttributes.entries
                                          .where((e) =>
                                              e.key != 'inspection.material'),
                                    ),
                                },
                              ),
                            );
                            item.recalculateStatus();
                            Navigator.of(sheetContext).pop(true);
                          },
                          child: const Text('Salvar classificaÃ§Ã£o'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCompositionEditor({String? focusFilePath}) async {
    final workingItems = _items.map((item) => item.clone()).toList();
    final workingCaptures = List<OverlayCameraCaptureResult>.from(
      _capturesCurrent,
    );
    final result =
        await Navigator.of(context).push<InspectionCompositionEditorResult>(
          MaterialPageRoute<InspectionCompositionEditorResult>(
            fullscreenDialog: true,
            builder: (pageContext) {
              final pageState = InspectionCompositionEditorState(
                items: workingItems,
                captures: workingCaptures,
                focusFilePath: focusFilePath,
              );

              return StatefulBuilder(
                builder: (context, setPageState) {
                  Future<void> editWorkingItem(
                    InspectionReviewEditableCapture item,
                  ) async {
                    final edited = await _showClassificationEditor(
                      context: context,
                      item: item,
                    );
                    if (edited == true) {
                      setPageState(() {});
                    }
                  }

                  Future<void> addItemFromAvailableCapture() async {
                    final usedPaths =
                        pageState.items.map((item) => item.filePath).toSet();
                    final available =
                        pageState.captures
                            .where((capture) => !usedPaths.contains(capture.filePath))
                            .toList();
                    if (available.isNotEmpty) {
                      final selected = available.first;
                      pageState.items.add(
                        InspectionReviewEditableCapture.fromCapture(selected),
                      );
                      setPageState(() {});
                      return;
                    }

                    final appState = Provider.of<AppState>(context, listen: false);
                    final seedSelection =
                        pageState.items.isNotEmpty
                            ? pageState.items.last.selection
                            : _cameraEntryPolicy.resolveFallbackSelection(
                                step1Payload: appState.step1Payload,
                                inspectionRecoveryPayload:
                                    appState.inspectionRecoveryPayload,
                              );
                    final newCapture = await _reviewCameraUseCase.captureEditorAdd(
                      context,
                      flowCoordinator: widget.flowCoordinator,
                      appState: appState,
                      tipoImovel: _resolvedTipoImovel().label,
                      subtipoImovel:
                          _resolvedSubtipoImovel(appState) ??
                          _resolvedTipoImovel().label,
                      seedSelection: seedSelection,
                      currentCaptures: pageState.captures,
                    );
                    if (newCapture == null) {
                      if (context.mounted) {
                        await _persistReviewState();
                      }
                      return;
                    }

                    pageState.captures.add(newCapture);
                    pageState.items.add(
                      InspectionReviewEditableCapture.fromCapture(newCapture),
                    );
                    setPageState(() {});
                  }

                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Editar composição'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(
                            InspectionCompositionEditorResult(
                              items: pageState.items
                                  .map((item) => item.clone())
                                  .toList(growable: false),
                              captures: List<OverlayCameraCaptureResult>.from(
                                pageState.captures,
                              ),
                            ),
                          ),
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                    floatingActionButton: FloatingActionButton.extended(
                      onPressed: addItemFromAvailableCapture,
                      icon: const Icon(Icons.add),
                      label: const Text('Incluir item'),
                    ),
                    body: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        const Text(
                          'Ajuste a composição identificada sem sair da revisão.',
                        ),
                        const SizedBox(height: 12),
                        ...pageState.items.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    item.filePath == pageState.focusFilePath
                                        ? Colors.blue.withValues(alpha: 0.35)
                                        : Colors.blueGrey.withValues(alpha: 0.18),
                              ),
                              color: item.filePath == pageState.focusFilePath
                                  ? Colors.blue.withValues(alpha: 0.05)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ReviewCaptureThumbnail(
                                      filePath: item.filePath,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.ambienteBase?.trim().isNotEmpty == true
                                            ? item.ambienteBase!.trim()
                                            : item.ambiente,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.shortDescription,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Capturada às ',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => editWorkingItem(item),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () {
                                    pageState.items.remove(item);
                                    setPageState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(result.items);
      _capturesCurrent = List<OverlayCameraCaptureResult>.from(result.captures);
      _rebuildCapturesFromItems(_items);
    });
    await _persistReviewState();
  }
  List<String> _mergeCurrentAndCatalogValues({
    required Iterable<String> catalogValues,
    required Iterable<String?> currentValues,
    String? selectedValue,
  }) {
    final merged = <String>[];

    void addValue(String? value) {
      final normalized = value?.trim() ?? '';
      if (normalized.isEmpty) return;
      if (merged.contains(normalized)) return;
      merged.add(normalized);
    }

    for (final value in catalogValues) {
      addValue(value);
    }
    for (final value in currentValues) {
      addValue(value);
    }
    addValue(selectedValue);

    return merged;
  }

  Future<InspectionReviewEditorCatalogData> _loadReviewEditorCatalog(
    InspectionReviewEditableCapture item,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final propertyType = _resolvedTipoImovel().label;
    final subtipo = _resolvedSubtipoImovel(appState);
    final selectedMacroLocal = item.macroLocal?.trim();
    final selectedAmbiente = item.ambiente.trim();
    final selectedElemento = item.elemento?.trim();

    final macroLocaisFromConfig = await _menuService.getMacroLocals(
      propertyType: propertyType,
      subtipo: subtipo,
    );

    final macroLocais = _mergeCurrentAndCatalogValues(
      catalogValues: macroLocaisFromConfig,
      currentValues: _items.map((capture) => capture.macroLocal),
      selectedValue: selectedMacroLocal,
    );

    final ambientesFromConfig =
        selectedMacroLocal == null || selectedMacroLocal.isEmpty
            ? const <String>[]
            : await _menuService.getAmbientes(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: selectedMacroLocal,
              );

    final ambientes = _mergeCurrentAndCatalogValues(
      catalogValues: ambientesFromConfig.isNotEmpty
          ? ambientesFromConfig
          : _domainAdapter.environmentOptions(),
      currentValues: _items.map((capture) => capture.ambiente),
      selectedValue: selectedAmbiente,
    );

    final elementosFromConfig =
        selectedMacroLocal == null ||
                selectedMacroLocal.isEmpty ||
                selectedAmbiente.isEmpty
            ? const <String>[]
            : await _menuService.getElementos(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: selectedMacroLocal,
                ambiente: selectedAmbiente,
              );

    final elementos = _mergeCurrentAndCatalogValues(
      catalogValues: elementosFromConfig.isNotEmpty
          ? elementosFromConfig
          : _domainAdapter.elementOptions(),
      currentValues: _items.map((capture) => capture.elemento),
      selectedValue: selectedElemento,
    );

    final materiaisFromConfig =
        selectedMacroLocal == null ||
                selectedMacroLocal.isEmpty ||
                selectedAmbiente.isEmpty ||
                selectedElemento == null ||
                selectedElemento.isEmpty
            ? const <String>[]
            : await _menuService.getMateriais(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: selectedMacroLocal,
                ambiente: selectedAmbiente,
                elemento: selectedElemento,
              );

    final materiais = _mergeCurrentAndCatalogValues(
      catalogValues: materiaisFromConfig.isNotEmpty
          ? materiaisFromConfig
          : _domainAdapter.materialOptions(),
      currentValues: _items.map((capture) => capture.material),
      selectedValue: item.material,
    );

    final estadosFromConfig =
        selectedMacroLocal == null ||
                selectedMacroLocal.isEmpty ||
                selectedAmbiente.isEmpty ||
                selectedElemento == null ||
                selectedElemento.isEmpty
            ? const <String>[]
            : await _menuService.getEstados(
                propertyType: propertyType,
                subtipo: subtipo,
                macroLocal: selectedMacroLocal,
                ambiente: selectedAmbiente,
                elemento: selectedElemento,
              );

    final estados = _mergeCurrentAndCatalogValues(
      catalogValues: estadosFromConfig.isNotEmpty
          ? estadosFromConfig
          : _domainAdapter.stateOptions(),
      currentValues: _items.map((capture) => capture.estado),
      selectedValue: item.estado,
    );

    return InspectionReviewEditorCatalogData(
      macroLocais: macroLocais,
      ambientes: ambientes,
      elementos: elementos,
      materiais: materiais,
      estados: estados,
    );
  }

  Future<void> _finishInspection(BuildContext context, int pendingCount) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = Provider.of<AppState>(context, listen: false);

    final shouldContinue =
        pendingCount == 0
            ? true
            : await showDialog<bool>(
                  context: context,
                  builder:
                      (dialogContext) => AlertDialog(
                        title: Text(strings.thereArePendingItems),
                        content: Text(
                          strings.pendingItemsDialog(pendingCount),
                        ),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.pop(dialogContext, false),
                            child: Text(strings.back),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: Text(strings.completeAnyway),
                          ),
                        ],
                      ),
                ) ??
                false;

    if (!shouldContinue) return;
    if (!mounted) return;

    final payload = _reviewExportPayloadService.build(
      appState: appState,
      assetType: widget.assetType,
      step2Config: _resolveStep2ConfigForTipo(_resolvedTipoImovel(), appState),
      captures: _capturesCurrent,
      reviewedItems: _items,
      note: _noteController.text,
      technicalJustification: _technicalJustificationController.text,
    );
    final result = await _finalizeUseCase.execute(
      appState: appState,
      payload: payload,
    );

    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
    if (result.shouldExitFlow) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

}





