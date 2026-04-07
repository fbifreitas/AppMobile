import 'flow_selection.dart';

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

  String get targetItem => subtipo;
  String? get targetQualifier => elemento;
  String? get targetCondition => estado;
  bool get hasTargetQualifier => hasElemento;
  bool get hasTargetCondition => hasEstado;
  Map<String, dynamic> get domainAttributes => <String, dynamic>{
    if (hasMaterial) 'inspection.material': material,
  };

  FlowSelection get selection => FlowSelection(
    targetItem: targetItem,
    targetQualifier: targetQualifier,
    targetCondition: targetCondition,
    domainAttributes: domainAttributes,
  );
}
