import '../models/inspection_review_models.dart';
import '../models/inspection_review_operational_models.dart';
import '../models/inspection_technical_summary.dart';
import '../models/technical_rule_result.dart';

class InspectionReviewOperationalService {
  const InspectionReviewOperationalService();

  static const InspectionReviewOperationalService instance =
      InspectionReviewOperationalService();

  InspectionReviewOperationalData build({
    required List<InspectionReviewEditableCapture> items,
    required List<InspectionReviewRequirementStatus> checkinStatuses,
    required InspectionTechnicalSummary technicalSummary,
    required bool justificationMissing,
    required int photoCountPolicyPending,
  }) {
    final pendings = _buildPendings(
      items: items,
      checkinStatuses: checkinStatuses,
      technicalSummary: technicalSummary,
      justificationMissing: justificationMissing,
      photoCountPolicyPending: photoCountPolicyPending,
    );

    return InspectionReviewOperationalData(
      header: InspectionReviewHeaderData(
        supportText: pendings.isEmpty
            ? 'Confira a composição identificada antes de finalizar.'
            : 'Confira a composição identificada e finalize os itens pendentes.',
        hasBlockingPendings: pendings.isNotEmpty,
      ),
      compositions: _buildCompositions(items),
      evidences: _buildEvidences(items),
      pendings: pendings,
      canFinalize: pendings.isEmpty,
      footerBlockingMessage: pendings.isEmpty
          ? null
          : 'Conclua os itens pendentes para finalizar.',
    );
  }

  List<InspectionReviewCompositionEntry> _buildCompositions(
    List<InspectionReviewEditableCapture> items,
  ) {
    final grouped = <String, List<InspectionReviewEditableCapture>>{};
    for (final item in items) {
      final key = _compositionKey(item);
      grouped.putIfAbsent(key, () => <InspectionReviewEditableCapture>[]).add(item);
    }

    return grouped.entries.map((entry) {
      final first = entry.value.first;
      final detailTrail = <String>[
        if (_hasText(first.elemento)) first.elemento!.trim(),
        if (_hasText(first.material)) first.material!.trim(),
        if (_hasText(first.estado)) first.estado!.trim(),
      ];

      return InspectionReviewCompositionEntry(
        id: entry.key,
        title: _occurrenceTitle(first),
        contextTrail: <String>[
          if (_hasText(first.macroLocal)) first.macroLocal!.trim(),
          if (_hasText(first.ambienteBase)) first.ambienteBase!.trim(),
        ],
        detailTrail: detailTrail,
        evidenceCount: entry.value.length,
        classified: entry.value.every(
          (item) => item.status == InspectionReviewPhotoStatus.classified,
        ),
      );
    }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  List<InspectionReviewEvidenceEntry> _buildEvidences(
    List<InspectionReviewEditableCapture> items,
  ) {
    final sorted = List<InspectionReviewEditableCapture>.from(items)
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    return sorted.map((item) {
      final qualifiers = <String>[
        if (_hasText(item.material)) item.material!.trim(),
        if (_hasText(item.estado)) item.estado!.trim(),
      ];

      return InspectionReviewEvidenceEntry(
        id: item.filePath,
        filePath: item.filePath,
        contextTrail: <String>[
          if (_hasText(item.macroLocal)) item.macroLocal!.trim(),
          if (_hasText(item.ambienteBase)) item.ambienteBase!.trim(),
          _occurrenceTitle(item),
        ],
        itemLabel: _hasText(item.elemento)
            ? item.elemento!.trim()
            : 'Sem item classificado',
        qualifiers: qualifiers,
        classified: item.status == InspectionReviewPhotoStatus.classified,
        capturedAtLabel: item.hourMinute,
      );
    }).toList(growable: false);
  }

  List<InspectionReviewPendingEntry> _buildPendings({
    required List<InspectionReviewEditableCapture> items,
    required List<InspectionReviewRequirementStatus> checkinStatuses,
    required InspectionTechnicalSummary technicalSummary,
    required bool justificationMissing,
    required int photoCountPolicyPending,
  }) {
    final pendings = <InspectionReviewPendingEntry>[];

    for (final status in checkinStatuses.where((item) => !item.isDone)) {
      pendings.add(
        InspectionReviewPendingEntry(
          id: 'checkin-${status.field.id}',
          title: status.field.titulo,
          reason: 'Falta foto obrigatória',
          ctaLabel: 'Ir para captura',
          target: InspectionReviewPendingActionTarget.capture,
          source: InspectionReviewPendingSource.normativeMatrix,
          subjectContext: status.field.evidenceContext,
          targetItem: status.field.evidenceTargetItem,
          targetQualifier: status.field.evidenceTargetQualifier,
        ),
      );
    }

    for (final item in items.where(
      (entry) => entry.status != InspectionReviewPhotoStatus.classified,
    )) {
      pendings.add(
        InspectionReviewPendingEntry(
          id: 'item-${item.filePath}',
          title: _occurrenceTitle(item),
          reason: 'Falta preenchimento',
          ctaLabel: 'Preencher',
          target: InspectionReviewPendingActionTarget.fill,
          source: InspectionReviewPendingSource.captureTree,
          subjectContext: item.macroLocal,
          targetItem: item.ambiente,
          targetQualifier: item.elemento,
          filePath: item.filePath,
        ),
      );
    }

    for (final rule in technicalSummary.pendingMatrix.items.where(
      (item) => item.isBlocking,
    )) {
      pendings.add(_pendingFromTechnicalRule(rule));
    }

    if (photoCountPolicyPending > 0) {
      pendings.add(
        InspectionReviewPendingEntry(
          id: 'photo-count-policy',
          title: 'Cobertura fotográfica',
          reason: photoCountPolicyPending == 1
              ? 'Falta 1 foto para a cobertura mínima'
              : 'Faltam $photoCountPolicyPending fotos para a cobertura mínima',
          ctaLabel: 'Ir para captura',
          target: InspectionReviewPendingActionTarget.capture,
          source: InspectionReviewPendingSource.captureTree,
        ),
      );
    }

    if (justificationMissing) {
      pendings.add(
        const InspectionReviewPendingEntry(
          id: 'closing-justification',
          title: 'Justificativa técnica',
          reason: 'Falta preenchimento',
          ctaLabel: 'Preencher',
          target: InspectionReviewPendingActionTarget.finalization,
          source: InspectionReviewPendingSource.finalization,
        ),
      );
    }

    final unique = <String, InspectionReviewPendingEntry>{};
    for (final entry in pendings) {
      unique.putIfAbsent(entry.id, () => entry);
    }
    final sorted = unique.values.toList(growable: false)
      ..sort((a, b) {
        final sourceDiff = _pendingSourceOrder(a.source)
            .compareTo(_pendingSourceOrder(b.source));
        if (sourceDiff != 0) return sourceDiff;
        return a.title.compareTo(b.title);
      });
    return sorted;
  }

  InspectionReviewPendingEntry _pendingFromTechnicalRule(
    TechnicalRuleResult rule,
  ) {
    return InspectionReviewPendingEntry(
      id: 'technical-${rule.id}',
      title: rule.title,
      reason: _reasonForTechnicalRule(rule),
      ctaLabel: _ctaForTechnicalRule(rule),
      target: _targetForTechnicalRule(rule),
      source: InspectionReviewPendingSource.technicalRule,
      targetItem: rule.subtipo,
      technicalRule: rule,
    );
  }

  InspectionReviewPendingActionTarget _targetForTechnicalRule(
    TechnicalRuleResult rule,
  ) {
    return switch (rule.stage) {
      TechnicalRuleStage.checkin => InspectionReviewPendingActionTarget.capture,
      TechnicalRuleStage.capture => InspectionReviewPendingActionTarget.capture,
      TechnicalRuleStage.review => InspectionReviewPendingActionTarget.fill,
      TechnicalRuleStage.finalization =>
        InspectionReviewPendingActionTarget.finalization,
    };
  }

  String _ctaForTechnicalRule(TechnicalRuleResult rule) {
    return switch (rule.stage) {
      TechnicalRuleStage.checkin => 'Ir para captura',
      TechnicalRuleStage.capture => 'Ir para captura',
      TechnicalRuleStage.review => 'Editar composição',
      TechnicalRuleStage.finalization => 'Preencher',
    };
  }

  String _reasonForTechnicalRule(TechnicalRuleResult rule) {
    final normalized = rule.description.trim().toLowerCase();
    if (normalized.contains('foto')) {
      return 'Falta foto obrigatória';
    }
    if (normalized.contains('classifica')) {
      return 'Ajuste a composição';
    }
    return 'Falta preenchimento';
  }

  int _pendingSourceOrder(InspectionReviewPendingSource source) {
    return switch (source) {
      InspectionReviewPendingSource.normativeMatrix => 0,
      InspectionReviewPendingSource.captureTree => 1,
      InspectionReviewPendingSource.technicalRule => 2,
      InspectionReviewPendingSource.finalization => 3,
    };
  }

  String _compositionKey(InspectionReviewEditableCapture item) {
    return [
      item.macroLocal?.trim() ?? '',
      item.ambienteBase?.trim() ?? '',
      item.ambiente.trim(),
      '${item.ambienteInstanceIndex ?? 1}',
      item.elemento?.trim() ?? '',
    ].join('|');
  }

  String _occurrenceTitle(InspectionReviewEditableCapture item) {
    final base = _hasText(item.ambienteBase) ? item.ambienteBase!.trim() : item.ambiente.trim();
    final index = item.ambienteInstanceIndex ?? 1;
    if (index <= 1) {
      return base;
    }
    return '$base $index';
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

