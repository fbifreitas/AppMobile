class TechnicalEvidenceInput {
  final String subtipo;
  final String? elemento;
  final String? material;
  final String? estado;
  final String? observacao;
  final String? filePath;
  final List<String> applicableClassificationLevels;

  const TechnicalEvidenceInput({
    required this.subtipo,
    this.elemento,
    this.material,
    this.estado,
    this.observacao,
    this.filePath,
    this.applicableClassificationLevels = const <String>[],
  });

  bool get hasElemento => elemento != null && elemento!.trim().isNotEmpty;
  bool get hasMaterial => material != null && material!.trim().isNotEmpty;
  bool get hasEstado => estado != null && estado!.trim().isNotEmpty;
  bool get requiresElemento =>
      applicableClassificationLevels.contains('elemento');
  bool get requiresMaterial =>
      applicableClassificationLevels.contains('material');
  bool get requiresEstado =>
      applicableClassificationLevels.contains('estado');
  bool get isFullyClassified =>
      (!requiresElemento || hasElemento) &&
      (!requiresMaterial || hasMaterial) &&
      (!requiresEstado || hasEstado);
}
