import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import '../models/flow_selection.dart';
import '../models/inspection_review_models.dart';
import '../models/job_status.dart';
import '../models/overlay_camera_capture_result.dart';
import '../state/app_state.dart';
import '../models/technical_check_requirement_input.dart';
import '../models/technical_evidence_input.dart';
import '../models/technical_rule_result.dart';
import '../services/inspection_technical_summary_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../widgets/inspection_technical_summary_card.dart';
import '../widgets/technical_justification_card.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_export_service.dart';
import '../services/inspection_capture_recovery_adapter.dart';
import '../services/inspection_menu_service.dart';
import '../services/inspection_review_accordion_service.dart';
import '../services/inspection_review_presentation_service.dart';
import '../services/inspection_review_technical_presentation_service.dart';
import '../services/inspection_requirement_policy_service.dart';
import '../services/inspection_review_requirement_service.dart';
import '../services/inspection_semantic_field_service.dart';
import '../services/inspection_sync_queue_service.dart';
import '../services/inspection_sync_service.dart';
import '../services/inspection_domain_adapter.dart';
import '../services/voice_input_service.dart';
import '../widgets/voice_text_field.dart';
import '../models/inspection_technical_summary.dart';

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

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

class _InspectionReviewScreenState extends State<InspectionReviewScreen> {
  late final List<InspectionReviewEditableCapture> _items;
  late List<OverlayCameraCaptureResult> _capturesCurrent;
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _technicalJustificationController =
      TextEditingController();
  final InspectionTechnicalSummaryService _technicalSummaryService =
      const InspectionTechnicalSummaryService();
  final VoiceInputService _voiceService = VoiceInputService();
  final InspectionExportService _exportService = InspectionExportService();
  final InspectionSyncService _syncService = const InspectionSyncService();
  final InspectionSyncQueueService _syncQueueService =
      const InspectionSyncQueueService();
  final CheckinDynamicConfigService _dynamicConfigService =
      CheckinDynamicConfigService.instance;
  final InspectionMenuService _menuService = InspectionMenuService.instance;
  final InspectionCaptureRecoveryAdapter _captureRecoveryAdapter =
      InspectionCaptureRecoveryAdapter.instance;
  final InspectionRequirementPolicyService _requirementPolicy =
      InspectionRequirementPolicyService.instance;
  final InspectionReviewAccordionService _reviewAccordionService =
      InspectionReviewAccordionService.instance;
  final InspectionReviewPresentationService _reviewPresentationService =
      InspectionReviewPresentationService.instance;
  final InspectionReviewTechnicalPresentationService
  _reviewTechnicalPresentationService =
      InspectionReviewTechnicalPresentationService.instance;
  final InspectionReviewRequirementService _reviewRequirementService =
      InspectionReviewRequirementService.instance;
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
  bool _closingNotesExpanded = false;
  bool _closingObservationExpanded = false;
  Map<String, String> _reviewLevelLabels = const <String, String>{};

  @override
  void initState() {
    super.initState();
    _items =
        widget.captures.map(InspectionReviewEditableCapture.fromCapture).toList();
    _hydrateReviewedItemsFromRecovery();
    _capturesCurrent = List.of(widget.captures);
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
      propertyType: _resolvedTipoImovel().label,
      subtipo: _resolvedSubtipoImovel(appState),
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
    final step2Payload = _buildStep2PayloadFromCaptures(appState.step2Payload);
    final existingReviewPayload =
        appState.inspectionRecoveryPayload['review'] as Map?;
    final reviewPayload = _captureRecoveryAdapter.buildReviewPayload(
      tipoImovel: widget.tipoImovel,
      currentCaptures: _capturesCurrent,
      reviewedCaptures: _serializeReviewedCaptures(),
      inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      existingReviewPayload:
          existingReviewPayload?.map(
            (key, value) => MapEntry('$key', value),
          ),
    );

    await appState.setInspectionRecoveryStage(
      stageKey: 'inspection_review',
      stageLabel: 'Revis\u00E3o final',
      routeName: '/inspection_review',
      payload: {
        ...appState.inspectionRecoveryPayload,
        'step1': appState.step1Payload,
        'step2': step2Payload,
        'review': reviewPayload,
      },
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

    for (final campo in config.camposFotos) {
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

  TipoImovel _resolvedTipoImovel() {
    final rawTipo = widget.tipoImovel.split('?').first.trim();
    return TipoImovelExtension.fromString(rawTipo);
  }


  String? _resolvedSubtipoImovel(AppState appState) {
    final direct = appState.step1Payload['subtipoImovel'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final rawStep1 = appState.inspectionRecoveryPayload['step1'];
    if (rawStep1 is Map) {
      final restored = rawStep1['subtipoImovel'];
      if (restored is String && restored.trim().isNotEmpty) {
        return restored.trim();
      }
    }

    return null;
  }

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
    final configured = _reviewLevelLabels[levelId]?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    switch (levelId) {
      case 'ambiente':
        return 'Subtipo / Local';
      case 'elemento':
        return 'Elemento';
      case 'material':
        return 'Material';
      case 'estado':
        return 'Estado';
    }
    return levelId;
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    _technicalJustificationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkinStatuses = _buildCheckinRequirements();
    final summary = _buildSummary(checkinStatuses);
    final technicalSummary = _technicalSummaryService.build(
      tipoImovel: _resolvedTipoImovel().label,
      evidences: _buildTechnicalEvidenceInputs(),
      requirements: _buildTechnicalRequirementInputs(checkinStatuses),
    );

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Menu de Vistoria')),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  technicalSummary.canProceedWith(
                        _technicalJustificationController.text,
                      )
                      ? () => _finishInspection(
                        context,
                        summary.totalPending +
                            technicalSummary.pendingMatrix.totalBlocking,
                      )
                      : null,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text(
                'FINALIZAR VISTORIA',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            InspectionTechnicalSummaryCard(summary: technicalSummary),
            const SizedBox(height: 8),
            _buildSectionAccordion(
              title: 'PEND\u00CANCIAS T\u00C9CNICAS DA VISTORIA',
              expanded: _technicalPendingSectionExpanded,
              onExpansionChanged: (expanded) => setState(
                () => _technicalPendingSectionExpanded = expanded,
              ),
              child: _buildTechnicalPendingAccordionsSection(
                context: context,
                technicalSummary: technicalSummary,
                checkinStatuses: checkinStatuses,
              ),
            ),
            const SizedBox(height: 8),
            _buildSectionAccordion(
              title: 'REVIS\u00C3O DE FOTOS',
              expanded: _reviewSectionExpanded,
              onExpansionChanged:
                  (expanded) => setState(() => _reviewSectionExpanded = expanded),
              child: _buildReviewAccordionsSection(
                context: context,
                checkinStatuses: checkinStatuses,
              ),
            ),
            const SizedBox(height: 8),
            _buildSectionAccordion(
              title: 'ENCERRAMENTO',
              expanded: _closingSectionExpanded,
              onExpansionChanged:
                  (expanded) => setState(() => _closingSectionExpanded = expanded),
              child: _buildClosingCard(context, summary, technicalSummary),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        children: [child],
      ),
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toque em "Ir para pend\u00EAncia" para navegar direto ao ponto de ajuste.',

        ),
        const SizedBox(height: 10),
        _buildTechnicalStageAccordion(
          title: 'Check-In $checkinDone/$checkinTotal',
          expanded: _technicalCheckinExpanded,
          onExpansionChanged:
              (expanded) => setState(() => _technicalCheckinExpanded = expanded),
          items: matrix.checkin,
        ),
        _buildTechnicalStageAccordion(
          title: 'Captura $captureDone/$captureTotal',
          expanded: _technicalCaptureExpanded,
          onExpansionChanged:
              (expanded) => setState(() => _technicalCaptureExpanded = expanded),
          items: matrix.capture,
        ),
        _buildTechnicalStageAccordion(
          title: 'Revis\u00E3o $reviewDone/$reviewTotal',
          expanded: _technicalReviewExpanded,
          onExpansionChanged:
              (expanded) => setState(() => _technicalReviewExpanded = expanded),
          items: matrix.review,
        ),
        _buildTechnicalStageAccordion(
          title: 'Finaliza\u00E7\u00E3o $finalizationDone/$finalizationTotal',
          expanded: _technicalFinalizationExpanded,
          onExpansionChanged:
              (expanded) =>
                  setState(() => _technicalFinalizationExpanded = expanded),
          items: matrix.finalization,
        ),
      ],
    );
  }

  Widget _buildTechnicalStageAccordion({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<TechnicalRuleResult> items,
  }) {
    final hasPending = items.isNotEmpty;
    final pendingLabel = hasPending
        ? '${items.length} pend\u00EAncia(s)'
        : 'Sem pend\u00EAncias nesta etapa';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPending
              ? Colors.orange.withValues(alpha: 0.35)
              : Colors.green.withValues(alpha: 0.30),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pendingLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasPending
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(
              status: hasPending ? _VisualStatus.pending : _VisualStatus.ok,
              label: hasPending ? 'NOK' : 'OK',
            ),
          ],
        ),
        children: [
          if (!hasPending)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Nenhum ajuste pendente nesta etapa.'),
              ),
            )
          else
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isBlocking
                        ? Colors.orange.withValues(alpha: 0.28)
                        : Colors.blueGrey.withValues(alpha: 0.28),
                  ),
                  color: item.isBlocking
                      ? Colors.orange.withValues(alpha: 0.06)
                      : Colors.blueGrey.withValues(alpha: 0.06),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _friendlyDescription(item),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _handlePendingShortcut(item),
                      icon: const Icon(Icons.near_me_outlined, size: 16),
                      label: const Text('Ir para pend\u00EAncia'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
          ),
        )
        .toList();
  }

  List<TechnicalCheckRequirementInput> _buildTechnicalRequirementInputs(
    List<InspectionReviewRequirementStatus> statuses,
  ) {
    return statuses
        .map(
          (item) => TechnicalCheckRequirementInput(
            title: item.field.titulo,
            fulfilled: item.isDone,
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
          child: Column(
            children: [
              if (mandatoryGroups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Sem cart\u00F5es de captura obrigat\u00F3ria dispon\u00EDveis.',
                  ),
                )
              else
                ...mandatoryGroups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NodeCard(
                      group: group,
                      initiallyExpanded:
                          _expandedSubtype == null
                              ? group.pending > 0
                              : _expandedSubtype == group.title,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedSubtype = expanded ? group.title : null;
                        });
                      },
                      onChanged: () => setState(() {}),
                      onApplySubtype: () => _applySubtype(group),
                      onApplySimilar: (source) => _applySimilar(group, source),
                      onAcceptSuggestions: () => _acceptSuggestions(group),
                      onEditItem: _editItem,
                    ),
                  ),
                ),
              ...visibleGroupedRequirements.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CheckinRequirementCard(
                    status: group,
                    onCapture:
                        group.pendingStatus == null
                            ? null
                            : () =>
                                _captureMissingRequirement(group.pendingStatus!),
                  ),
                ),
              ),
            ],
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
          child: Column(
            children:
                capturedGroups
                    .map(
                      (group) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NodeCard(
                          group: group,
                          initiallyExpanded:
                              _expandedSubtype == null
                                  ? group.pending > 0
                                  : _expandedSubtype == group.title,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _expandedSubtype = expanded ? group.title : null;
                            });
                          },
                          onChanged: () => setState(() {}),
                          onApplySubtype: () => _applySubtype(group),
                          onApplySimilar:
                              (source) => _applySimilar(group, source),
                          onAcceptSuggestions: () => _acceptSuggestions(group),
                          onEditItem: _editItem,
                        ),
                      ),
                    )
                    .toList(),
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
    final status = isOk ? _VisualStatus.ok : _VisualStatus.pending;

    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.borderColor.withValues(alpha: 0.30)),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(status: status, label: isOk ? 'OK' : 'NOK'),
          ],
        ),
        children: [child],
      ),
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
    final observationDone = _observacaoController.text.trim().isNotEmpty;

    return Container(
      key: _closingSectionKey,
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClosingAccordion(
            title: 'Anota\u00E7\u00F5es do Vistoriador ${annotationDone ? 1 : 0}/1',
            expanded: _closingNotesExpanded,
            isDone: annotationDone,
            onExpansionChanged:
                (expanded) => setState(() => _closingNotesExpanded = expanded),
            child: annotationRequired
                ? TechnicalJustificationCard(
                    controller: _technicalJustificationController,
                    voiceService: _voiceService,
                    onChanged: (_) => setState(() {}),
                  )
                : const Text(
                    'Sem justificativa t\u00E9cnica obrigat\u00F3ria para este cen\u00E1rio.',
                  ),
          ),
          const SizedBox(height: 10),
          _buildClosingAccordion(
            title: 'Observa\u00E7\u00E3o Final ${observationDone ? 1 : 0}/1',
            expanded: _closingObservationExpanded,
            isDone: observationDone,
            onExpansionChanged: (expanded) =>
                setState(() => _closingObservationExpanded = expanded),
            child: VoiceTextField(
              controller: _observacaoController,
              labelText: 'Observa\u00E7\u00E3o Final',
              minLines: 3,
              maxLines: 4,
              voiceService: _voiceService,
              helperText: 'Toque no microfone para ditar a observa\u00E7\u00E3o.',
            ),
          ),
          if (summary.totalPending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Aten\u00E7\u00E3o: ainda existem ${summary.totalPending} pend\u00EAncia(s).',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          if (summary.photoCountPolicyPending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Builder(
                builder: (context) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  final config = _resolveStep2ConfigForTipo(
                    _resolvedTipoImovel(),
                    appState,
                  );
                  final totalCaptures = _capturesCurrent.length;
                  final message = _reviewTechnicalPresentationService
                      .photoCountPolicyMessage(
                        config: config,
                        totalCaptures: totalCaptures,
                      );

                  return Text(
                    message ?? '',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          if (_reviewTechnicalPresentationService.closingBlockingMessage(
                technicalSummary: technicalSummary,
                justificationText: _technicalJustificationController.text,
              ) !=
              null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _reviewTechnicalPresentationService.closingBlockingMessage(
                      technicalSummary: technicalSummary,
                      justificationText: _technicalJustificationController.text,
                    )!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClosingAccordion({
    required String title,
    required bool expanded,
    required bool isDone,
    required ValueChanged<bool> onExpansionChanged,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? Colors.green.withValues(alpha: 0.28)
              : Colors.orange.withValues(alpha: 0.30),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            _StatusPill(
              status: isDone ? _VisualStatus.ok : _VisualStatus.pending,
              label: isDone ? 'OK' : 'NOK',
            ),
          ],
        ),
        children: [child],
      ),
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
    final config = _resolveStep2ConfigForTipo(_resolvedTipoImovel(), appState);
    final totalCaptures = _capturesCurrent.length;

    if (totalCaptures < config.minFotos) {
      return 1;
    }
    final maxFotos = config.maxFotos;
    if (maxFotos != null && maxFotos > 0 && totalCaptures > maxFotos) {
      return 1;
    }
    return 0;
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

    return _reviewRequirementService
        .buildStatuses(
          fields: config.camposFotos,
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

  // ignore: unused_element
  // ignore: unused_element
  String _normalizeComparableText(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) return '';
    return text
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©', 'e')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âª', 'e')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â­', 'i')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³', 'o')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â´', 'o')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âµ', 'o')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âº', 'u')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§', 'c')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢', 'a')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢', '');
  }

  Future<void> _captureMissingRequirement(
    InspectionReviewRequirementStatus status,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final result = await widget.flowCoordinator.openOverlayCamera(
      context,
      request: _captureRecoveryAdapter.buildCameraFlowRequest(
        title: status.field.titulo,
        tipoImovel: widget.tipoImovel,
        subtipoImovel:
            _resolvedSubtipoImovel(appState) ?? _resolvedTipoImovel().label,
        singleCaptureMode: true,
        cameFromCheckinStep1: false,
        initialSelection: FlowSelection(
          subjectContext: status.field.cameraMacroLocal,
          targetItem: status.field.cameraAmbiente,
          targetQualifier: status.field.cameraElementoInicial,
        ),
        currentCaptures: _capturesCurrent,
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      ),
    );
    if (result == null || !mounted) return;
    _capturesCurrent.add(result);
    setState(() {
      _items.add(InspectionReviewEditableCapture.fromCapture(result));
    });
    await _persistReviewState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${status.field.titulo} registrado com sucesso.')),
    );
  }

  void _applySubtype(InspectionReviewNodeGroup group) {
    if (group.items.isEmpty) return;
    final source = group.items.firstWhere(
      (item) => item.hasAnyClassification,
      orElse: () => group.items.first,
    );
    setState(() {
      for (final item in group.items) {
        item.copyClassificationFrom(source);
        item.recalculateStatus(forceClassified: true);
      }
    });
    _persistReviewState();
  }

  void _acceptSuggestions(InspectionReviewNodeGroup group) {
    setState(() {
      for (final item in group.items) {
        if (item.status == InspectionReviewPhotoStatus.suggested) {
          item.recalculateStatus(forceClassified: true);
        }
      }
    });
    _persistReviewState();
  }

  void _applySimilar(
    InspectionReviewNodeGroup group,
    InspectionReviewEditableCapture source,
  ) {
    setState(() {
      for (final item in group.items) {
        item.copyClassificationFrom(source);
        item.recalculateStatus(forceClassified: true);
      }
    });
    _persistReviewState();
  }

  Future<void> _editItem(InspectionReviewEditableCapture item) async {
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (sheetContext) {
        final itemSelection = item.selection;
        String? elemento = itemSelection.targetQualifier;
        String? material = itemSelection.attributeText('inspection.material');
        String? estado = itemSelection.targetCondition;
        String? ambiente = itemSelection.targetItem;
        final ambientes = _domainAdapter.environmentOptions();
        final elementos = _domainAdapter.elementOptions();
        final materiais = _domainAdapter.materialOptions();
        final estados = _domainAdapter.stateOptions();

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
                        'Classificar foto',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _EditorDropdown(
                        label: _labelForReviewField('ambiente'),
                        value: ambientes.contains(ambiente) ? ambiente : null,
                        items: ambientes,
                        onChanged:
                            (value) => setSheetState(() => ambiente = value),
                      ),
                      const SizedBox(height: 10),
                      _EditorDropdown(
                        label: _labelForReviewField('elemento'),
                        value: elementos.contains(elemento) ? elemento : null,
                        items: elementos,
                        onChanged:
                            (value) => setSheetState(() => elemento = value),
                      ),
                      const SizedBox(height: 10),
                      _EditorDropdown(
                        label: _labelForReviewField('material'),
                        value: materiais.contains(material) ? material : null,
                        items: materiais,
                        onChanged:
                            (value) => setSheetState(() => material = value),
                      ),
                      const SizedBox(height: 10),
                      _EditorDropdown(
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
                          child: const Text('Salvar classifica\u00E7\u00E3o'),
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
    if (edited == true && mounted) {
      setState(() {});
      _persistReviewState();
    }
  }

  Future<void> _finishInspection(BuildContext context, int pendingCount) async {
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
                        title: const Text('Existem pend\u00EAncias'),
                        content: Text(
                          'Ainda existem $pendingCount item(ns) com pend\u00EAncia. Deseja finalizar a vistoria mesmo assim?',
                        ),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.pop(dialogContext, false),
                            child: const Text('Voltar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Finalizar mesmo assim'),
                          ),
                        ],
                      ),
                ) ??
                false;

    if (!shouldContinue) return;
    if (!mounted) return;

    String? exportPath;
    InspectionSyncResult? syncResult;
    int queuedCount = 0;
    InspectionSyncQueueFlushResult? flushResult;
    try {
      final payload = _buildInspectionExportPayload(appState);
      exportPath = await _exportService.export(payload);
      syncResult = await _syncService.syncFinalInspection(payload);

      if (syncResult.success) {
        appState.atualizarReferenciasExternasJobAtual(
          idExterno: syncResult.processId,
          protocoloExterno: syncResult.protocolId ?? syncResult.processNumber,
        );
        flushResult = await _syncQueueService.flush(syncService: _syncService);
      } else if (_syncService.isConfigured) {
        queuedCount = await _syncQueueService.enqueue(
          payload,
          lastError: syncResult.message,
        );
      }
    } catch (_) {
      exportPath = null;
    }

    await appState.finalizarJob();

    if (!mounted) return;
    final syncSuffix =
        syncResult == null
            ? ''
            : (syncResult.success
                ? _buildSyncSuccessMessage(
                  syncResult: syncResult,
                  flushResult: flushResult,
                )
                : _buildSyncFailureMessage(
                  syncResult: syncResult,
                  queuedCount: queuedCount,
                ));

    final message =
        exportPath == null
            ? 'Vistoria finalizada com sucesso.$syncSuffix'
            : 'Vistoria finalizada com sucesso. JSON salvo em: $exportPath.$syncSuffix';
    messenger.showSnackBar(SnackBar(content: Text(message)));
    navigator.popUntil((route) => route.isFirst);
  }

  String _buildSyncSuccessMessage({
    required InspectionSyncResult syncResult,
    InspectionSyncQueueFlushResult? flushResult,
  }) {
    final protocol = syncResult.protocolId ?? syncResult.processNumber;
    final protocolSuffix =
        protocol == null || protocol.trim().isEmpty
            ? ''
            : ' Protocolo: ${protocol.trim()}.';

    if (flushResult == null || flushResult.sentCount == 0) {
      return ' Sincronizado com backend.$protocolSuffix';
    }
    return ' Sincronizado com backend e ${flushResult.sentCount} pend\u00EAncia(s) antiga(s) enviada(s).$protocolSuffix';
  }

  String _buildSyncFailureMessage({
    required InspectionSyncResult syncResult,
    required int queuedCount,
  }) {
    if (!_syncService.isConfigured) {
      return ' Sync n\u00E3o configurado; JSON mantido localmente.';
    }

    final shortMessage = _truncateMessage(syncResult.message);
    return ' Sync pendente em fila local (${queuedCount <= 0 ? 1 : queuedCount} item(ns)). Motivo: $shortMessage';
  }

  String _truncateMessage(String input) {
    final text = input.trim();
    if (text.length <= 120) return text;
    return '${text.substring(0, 120)}...';
  }

  Map<String, dynamic> _buildInspectionExportPayload(AppState appState) {
    final captures =
        _capturesCurrent.map((capture) => capture.toMap()).toList();
    final reviewedCaptures =
        _items
            .map(
              (item) => {
                'filePath': item.filePath,
                'ambiente': item.ambiente,
                'elemento': item.elemento,
                'material': item.material,
                'estado': item.estado,
                'isComplete':
                    item.status == InspectionReviewPhotoStatus.classified,
              },
            )
            .toList();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'job': {
        'id': appState.jobAtual?.id,
        'titulo': appState.jobAtual?.titulo,
        'status': appState.jobAtual?.status.label,
        'idExterno': appState.jobAtual?.idExterno,
        'protocoloExterno': appState.jobAtual?.protocoloExterno,
      },
      'step1': appState.step1Payload,
      'step2': appState.step2Payload,
      'step2Config': appState.inspectionRecoveryPayload['step2Config'],
      'review': {
        'tipoImovel': widget.tipoImovel,
        'observacao': _observacaoController.text.trim(),
        'justificativaTecnica': _technicalJustificationController.text.trim(),
        'capturas': captures,
        'capturasRevisadas': reviewedCaptures,
      },
    };
  }
}

class _CheckinRequirementCard extends StatelessWidget {
  final InspectionReviewRequirementGroupStatus status;
  final VoidCallback? onCapture;

  const _CheckinRequirementCard({
    required this.status,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.isDone ? Colors.green : Colors.orange;
    final subtitle =
        status.isDone
        ? 'Obrigat\u00F3rio atendido'
        : 'Obrigat\u00F3rio \u2014 pendente de captura';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: status.isDone ? 1.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(status.icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        status.isDone
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                    fontWeight:
                        status.isDone ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Progresso ${status.doneCount}/${status.totalCount}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (status.isDone)
            _StatusPill(status: _VisualStatus.ok, label: 'OK')
          else
            FilledButton.tonalIcon(
              onPressed: onCapture,
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: const Text(
                'Capturar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final InspectionReviewNodeGroup group;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onChanged;
  final VoidCallback onApplySubtype;
  final VoidCallback onAcceptSuggestions;
  final ValueChanged<InspectionReviewEditableCapture> onApplySimilar;
  final Future<void> Function(InspectionReviewEditableCapture) onEditItem;

  const _NodeCard({
    required this.group,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onChanged,
    required this.onApplySubtype,
    required this.onAcceptSuggestions,
    required this.onApplySimilar,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    final status =
        group.pending > 0
            ? _VisualStatus.pending
            : group.suggested > 0
            ? _VisualStatus.suggested
            : _VisualStatus.ok;
    final icon = _iconForSubtype(group.title);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: status.borderColor.withValues(alpha: 0.35),
          width: status == _VisualStatus.pending ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: status.iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: status.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.subtitle(group),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          group.pending > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: status.subtitleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: _StatusPill(status: status, label: status.label(group)),
        children: [
          if (group.items.isNotEmpty)
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: group.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = group.items[index];
                  return _ThumbCard(
                    item: item,
                    onTap: () async {
                      await onEditItem(item);
                      onChanged();
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onApplySubtype,
                icon: const Icon(Icons.copy_all_outlined, size: 16),
                label: const Text(
                  'Aplicar ao subtipo',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (group.suggested > 0)
                OutlinedButton.icon(
                  onPressed: onAcceptSuggestions,
                  icon: const Icon(Icons.task_alt_outlined, size: 16),
                  label: const Text(
                    'Aceitar sugest\u00F5es',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          if (group.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onApplySimilar(group.items.first),
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                  label: const Text(
                    'Aplicar aos semelhantes',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForSubtype(String subtype) {
    final normalized = subtype.toLowerCase();
    if (normalized.contains('exterior') || normalized.contains('fachada')) {
      return Icons.home_outlined;
    }
    if (normalized.contains('sala')) {
      return Icons.weekend_outlined;
    }
    if (normalized.contains('cozinha')) {
      return Icons.restaurant_outlined;
    }
    if (normalized.contains('banheiro')) {
      return Icons.shower_outlined;
    }
    if (normalized.contains('\u00E1rea') || normalized.contains('comum')) {
      return Icons.apartment_outlined;
    }
    if (normalized.contains('garagem')) {
      return Icons.garage_outlined;
    }
    return Icons.grid_view_rounded;
  }
}

class _ThumbCard extends StatelessWidget {
  final InspectionReviewEditableCapture item;
  final VoidCallback onTap;

  const _ThumbCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status =
        item.status == InspectionReviewPhotoStatus.pending
            ? _VisualStatus.pending
            : item.status == InspectionReviewPhotoStatus.suggested
            ? _VisualStatus.suggested
            : _VisualStatus.ok;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 122,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              width: 122,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _CaptureThumbnail(filePath: item.filePath),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.hourMinute,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _StatusPill(status: status, label: status.shortLabel),
            const SizedBox(height: 4),
            Text(
              item.shortDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureThumbnail extends StatelessWidget {
  final String filePath;

  const _CaptureThumbnail({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 28)),
      );
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        errorBuilder:
            (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 28),
            ),
      ),
    );
  }
}

class _EditorDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _EditorDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value != null && items.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items:
          items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _VisualStatus status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.pillBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.pillText),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.pillText,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _VisualStatus { ok, suggested, pending }

extension on _VisualStatus {
  Color get borderColor =>
      this == _VisualStatus.ok
          ? Colors.green
          : this == _VisualStatus.suggested
          ? Colors.amber
          : Colors.orange;
  Color get iconBackground =>
      this == _VisualStatus.ok
          ? Colors.green.shade50
          : this == _VisualStatus.suggested
          ? Colors.amber.shade50
          : Colors.orange.shade50;
  Color get iconColor =>
      this == _VisualStatus.ok
          ? Colors.green.shade700
          : this == _VisualStatus.suggested
          ? Colors.amber.shade800
          : Colors.orange.shade700;
  Color get subtitleColor =>
      this == _VisualStatus.ok
          ? Colors.green.shade700
          : this == _VisualStatus.suggested
          ? Colors.amber.shade800
          : Colors.orange.shade700;
  Color get pillBackground =>
      this == _VisualStatus.ok
          ? Colors.green.shade50
          : this == _VisualStatus.suggested
          ? Colors.amber.shade50
          : Colors.orange.shade50;
  Color get pillBorder =>
      this == _VisualStatus.ok
          ? Colors.green.shade100
          : this == _VisualStatus.suggested
          ? Colors.amber.shade100
          : Colors.orange.shade200;
  Color get pillText =>
      this == _VisualStatus.ok
          ? Colors.green.shade700
          : this == _VisualStatus.suggested
          ? Colors.amber.shade800
          : Colors.orange.shade700;
  IconData get icon =>
      this == _VisualStatus.ok
          ? Icons.check_circle_outline
          : this == _VisualStatus.suggested
          ? Icons.auto_awesome_outlined
          : Icons.warning_amber_rounded;
  String get shortLabel =>
      this == _VisualStatus.ok
          ? 'OK'
          : this == _VisualStatus.suggested
          ? 'Sug.'
          : 'Pend.';

  String label(InspectionReviewNodeGroup group) {
    switch (this) {
      case _VisualStatus.ok:
        return 'OK';
      case _VisualStatus.suggested:
        return 'Revisar';
      case _VisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == InspectionReviewPhotoStatus.pending,
          orElse: () => group.items.first,
        );
        return source.elemento?.trim().isNotEmpty == true
            ? source.elemento!
            : 'Pendente';
    }
  }

  String subtitle(InspectionReviewNodeGroup group) {
    switch (this) {
      case _VisualStatus.ok:
        return 'Tudo revisado e pronto para finalizar';
      case _VisualStatus.suggested:
        return 'Existem sugest\u00F5es autom\u00E1ticas para revisar';
      case _VisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == InspectionReviewPhotoStatus.pending,
          orElse: () => group.items.first,
        );
        return source.elemento?.trim().isNotEmpty == true
            ? source.elemento!
            : 'Classifica\u00E7\u00E3o incompleta';
    }
  }
}

