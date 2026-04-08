class FlowSelection {
  final String? subjectContext;
  final String? targetItem;
  final String? targetItemBase;
  final int? targetItemInstanceIndex;
  final String? targetQualifier;
  final String? targetCondition;
  final Map<String, dynamic> domainAttributes;

  const FlowSelection({
    this.subjectContext,
    this.targetItem,
    this.targetItemBase,
    this.targetItemInstanceIndex,
    this.targetQualifier,
    this.targetCondition,
    this.domainAttributes = const <String, dynamic>{},
  });

  static const FlowSelection empty = FlowSelection();

  bool get hasAnyValue =>
      _hasText(subjectContext) ||
      _hasText(targetItem) ||
      _hasText(targetQualifier) ||
      _hasText(targetCondition) ||
      domainAttributes.values.any((value) => _hasText('$value'));

  String? attributeText(String key) => _readText(domainAttributes[key]);

  FlowSelection copyWith({
    String? subjectContext,
    String? targetItem,
    String? targetItemBase,
    int? targetItemInstanceIndex,
    String? targetQualifier,
    String? targetCondition,
    Map<String, dynamic>? domainAttributes,
    bool clearSubjectContext = false,
    bool clearTargetItem = false,
    bool clearTargetItemBase = false,
    bool clearTargetItemInstanceIndex = false,
    bool clearTargetQualifier = false,
    bool clearTargetCondition = false,
    bool clearDomainAttributes = false,
  }) {
    return FlowSelection(
      subjectContext:
          clearSubjectContext ? null : (subjectContext ?? this.subjectContext),
      targetItem: clearTargetItem ? null : (targetItem ?? this.targetItem),
      targetItemBase:
          clearTargetItemBase ? null : (targetItemBase ?? this.targetItemBase),
      targetItemInstanceIndex:
          clearTargetItemInstanceIndex
              ? null
              : (targetItemInstanceIndex ?? this.targetItemInstanceIndex),
      targetQualifier:
          clearTargetQualifier
              ? null
              : (targetQualifier ?? this.targetQualifier),
      targetCondition:
          clearTargetCondition
              ? null
              : (targetCondition ?? this.targetCondition),
      domainAttributes:
          clearDomainAttributes
              ? const <String, dynamic>{}
              : Map<String, dynamic>.unmodifiable(
                domainAttributes ?? this.domainAttributes,
              ),
    );
  }

  Map<String, dynamic> toMap({
    bool includeCanonical = true,
    bool includeLegacy = false,
  }) {
    final map = <String, dynamic>{};
    if (includeCanonical) {
      if (_hasText(subjectContext)) {
        map['subjectContext'] = subjectContext;
      }
      if (_hasText(targetItem)) {
        map['targetItem'] = targetItem;
      }
      if (_hasText(targetItemBase)) {
        map['targetItemBase'] = targetItemBase;
      }
      if (targetItemInstanceIndex != null) {
        map['targetItemInstanceIndex'] = targetItemInstanceIndex;
      }
      if (_hasText(targetQualifier)) {
        map['targetQualifier'] = targetQualifier;
      }
      if (_hasText(targetCondition)) {
        map['targetCondition'] = targetCondition;
      }
      if (domainAttributes.isNotEmpty) {
        map['domainAttributes'] = Map<String, dynamic>.from(domainAttributes);
      }
    }
    if (includeLegacy) {
      if (_hasText(subjectContext)) {
        map['macroLocal'] = subjectContext;
      }
      if (_hasText(targetItem)) {
        map['ambiente'] = targetItem;
      }
      if (_hasText(targetItemBase)) {
        map['ambienteBase'] = targetItemBase;
      }
      if (targetItemInstanceIndex != null) {
        map['ambienteInstanceIndex'] = targetItemInstanceIndex;
      }
      if (_hasText(targetQualifier)) {
        map['elemento'] = targetQualifier;
      }
      final material = attributeText('inspection.material');
      if (_hasText(material)) {
        map['material'] = material;
      }
      if (_hasText(targetCondition)) {
        map['estado'] = targetCondition;
      }
    }
    return map;
  }

  factory FlowSelection.fromMap(Map<String, dynamic> map) {
    final inheritedAttributes = <String, dynamic>{
      if (map['domainAttributes'] is Map)
        ...Map<String, dynamic>.from(
          (map['domainAttributes'] as Map).map(
            (key, value) => MapEntry('$key', value),
          ),
        ),
    };
    final material = _readText(map['material']);
    if (material != null && !inheritedAttributes.containsKey('inspection.material')) {
      inheritedAttributes['inspection.material'] = material;
    }

    return FlowSelection(
      subjectContext: _readText(map['subjectContext']) ?? _readText(map['macroLocal']),
      targetItem: _readText(map['targetItem']) ?? _readText(map['ambiente']),
      targetItemBase:
          _readText(map['targetItemBase']) ?? _readText(map['ambienteBase']),
      targetItemInstanceIndex:
          (map['targetItemInstanceIndex'] as num?)?.toInt() ??
          int.tryParse('${map['targetItemInstanceIndex'] ?? ''}') ??
          (map['ambienteInstanceIndex'] as num?)?.toInt() ??
          int.tryParse('${map['ambienteInstanceIndex'] ?? ''}'),
      targetQualifier:
          _readText(map['targetQualifier']) ?? _readText(map['elemento']),
      targetCondition:
          _readText(map['targetCondition']) ?? _readText(map['estado']),
      domainAttributes: Map<String, dynamic>.unmodifiable(inheritedAttributes),
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

class FlowSelectionState {
  final FlowSelection initialSuggestedSelection;
  final FlowSelection currentSelection;
  final FlowSelection? resumeSelection;

  const FlowSelectionState({
    required this.initialSuggestedSelection,
    required this.currentSelection,
    this.resumeSelection,
  });

  factory FlowSelectionState.bootstrap({
    String? subjectContext,
    String? targetItem,
    String? targetQualifier,
    String? targetCondition,
    Map<String, dynamic>? domainAttributes,
  }) {
    final initial = FlowSelection(
      subjectContext: subjectContext,
      targetItem: targetItem,
      targetQualifier: targetQualifier,
      targetCondition: targetCondition,
      domainAttributes: Map<String, dynamic>.unmodifiable(
        domainAttributes ?? const <String, dynamic>{},
      ),
    );
    return FlowSelectionState(
      initialSuggestedSelection: initial,
      currentSelection: initial,
    );
  }

  FlowSelectionState copyWith({
    FlowSelection? initialSuggestedSelection,
    FlowSelection? currentSelection,
    FlowSelection? resumeSelection,
    bool clearResumeSelection = false,
  }) {
    return FlowSelectionState(
      initialSuggestedSelection:
          initialSuggestedSelection ?? this.initialSuggestedSelection,
      currentSelection: currentSelection ?? this.currentSelection,
      resumeSelection:
          clearResumeSelection ? null : (resumeSelection ?? this.resumeSelection),
    );
  }
}
