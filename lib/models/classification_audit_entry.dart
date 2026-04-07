class ClassificationAuditEntry {
  final String subtipo;
  final int totalFotos;
  final int fullyClassified;
  final int missingElemento;
  final int missingMaterial;
  final int missingEstado;

  const ClassificationAuditEntry({
    required this.subtipo,
    required this.totalFotos,
    required this.fullyClassified,
    required this.missingElemento,
    required this.missingMaterial,
    required this.missingEstado,
  });

  bool get hasIssues =>
      missingElemento > 0 || missingMaterial > 0 || missingEstado > 0;

  double get completenessPercent {
    if (totalFotos == 0) return 0;
    return fullyClassified / totalFotos;
  }
}
