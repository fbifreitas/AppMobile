class InspectionMenuDocumentMergeResolver {
  const InspectionMenuDocumentMergeResolver();

  static const InspectionMenuDocumentMergeResolver instance =
      InspectionMenuDocumentMergeResolver();

  Map<String, dynamic>? merge({
    Map<String, dynamic>? base,
    Map<String, dynamic>? override,
  }) {
    if (base == null && override == null) return null;
    if (base == null) return Map<String, dynamic>.from(override!);
    if (override == null) return Map<String, dynamic>.from(base);

    final result = <String, dynamic>{};
    final keys = <String>{...base.keys, ...override.keys};

    for (final key in keys) {
      final baseValue = base[key];
      final overrideValue = override[key];

      if (baseValue is Map && overrideValue is Map) {
        result[key] = merge(
          base: Map<String, dynamic>.from(baseValue),
          override: Map<String, dynamic>.from(overrideValue),
        );
      } else if (override.containsKey(key)) {
        result[key] = overrideValue;
      } else {
        result[key] = baseValue;
      }
    }

    return result;
  }
}
