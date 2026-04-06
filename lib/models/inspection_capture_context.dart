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

  static const InspectionCaptureContext empty = InspectionCaptureContext();

  bool get hasAnyValue =>
      _hasText(macroLocal) ||
      _hasText(ambiente) ||
      _hasText(elemento) ||
      _hasText(material) ||
      _hasText(estado);

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
    return <String, dynamic>{
      if (_hasText(macroLocal)) 'macroLocal': macroLocal,
      if (_hasText(ambiente)) 'ambiente': ambiente,
      if (_hasText(ambienteBase)) 'ambienteBase': ambienteBase,
      if (ambienteInstanceIndex != null)
        'ambienteInstanceIndex': ambienteInstanceIndex,
      if (_hasText(elemento)) 'elemento': elemento,
      if (_hasText(material)) 'material': material,
      if (_hasText(estado)) 'estado': estado,
    };
  }

  factory InspectionCaptureContext.fromMap(Map<String, dynamic> map) {
    return InspectionCaptureContext(
      macroLocal: _readText(map['macroLocal']),
      ambiente: _readText(map['ambiente']),
      ambienteBase: _readText(map['ambienteBase']),
      ambienteInstanceIndex:
          (map['ambienteInstanceIndex'] as num?)?.toInt() ??
          int.tryParse('${map['ambienteInstanceIndex'] ?? ''}'),
      elemento: _readText(map['elemento']),
      material: _readText(map['material']),
      estado: _readText(map['estado']),
    );
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
}
