import 'flow_selection.dart';

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

  static const InspectionCaptureContext empty = InspectionCaptureContext();

  String? get subjectContext => macroLocal;
  String? get targetItem => ambiente;
  String? get targetItemBase => ambienteBase;
  int? get targetItemInstanceIndex => ambienteInstanceIndex;
  String? get targetQualifier => elemento;
  String? get targetCondition => estado;
  Map<String, dynamic> get domainAttributes => <String, dynamic>{
    if (_hasText(material)) 'inspection.material': material,
  };

  bool get hasAnyValue =>
      _hasText(macroLocal) ||
      _hasText(ambiente) ||
      _hasText(elemento) ||
      _hasText(material) ||
      _hasText(estado);

  FlowSelection get selection => FlowSelection(
    subjectContext: subjectContext,
    targetItem: targetItem,
    targetItemBase: targetItemBase,
    targetItemInstanceIndex: targetItemInstanceIndex,
    targetQualifier: targetQualifier,
    targetCondition: targetCondition,
    domainAttributes: domainAttributes,
  );

  InspectionCaptureContext copyWith({
    String? macroLocal,
    String? ambiente,
    String? ambienteBase,
    int? ambienteInstanceIndex,
    String? elemento,
    String? material,
    String? estado,
    bool clearMacroLocal = false,
    bool clearAmbiente = false,
    bool clearAmbienteBase = false,
    bool clearAmbienteInstanceIndex = false,
    bool clearElemento = false,
    bool clearMaterial = false,
    bool clearEstado = false,
  }) {
    return InspectionCaptureContext(
      macroLocal: clearMacroLocal ? null : (macroLocal ?? this.macroLocal),
      ambiente: clearAmbiente ? null : (ambiente ?? this.ambiente),
      ambienteBase:
          clearAmbienteBase ? null : (ambienteBase ?? this.ambienteBase),
      ambienteInstanceIndex:
          clearAmbienteInstanceIndex
              ? null
              : (ambienteInstanceIndex ?? this.ambienteInstanceIndex),
      elemento: clearElemento ? null : (elemento ?? this.elemento),
      material: clearMaterial ? null : (material ?? this.material),
      estado: clearEstado ? null : (estado ?? this.estado),
    );
  }

  Map<String, dynamic> toMap() {
    return selection.toMap(includeCanonical: true, includeLegacy: true);
  }

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

class InspectionCaptureFlowState {
  final InspectionCaptureContext initialSuggested;
  final InspectionCaptureContext current;
  final InspectionCaptureContext? resume;

  const InspectionCaptureFlowState({
    required this.initialSuggested,
    required this.current,
    this.resume,
  });

  factory InspectionCaptureFlowState.bootstrap({
    String? macroLocal,
    String? ambiente,
    String? elemento,
    String? material,
    String? estado,
  }) {
    final initial = InspectionCaptureContext(
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
      material: material,
      estado: estado,
    );
    return InspectionCaptureFlowState(
      initialSuggested: initial,
      current: initial,
    );
  }

  FlowSelectionState get canonical => FlowSelectionState(
    initialSuggestedSelection: initialSuggested.selection,
    currentSelection: current.selection,
    resumeSelection: resume?.selection,
  );

  InspectionCaptureFlowState copyWith({
    InspectionCaptureContext? initialSuggested,
    InspectionCaptureContext? current,
    InspectionCaptureContext? resume,
    bool clearResume = false,
  }) {
    return InspectionCaptureFlowState(
      initialSuggested: initialSuggested ?? this.initialSuggested,
      current: current ?? this.current,
      resume: clearResume ? null : (resume ?? this.resume),
    );
  }

  factory InspectionCaptureFlowState.fromCanonical(FlowSelectionState state) {
    return InspectionCaptureFlowState(
      initialSuggested: InspectionCaptureContext.canonical(
        subjectContext: state.initialSuggestedSelection.subjectContext,
        targetItem: state.initialSuggestedSelection.targetItem,
        targetItemBase: state.initialSuggestedSelection.targetItemBase,
        targetItemInstanceIndex:
            state.initialSuggestedSelection.targetItemInstanceIndex,
        targetQualifier: state.initialSuggestedSelection.targetQualifier,
        targetCondition: state.initialSuggestedSelection.targetCondition,
        domainAttributes: state.initialSuggestedSelection.domainAttributes,
      ),
      current: InspectionCaptureContext.canonical(
        subjectContext: state.currentSelection.subjectContext,
        targetItem: state.currentSelection.targetItem,
        targetItemBase: state.currentSelection.targetItemBase,
        targetItemInstanceIndex: state.currentSelection.targetItemInstanceIndex,
        targetQualifier: state.currentSelection.targetQualifier,
        targetCondition: state.currentSelection.targetCondition,
        domainAttributes: state.currentSelection.domainAttributes,
      ),
      resume:
          state.resumeSelection == null
              ? null
              : InspectionCaptureContext.canonical(
                subjectContext: state.resumeSelection!.subjectContext,
                targetItem: state.resumeSelection!.targetItem,
                targetItemBase: state.resumeSelection!.targetItemBase,
                targetItemInstanceIndex:
                    state.resumeSelection!.targetItemInstanceIndex,
                targetQualifier: state.resumeSelection!.targetQualifier,
                targetCondition: state.resumeSelection!.targetCondition,
                domainAttributes: state.resumeSelection!.domainAttributes,
              ),
    );
  }
}
