class InspectionCameraPresentationData {
  final String batchSummary;
  final bool canOpenChecklist;
  final bool showContextSuggestion;
  final bool showPredictionSuggestion;
  final bool showRecentAmbientes;
  final bool showRecentElementos;
  final String finalizeSubtitle;

  const InspectionCameraPresentationData({
    required this.batchSummary,
    required this.canOpenChecklist,
    required this.showContextSuggestion,
    required this.showPredictionSuggestion,
    required this.showRecentAmbientes,
    required this.showRecentElementos,
    required this.finalizeSubtitle,
  });
}

class InspectionCameraPresentationService {
  const InspectionCameraPresentationService();

  static const InspectionCameraPresentationService instance =
      InspectionCameraPresentationService();

  InspectionCameraPresentationData build({
    required int capturesCount,
    required bool hasPreviousPhotos,
    required bool hasSelectorAmbiente,
    required bool hasSelectorElemento,
    required bool hasMacroLocal,
    required bool hasAmbiente,
    required bool singleCaptureMode,
    required String? resumo,
    required String? contextSuggestionSummary,
    required String? predictionSummary,
    required List<String> recentAmbientes,
    required List<String> recentElementos,
    int requiredEvidenceCount = 0,
  }) {
    final hasAnyCaptures = capturesCount > 0 || hasPreviousPhotos;
    final trimmedResumo = resumo?.trim() ?? '';
    final evidenceTarget =
        requiredEvidenceCount > 0 ? requiredEvidenceCount : null;
    final normalizedCapturesCount = capturesCount < 0 ? 0 : capturesCount;
    final progressSummary =
        evidenceTarget == null
            ? '$capturesCount'
            : '$normalizedCapturesCount/$evidenceTarget';
    final batchSummary = StringBuffer('Capturas no lote: $progressSummary');
    if (trimmedResumo.isNotEmpty) {
      batchSummary.write(' • $trimmedResumo');
    }
    final finalizeSubtitle =
        evidenceTarget == null
            ? (capturesCount > 0 ? '$capturesCount nova(s)' : 'fotos anteriores')
            : '$normalizedCapturesCount de $evidenceTarget evidência(s)';

    return InspectionCameraPresentationData(
      batchSummary: batchSummary.toString(),
      canOpenChecklist: !singleCaptureMode && hasAnyCaptures,
      showContextSuggestion:
          contextSuggestionSummary != null &&
          contextSuggestionSummary.trim().isNotEmpty,
      showPredictionSuggestion:
          predictionSummary != null && predictionSummary.trim().isNotEmpty,
      showRecentAmbientes:
          hasSelectorAmbiente && recentAmbientes.isNotEmpty && hasMacroLocal,
      showRecentElementos:
          hasSelectorElemento && recentElementos.isNotEmpty && hasAmbiente,
      finalizeSubtitle: finalizeSubtitle,
    );
  }
}
