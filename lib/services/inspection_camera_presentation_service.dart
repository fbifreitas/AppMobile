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
  }) {
    final hasAnyCaptures = capturesCount > 0 || hasPreviousPhotos;
    final trimmedResumo = resumo?.trim() ?? '';

    return InspectionCameraPresentationData(
      batchSummary:
          'Capturas no lote: $capturesCount${trimmedResumo.isEmpty ? '' : ' • $trimmedResumo'}',
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
      finalizeSubtitle:
          capturesCount > 0 ? '$capturesCount nova(s)' : 'fotos anteriores',
    );
  }
}
