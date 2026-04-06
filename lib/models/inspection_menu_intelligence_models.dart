class PredictedSelection {
  final String? elemento;
  final String? material;
  final String? estado;
  final int captures;

  const PredictedSelection({
    this.elemento,
    this.material,
    this.estado,
    required this.captures,
  });

  bool get hasAnyValue =>
      (elemento != null && elemento!.trim().isNotEmpty) ||
      (material != null && material!.trim().isNotEmpty) ||
      (estado != null && estado!.trim().isNotEmpty);
}

class SuggestedCameraContext {
  final String? macroLocal;
  final String? ambiente;
  final int confidenceSignals;

  const SuggestedCameraContext({
    this.macroLocal,
    this.ambiente,
    required this.confidenceSignals,
  });

  bool get hasValue =>
      (macroLocal != null && macroLocal!.trim().isNotEmpty) ||
      (ambiente != null && ambiente!.trim().isNotEmpty);
}
