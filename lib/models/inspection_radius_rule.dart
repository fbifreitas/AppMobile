class InspectionRadiusRule {
  const InspectionRadiusRule({
    required this.tipoImovel,
    this.subtipoImovel,
    required this.radiusMeters,
    required this.label,
  });

  final String tipoImovel;
  final String? subtipoImovel;
  final double radiusMeters;
  final String label;
}
