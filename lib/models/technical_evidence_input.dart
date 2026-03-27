class TechnicalEvidenceInput {
  final String subtipo;
  final String? elemento;
  final String? material;
  final String? estado;
  final String? observacao;
  final String? filePath;

  const TechnicalEvidenceInput({
    required this.subtipo,
    this.elemento,
    this.material,
    this.estado,
    this.observacao,
    this.filePath,
  });

  bool get hasElemento => elemento != null && elemento!.trim().isNotEmpty;
  bool get hasMaterial => material != null && material!.trim().isNotEmpty;
  bool get hasEstado => estado != null && estado!.trim().isNotEmpty;
  bool get isFullyClassified => hasElemento && hasMaterial && hasEstado;
}
