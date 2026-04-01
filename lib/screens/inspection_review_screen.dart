import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/checkin_step2_config.dart';
import '../models/job_status.dart';
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
import '../services/inspection_sync_queue_service.dart';
import '../services/inspection_sync_service.dart';
import '../services/voice_input_service.dart';
import '../widgets/voice_text_field.dart';
import 'overlay_camera_screen.dart';
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
  late final List<_EditableCapture> _items;
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

  final GlobalKey _checkinPendingSectionKey = GlobalKey();
  final GlobalKey _capturedPhotosSectionKey = GlobalKey();
  final GlobalKey _closingSectionKey = GlobalKey();

  String? _expandedSubtype;
  bool _checkinAccordionExpanded = true;
  bool _capturedAccordionExpanded = true;
  bool _technicalCheckinExpanded = true;
  bool _technicalCaptureExpanded = true;
  bool _technicalReviewExpanded = true;
  bool _technicalFinalizationExpanded = true;
  bool _closingNotesExpanded = true;
  bool _closingObservationExpanded = true;

  static const _elementos = <String>[
    'Visão geral',
    'Número',
    'Porta',
    'Portão',
    'Janela',
    'Piso',
    'Parede',
    'Teto',
    'Outro',
  ];
  static const _materiais = <String>[
    'Alvenaria',
    'Metal',
    'Madeira',
    'Vidro',
    'Cerâmica',
    'Concreto',
    'Outro',
  ];
  static const _estados = <String>[
    'Bom',
    'Regular',
    'Ruim',
    'Necessita reparo',
    'Não se aplica',
  ];
  static const _ambientes = <String>[
    'Fachada',
    'Logradouro',
    'Acesso ao imóvel',
    'Entorno',
    'Sala de Estar',
    'Sala',
    'Dormitório',
    'Cozinha',
    'Banheiro',
    'Área de serviço',
    'Áreas Comuns',
    'Garagem',
    'Outro ambiente',
  ];

  @override
  void initState() {
    super.initState();
    _items = widget.captures.map(_EditableCapture.fromCapture).toList();
    _hydrateReviewedItemsFromRecovery();
    _capturesCurrent = List.of(widget.captures);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _persistReviewState();
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

      item.ambiente = _nonEmptyText(reviewed['ambiente']) ?? item.ambiente;
      item.elemento = _nonEmptyText(reviewed['elemento']);
      item.material = _nonEmptyText(reviewed['material']);
      item.estado = _nonEmptyText(reviewed['estado']);

      final isComplete = reviewed['isComplete'] == true;
      item.recalculateStatus(forceClassified: isComplete);
    }
  }

  Future<void> _persistReviewState() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final step2Payload = _buildStep2PayloadFromCaptures(appState.step2Payload);

    await appState.setInspectionRecoveryStage(
      stageKey: 'inspection_review',
      stageLabel: 'Revisão final',
      routeName: '/inspection_review',
      payload: {
        ...appState.inspectionRecoveryPayload,
        'step1': appState.step1Payload,
        'step2': step2Payload,
        'review': {
          'tipoImovel': widget.tipoImovel,
          'captures':
              _capturesCurrent.map((capture) => capture.toMap()).toList(),
          'capturesRevisadas': _serializeReviewedCaptures(),
        },
      },
    );
  }

  List<Map<String, dynamic>> _serializeReviewedCaptures() {
    return _items
        .map(
          (item) => {
            'filePath': item.filePath,
            'ambiente': item.ambiente,
            'elemento': item.elemento,
            'material': item.material,
            'estado': item.estado,
            'isComplete': item.status == _PhotoStatus.classified,
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

      OverlayCameraCaptureResult? matchedCapture;
      for (final capture in _capturesCurrent) {
        final sameAmbiente =
            capture.ambiente.trim().toLowerCase() ==
            campo.cameraAmbiente.trim().toLowerCase();
        final sameElemento =
            campo.cameraElementoInicial == null ||
            capture.elemento?.trim().toLowerCase() ==
                campo.cameraElementoInicial!.trim().toLowerCase();

        if (sameAmbiente && sameElemento) {
          matchedCapture = capture;
          break;
        }
      }

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
    final rawTipo = widget.tipoImovel.split('•').first.trim();
    return TipoImovelExtension.fromString(rawTipo);
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
    final summary = _buildSummary();
    final checkinStatuses = _buildCheckinRequirements();
    final technicalSummary = _technicalSummaryService.build(
      tipoImovel: _resolvedTipoImovel().label,
      evidences: _buildTechnicalEvidenceInputs(),
      requirements: _buildTechnicalRequirementInputs(checkinStatuses),
    );

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('MENU DE VISTORIA')),
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
            _buildTechnicalPendingAccordionsSection(
              context: context,
              technicalSummary: technicalSummary,
              checkinStatuses: checkinStatuses,
            ),
            const SizedBox(height: 8),
            _buildReviewAccordionsSection(
              context: context,
              checkinStatuses: checkinStatuses,
            ),
            const SizedBox(height: 16),
            _buildClosingCard(context, summary, technicalSummary),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalPendingAccordionsSection({
    required BuildContext context,
    required InspectionTechnicalSummary technicalSummary,
    required List<_CheckinRequirementStatus> checkinStatuses,
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
        _items.where((item) => item.status == _PhotoStatus.classified).length;

    final finalizationTotal = matrix.finalization.isEmpty ? 1 : matrix.finalization.length;
    final finalizationDone = matrix.finalization.isEmpty ? 1 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PENDÊNCIAS TÉCNICAS DA VISTORIA',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em "Ir para pendência" para navegar direto ao ponto de ajuste.',
            style: Theme.of(context).textTheme.bodySmall,
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
            title: 'Revisão $reviewDone/$reviewTotal',
            expanded: _technicalReviewExpanded,
            onExpansionChanged:
                (expanded) => setState(() => _technicalReviewExpanded = expanded),
            items: matrix.review,
          ),
          _buildTechnicalStageAccordion(
            title: 'Finalização $finalizationDone/$finalizationTotal',
            expanded: _technicalFinalizationExpanded,
            onExpansionChanged:
                (expanded) =>
                    setState(() => _technicalFinalizationExpanded = expanded),
            items: matrix.finalization,
          ),
        ],
      ),
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
        ? '${items.length} pendência(s)'
        : 'Sem pendências nesta etapa';

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
                      label: const Text('Ir para pendência'),
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
    switch (item.stage) {
      case TechnicalRuleStage.checkin:
        return 'No check-in obrigatório: ${item.description}';
      case TechnicalRuleStage.capture:
        return 'Nas fotos capturadas: ${item.description}';
      case TechnicalRuleStage.review:
        return 'Na revisão das fotos: ${item.description}';
      case TechnicalRuleStage.finalization:
        return 'Na etapa de finalização: ${item.description}';
    }
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
    List<_CheckinRequirementStatus> statuses,
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
    switch (item.stage) {
      case TechnicalRuleStage.checkin:
        setState(() {
          _checkinAccordionExpanded = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 220));
        await _scrollToSection(_checkinPendingSectionKey);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendência aberta na seção de check-in.'),
            duration: Duration(milliseconds: 1400),
          ),
        );
        break;
      case TechnicalRuleStage.capture:
        setState(() {
          _capturedAccordionExpanded = true;
          final subtipo = item.subtipo?.trim();
          if (subtipo != null && subtipo.isNotEmpty) {
            _expandedSubtype = subtipo;
          }
        });
        await Future<void>.delayed(const Duration(milliseconds: 220));
        await _scrollToSection(_capturedPhotosSectionKey);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.subtipo?.trim().isNotEmpty == true
                  ? 'Navegado para captura/revisão de ${item.subtipo!.trim()}.'
                  : 'Pendência de captura aberta na revisão de fotos.',
            ),
            duration: const Duration(milliseconds: 1500),
          ),
        );
        break;
      case TechnicalRuleStage.review:
        if (item.subtipo != null && item.subtipo!.trim().isNotEmpty) {
          setState(() {
            _expandedSubtype = item.subtipo!.trim();
            _capturedAccordionExpanded = true;
          });
        }
        await Future<void>.delayed(const Duration(milliseconds: 280));
        await _scrollToSection(_capturedPhotosSectionKey);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendência aberta na seção de revisão de fotos.'),
            duration: Duration(milliseconds: 1400),
          ),
        );
        break;
      case TechnicalRuleStage.finalization:
        await _scrollToSection(_closingSectionKey);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendência aberta na seção de encerramento.'),
            duration: Duration(milliseconds: 1400),
          ),
        );
        break;
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
    required List<_CheckinRequirementStatus> checkinStatuses,
  }) {
    final mandatoryCapturedItems = <_EditableCapture>[];
    final mandatoryCapturedPaths = <String>{};

    for (final status in checkinStatuses.where((status) => status.isDone)) {
      final matched = _items.firstWhere(
        (item) {
          final sameAmbiente =
              _normalizeComparableText(item.ambiente) ==
              _normalizeComparableText(status.field.cameraAmbiente);
          final sameElemento =
              status.field.cameraElementoInicial == null ||
              _normalizeComparableText(item.elemento) ==
                  _normalizeComparableText(status.field.cameraElementoInicial);
          final notUsed = !mandatoryCapturedPaths.contains(item.filePath);
          return sameAmbiente && sameElemento && notUsed;
        },
        orElse:
            () => _EditableCapture(
              filePath: '',
              macroLocal: null,
              ambiente: '',
              elemento: null,
              material: null,
              estado: null,
              capturedAt: DateTime.fromMillisecondsSinceEpoch(0),
              status: _PhotoStatus.pending,
            ),
      );
      if (matched.filePath.isNotEmpty) {
        mandatoryCapturedItems.add(matched);
        mandatoryCapturedPaths.add(matched.filePath);
      }
    }

    final mandatoryGroups = _buildGroupsForItems(mandatoryCapturedItems);
    final groupedRequirements = _groupCheckinRequirements(checkinStatuses);
    final capturedGroups = _buildGroupsForItems(
      _items
          .where((item) => !mandatoryCapturedPaths.contains(item.filePath))
          .toList(),
    );

    final checkinPendencias =
        checkinStatuses.where((status) => !status.isDone).length;
    final hasCheckinPending =
        checkinPendencias > 0 ||
        mandatoryGroups.any(
          (group) => group.pending > 0 || group.suggested > 0,
        );
    final capturedPendencias = capturedGroups.fold<int>(
      0,
      (sum, group) => sum + group.pending,
    );
    final requiredDone = checkinStatuses.where((status) => status.isDone).length;
    final requiredTotal = checkinStatuses.length;
    final capturedClassified =
        _items.where((item) => item.status == _PhotoStatus.classified).length;
    final capturedTotal = _items.length;
    final hasCapturedPending = capturedPendencias > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'REVISÃO DE FOTOS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        _buildReviewAccordion(
          key: _checkinPendingSectionKey,
          title: 'Fotos Obrigatórias Do Check-In',
          isOk: !hasCheckinPending,
          subtitle:
              hasCheckinPending
                  ? '$checkinPendencias pendência(s) para captura • progresso $requiredDone/$requiredTotal'
                  : 'Todas as fotos obrigatórias foram registradas • progresso $requiredDone/$requiredTotal',
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
                    'Sem cartões de captura obrigatória disponíveis.',
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
              ...groupedRequirements.map(
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
          isOk: !hasCapturedPending,
          subtitle:
              hasCapturedPending
                  ? '$capturedPendencias pendência(s) de classificação • progresso $capturedClassified/$capturedTotal'
                  : 'Todas as fotos capturadas estão classificadas • progresso $capturedClassified/$capturedTotal',
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
    _ReviewSummary summary,
    InspectionTechnicalSummary technicalSummary,
  ) {
    final annotationRequired = technicalSummary.requiresJustification;
    final annotationDone =
        !annotationRequired || _technicalJustificationController.text.trim().isNotEmpty;
    final observationDone = _observacaoController.text.trim().isNotEmpty;

    return Container(
      key: _closingSectionKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENCERRAMENTO',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _buildClosingAccordion(
            title: 'Anotações Do Vistoriador ${annotationDone ? 1 : 0}/1',
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
                    'Sem justificativa técnica obrigatória para este cenário.',
                  ),
          ),
          const SizedBox(height: 10),
          _buildClosingAccordion(
            title: 'Observação Final ${observationDone ? 1 : 0}/1',
            expanded: _closingObservationExpanded,
            isDone: observationDone,
            onExpansionChanged: (expanded) =>
                setState(() => _closingObservationExpanded = expanded),
            child: VoiceTextField(
              controller: _observacaoController,
              labelText: 'Observação Final',
              minLines: 3,
              maxLines: 4,
              voiceService: _voiceService,
              helperText: 'Toque no microfone para ditar a observação.',
            ),
          ),
          if (summary.totalPending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Atenção: ainda existem ${summary.totalPending} pendência(s).',
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
                  final minMsg =
                      totalCaptures < config.minFotos
                          ? 'Mínimo de ${config.minFotos} foto(s) não atingido.'
                          : null;
                  final maxFotos = config.maxFotos;
                  final maxMsg =
                      maxFotos != null &&
                              maxFotos > 0 &&
                              totalCaptures > maxFotos
                          ? 'Máximo de $maxFotos foto(s) excedido.'
                          : null;
                  final message = [
                    if (minMsg != null) minMsg,
                    if (maxMsg != null) maxMsg,
                  ].join(' ');

                  return Text(
                    message,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          if (!technicalSummary.canProceedWith(
            _technicalJustificationController.text,
          ))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                technicalSummary.pendingMatrix.hasBlocking
                    ? 'Conclusão técnica bloqueada até resolver as pendências normativas.'
                    : 'Preencha a anotação do vistoriador para concluir a vistoria.',
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

  _ReviewSummary _buildSummary() {
    final photoPending =
        _items.where((item) => item.status == _PhotoStatus.pending).length;
    final suggested =
        _items.where((item) => item.status == _PhotoStatus.suggested).length;
    final classified =
        _items.where((item) => item.status == _PhotoStatus.classified).length;
    final missingCheckin =
        _buildCheckinRequirements().where((item) => !item.isDone).length;
    final photoCountPolicyPending = _buildPhotoCountPolicyPending();
    return _ReviewSummary(
      total: _items.length,
      photoPending: photoPending,
      missingCheckin: missingCheckin,
      photoCountPolicyPending: photoCountPolicyPending,
      suggested: suggested,
      classified: classified,
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

  List<_NodeGroup> _buildGroupsForItems(List<_EditableCapture> sourceItems) {
    final map = <String, List<_EditableCapture>>{};
    for (final item in sourceItems) {
      final key = item.ambiente.trim().isEmpty ? 'Sem subtipo' : item.ambiente;
      map.putIfAbsent(key, () => <_EditableCapture>[]).add(item);
    }
    final groups =
        map.entries.map((entry) {
          final items = entry.value;
          return _NodeGroup(
            title: entry.key,
            items: items,
            pending:
                items.where((e) => e.status == _PhotoStatus.pending).length,
            suggested:
                items.where((e) => e.status == _PhotoStatus.suggested).length,
            classified:
                items.where((e) => e.status == _PhotoStatus.classified).length,
          );
        }).toList();
    groups.sort((a, b) {
      if (a.pending != b.pending) return b.pending.compareTo(a.pending);
      if (a.suggested != b.suggested) return b.suggested.compareTo(a.suggested);
      return a.title.compareTo(b.title);
    });
    return groups;
  }

  List<_CheckinRequirementStatus> _buildCheckinRequirements() {
    final appState = Provider.of<AppState>(context, listen: false);
    final tipo = _resolvedTipoImovel();
    final persistedStep2Model = _dynamicConfigService.restoreStep2Model(
      tipo: tipo,
      step2Payload: appState.step2Payload,
    );

    final config = _resolveStep2ConfigForTipo(tipo, appState);

    return config.camposFotos.where((campo) => campo.obrigatorio).map((campo) {
      final hasEvidence = _items.any((item) {
        final sameAmbiente =
            _normalizeComparableText(item.ambiente) ==
            _normalizeComparableText(campo.cameraAmbiente);
        final sameElemento =
            campo.cameraElementoInicial == null
                ? true
                : (_normalizeComparableText(item.elemento) ==
                    _normalizeComparableText(campo.cameraElementoInicial));
        return sameAmbiente && sameElemento;
      });
      final isPersisted = persistedStep2Model.isPhotoCaptured(campo.id);
      return _CheckinRequirementStatus(
        field: campo,
        isDone: hasEvidence || isPersisted,
      );
    }).toList();
  }

  List<_CheckinRequirementGroupStatus> _groupCheckinRequirements(
    List<_CheckinRequirementStatus> statuses,
  ) {
    final map = <String, List<_CheckinRequirementStatus>>{};
    for (final status in statuses) {
      final key = _normalizeComparableText(status.field.titulo);
      map.putIfAbsent(key, () => <_CheckinRequirementStatus>[]).add(status);
    }

    final groups = map.values
        .map((items) {
          final doneCount = items.where((item) => item.isDone).length;
          final firstPending = items.cast<_CheckinRequirementStatus?>().firstWhere(
            (item) => item != null && !item.isDone,
            orElse: () => null,
          );
          return _CheckinRequirementGroupStatus(
            title: items.first.field.titulo,
            icon: items.first.field.icon,
            doneCount: doneCount,
            totalCount: items.length,
            pendingStatus: firstPending,
          );
        })
        .toList();

    groups.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return a.title.compareTo(b.title);
    });
    return groups;
  }

  String _normalizeComparableText(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) return '';
    return text
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  Future<void> _captureMissingRequirement(
    _CheckinRequirementStatus status,
  ) async {
    final result = await widget.flowCoordinator.openOverlayCamera(
      context,
      title: status.field.titulo,
      tipoImovel: widget.tipoImovel,
      subtipoImovel: widget.tipoImovel,
      singleCaptureMode: true,
      preselectedMacroLocal: status.field.cameraMacroLocal,
      initialAmbiente: status.field.cameraAmbiente,
      initialElemento: status.field.cameraElementoInicial,
      cameFromCheckinStep1: false,
    );
    if (result == null || !mounted) return;
    _capturesCurrent.add(result);
    setState(() {
      _items.add(_EditableCapture.fromCapture(result));
    });
    await _persistReviewState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${status.field.titulo} registrado com sucesso.')),
    );
  }

  void _applySubtype(_NodeGroup group) {
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

  void _acceptSuggestions(_NodeGroup group) {
    setState(() {
      for (final item in group.items) {
        if (item.status == _PhotoStatus.suggested) {
          item.recalculateStatus(forceClassified: true);
        }
      }
    });
    _persistReviewState();
  }

  void _applySimilar(_NodeGroup group, _EditableCapture source) {
    setState(() {
      for (final item in group.items) {
        item.copyClassificationFrom(source);
        item.recalculateStatus(forceClassified: true);
      }
    });
    _persistReviewState();
  }

  Future<void> _editItem(_EditableCapture item) async {
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (sheetContext) {
        String? elemento = item.elemento;
        String? material = item.material;
        String? estado = item.estado;
        String? ambiente = item.ambiente;

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
                        label: 'Subtipo / Local',
                        value: _ambientes.contains(ambiente) ? ambiente : null,
                        items: _ambientes,
                        onChanged:
                            (value) => setSheetState(() => ambiente = value),
                      ),
                      const SizedBox(height: 10),
                      _EditorDropdown(
                        label: 'Elemento',
                        value: _elementos.contains(elemento) ? elemento : null,
                        items: _elementos,
                        onChanged:
                            (value) => setSheetState(() => elemento = value),
                      ),
                      const SizedBox(height: 10),
                      _EditorDropdown(
                        label: 'Material',
                        value: _materiais.contains(material) ? material : null,
                        items: _materiais,
                        onChanged:
                            (value) => setSheetState(() => material = value),
                      ),
                      const SizedBox(height: 10),
                      _EditorDropdown(
                        label: 'Estado',
                        value: _estados.contains(estado) ? estado : null,
                        items: _estados,
                        onChanged:
                            (value) => setSheetState(() => estado = value),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            item.ambiente = ambiente ?? item.ambiente;
                            item.elemento = elemento;
                            item.material = material;
                            item.estado = estado;
                            item.recalculateStatus();
                            Navigator.of(sheetContext).pop(true);
                          },
                          child: const Text('Salvar classificação'),
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
                        title: const Text('Existem pendências'),
                        content: Text(
                          'Ainda existem $pendingCount item(ns) com pendência. Deseja finalizar a vistoria mesmo assim?',
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
    return ' Sincronizado com backend e ${flushResult.sentCount} pendência(s) antiga(s) enviada(s).$protocolSuffix';
  }

  String _buildSyncFailureMessage({
    required InspectionSyncResult syncResult,
    required int queuedCount,
  }) {
    if (!_syncService.isConfigured) {
      return ' Sync não configurado; JSON mantido localmente.';
    }

    final shortMessage = _truncateMessage(syncResult.message);
    return ' Sync pendente em fila local (${queuedCount <= 0 ? 1 : queuedCount} item(ns)). Motivo: $shortMessage';
  }

  String _truncateMessage(String input) {
    final text = input.trim();
    if (text.length <= 120) return text;
    return '${text.substring(0, 120)}...';
  }

  String? _nonEmptyText(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    if (text.isEmpty) return null;
    return text;
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
                'isComplete': item.status == _PhotoStatus.classified,
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
  final _CheckinRequirementGroupStatus status;
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
        ? 'Obrigatório atendido'
        : 'Obrigatório — pendente de captura';
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
  final _NodeGroup group;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onChanged;
  final VoidCallback onApplySubtype;
  final VoidCallback onAcceptSuggestions;
  final ValueChanged<_EditableCapture> onApplySimilar;
  final Future<void> Function(_EditableCapture) onEditItem;

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
                    'Aceitar sugestões',
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
    if (normalized.contains('área') || normalized.contains('comum')) {
      return Icons.apartment_outlined;
    }
    if (normalized.contains('garagem')) {
      return Icons.garage_outlined;
    }
    return Icons.grid_view_rounded;
  }
}

class _ThumbCard extends StatelessWidget {
  final _EditableCapture item;
  final VoidCallback onTap;

  const _ThumbCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status =
        item.status == _PhotoStatus.pending
            ? _VisualStatus.pending
            : item.status == _PhotoStatus.suggested
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

  String label(_NodeGroup group) {
    switch (this) {
      case _VisualStatus.ok:
        return 'OK';
      case _VisualStatus.suggested:
        return 'Revisar';
      case _VisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == _PhotoStatus.pending,
          orElse: () => group.items.first,
        );
        return source.elemento?.trim().isNotEmpty == true
            ? source.elemento!
            : 'Pendente';
    }
  }

  String subtitle(_NodeGroup group) {
    switch (this) {
      case _VisualStatus.ok:
        return 'Tudo revisado e pronto para finalizar';
      case _VisualStatus.suggested:
        return 'Existem sugestões automáticas para revisar';
      case _VisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == _PhotoStatus.pending,
          orElse: () => group.items.first,
        );
        final detail =
            source.elemento?.trim().isNotEmpty == true
                ? source.elemento!
                : 'Classificação incompleta';
        return 'Pendente: $detail';
    }
  }
}

class _CheckinRequirementStatus {
  final CheckinStep2PhotoFieldConfig field;
  final bool isDone;

  const _CheckinRequirementStatus({required this.field, required this.isDone});
}

class _CheckinRequirementGroupStatus {
  final String title;
  final IconData icon;
  final int doneCount;
  final int totalCount;
  final _CheckinRequirementStatus? pendingStatus;

  const _CheckinRequirementGroupStatus({
    required this.title,
    required this.icon,
    required this.doneCount,
    required this.totalCount,
    required this.pendingStatus,
  });

  bool get isDone => doneCount >= totalCount;
}

class _NodeGroup {
  final String title;
  final List<_EditableCapture> items;
  final int pending;
  final int suggested;
  final int classified;

  const _NodeGroup({
    required this.title,
    required this.items,
    required this.pending,
    required this.suggested,
    required this.classified,
  });
}

class _EditableCapture {
  String filePath;
  String? macroLocal;
  String ambiente;
  String? elemento;
  String? material;
  String? estado;
  DateTime capturedAt;
  _PhotoStatus status;

  _EditableCapture({
    required this.filePath,
    required this.macroLocal,
    required this.ambiente,
    required this.elemento,
    required this.material,
    required this.estado,
    required this.capturedAt,
    required this.status,
  });

  factory _EditableCapture.fromCapture(OverlayCameraCaptureResult capture) {
    final hasCompleteClassification =
        (capture.elemento?.trim().isNotEmpty ?? false) &&
        (capture.material?.trim().isNotEmpty ?? false) &&
        (capture.estado?.trim().isNotEmpty ?? false);
    final hasAnyClassification =
        (capture.elemento?.trim().isNotEmpty ?? false) ||
        (capture.material?.trim().isNotEmpty ?? false) ||
        (capture.estado?.trim().isNotEmpty ?? false);

    return _EditableCapture(
      filePath: capture.filePath,
      macroLocal: capture.macroLocal,
      ambiente: capture.ambiente,
      elemento: capture.elemento,
      material: capture.material,
      estado: capture.estado,
      capturedAt: capture.capturedAt,
      status:
          hasCompleteClassification
              ? _PhotoStatus.classified
              : hasAnyClassification
              ? _PhotoStatus.suggested
              : _PhotoStatus.pending,
    );
  }

  bool get hasAnyClassification =>
      (elemento?.trim().isNotEmpty ?? false) ||
      (material?.trim().isNotEmpty ?? false) ||
      (estado?.trim().isNotEmpty ?? false);

  String get hourMinute =>
      '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}';

  String get shortDescription {
    final parts = <String>[
      if (elemento?.trim().isNotEmpty == true) elemento!,
      if (material?.trim().isNotEmpty == true) material!,
      if (estado?.trim().isNotEmpty == true) estado!,
    ];
    return parts.isEmpty ? 'Sem classificação' : parts.join(' • ');
  }

  void copyClassificationFrom(_EditableCapture source) {
    ambiente = source.ambiente;
    elemento = source.elemento;
    material = source.material;
    estado = source.estado;
    macroLocal = source.macroLocal;
  }

  void recalculateStatus({bool forceClassified = false}) {
    final hasCompleteClassification =
        (elemento?.trim().isNotEmpty ?? false) &&
        (material?.trim().isNotEmpty ?? false) &&
        (estado?.trim().isNotEmpty ?? false);
    final hasAnyClassification =
        (elemento?.trim().isNotEmpty ?? false) ||
        (material?.trim().isNotEmpty ?? false) ||
        (estado?.trim().isNotEmpty ?? false);

    if (forceClassified && hasAnyClassification) {
      status = _PhotoStatus.classified;
      return;
    }
    if (hasCompleteClassification) {
      status = _PhotoStatus.classified;
    } else if (hasAnyClassification) {
      status = _PhotoStatus.suggested;
    } else {
      status = _PhotoStatus.pending;
    }
  }
}

enum _PhotoStatus { pending, suggested, classified }

class _ReviewSummary {
  final int total;
  final int photoPending;
  final int missingCheckin;
  final int photoCountPolicyPending;
  final int suggested;
  final int classified;

  const _ReviewSummary({
    required this.total,
    required this.photoPending,
    required this.missingCheckin,
    required this.photoCountPolicyPending,
    required this.suggested,
    required this.classified,
  });

  int get totalPending =>
      photoPending + missingCheckin + photoCountPolicyPending;
}
