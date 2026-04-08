import 'flow_selection.dart';

/// Inspection-domain projection of [FlowSelection].
/// Used at inspection boundaries to expose domain field names
/// (macroLocal, ambiente, elemento, material, estado).
/// Canonical flow state uses [FlowSelection] — this model is adapter-only.
class InspectionCaptureContext {
  final String? macroLocal;
  final String? ambiente;
  final String? ambienteBase;
  final int? ambienteInstanceIndex;
  final String? elemento;
  final String? material;
  final String? estado;

  const InspectionCaptureContext({
    this.macroLocal,
    this.ambiente,
    this.ambienteBase,
    this.ambienteInstanceIndex,
    this.elemento,
    this.material,
    this.estado,
  });

  factory InspectionCaptureContext.canonical({
    String? subjectContext,
    String? targetItem,
    String? targetItemBase,
    int? targetItemInstanceIndex,
    String? targetQualifier,
    String? targetCondition,
    Map<String, dynamic> domainAttributes = const <String, dynamic>{},
  }) {
    return InspectionCaptureContext(
      macroLocal: subjectContext,
      ambiente: targetItem,
      ambienteBase: targetItemBase,
      ambienteInstanceIndex: targetItemInstanceIndex,
      elemento: targetQualifier,
      material: _attributeText(domainAttributes, 'inspection.material'),
      estado: targetCondition,
    );
  }

  bool get hasAnyValue =>
      _hasText(macroLocal) ||
      _hasText(ambiente) ||
      _hasText(elemento) ||
      _hasText(material) ||
      _hasText(estado);

  FlowSelection get selection => FlowSelection(
    subjectContext: macroLocal,
    targetItem: ambiente,
    targetItemBase: ambienteBase,
    targetItemInstanceIndex: ambienteInstanceIndex,
    targetQualifier: elemento,
    targetCondition: estado,
    domainAttributes: <String, dynamic>{
      if (_hasText(material)) 'inspection.material': material,
    },
  );

  factory InspectionCaptureContext.fromMap(Map<String, dynamic> map) {
    final selection = FlowSelection.fromMap(map);
    return InspectionCaptureContext.canonical(
      subjectContext: selection.subjectContext,
      targetItem: selection.targetItem,
      targetItemBase: selection.targetItemBase,
      targetItemInstanceIndex: selection.targetItemInstanceIndex,
      targetQualifier: selection.targetQualifier,
      targetCondition: selection.targetCondition,
      domainAttributes: selection.domainAttributes,
    );
  }

  static String? _attributeText(Map<String, dynamic> attributes, String key) {
    final value = attributes[key];
    return _readText(value);
  }

  static String? _readText(Object? value) {
    final text = '$value'.trim();
    if (value == null || text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
