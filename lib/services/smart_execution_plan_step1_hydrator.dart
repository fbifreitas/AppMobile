import '../models/smart_execution_plan.dart';

class SmartExecutionPlanStep1Hydrator {
  const SmartExecutionPlanStep1Hydrator();

  static const SmartExecutionPlanStep1Hydrator instance =
      SmartExecutionPlanStep1Hydrator();

  SmartStep1Hydration? resolve({
    required SmartExecutionPlan? plan,
    required List<String> availableAssetTypes,
    required Map<String, List<String>> availableSubtypesByType,
    required List<String> availableContexts,
    String? fallbackAssetType,
    String? fallbackAssetSubtype,
    String? fallbackContext,
  }) {
    if (plan == null) {
      return null;
    }

    final resolvedAvailableContexts =
        plan.availableContexts.isNotEmpty ? plan.availableContexts : availableContexts;

    final assetType =
        _resolveAssetType(plan.initialAssetType, availableAssetTypes) ??
        _normalizeText(fallbackAssetType);
    final candidateAssetSubtypes = _resolveCandidateAssetSubtypes(
      rawCandidates: plan.candidateAssetSubtypes,
      resolvedAssetType: assetType,
      availableSubtypesByType: availableSubtypesByType,
    );
    final assetSubtype =
        (candidateAssetSubtypes.length == 1
            ? candidateAssetSubtypes.first
            : _resolveAssetSubtype(
                  rawAssetSubtype:
                      plan.initialAssetSubtype ?? plan.refinedAssetSubtype,
                  resolvedAssetType: assetType,
                  availableSubtypesByType: availableSubtypesByType,
                )) ??
        _normalizeText(fallbackAssetSubtype);
    final context =
        _resolveContext(plan.initialContext, resolvedAvailableContexts) ??
        _normalizeText(fallbackContext);

    if (assetType == null && assetSubtype == null && context == null) {
      return null;
    }

    return SmartStep1Hydration(
      assetType: assetType,
      assetSubtype: assetSubtype,
      candidateAssetSubtypes: candidateAssetSubtypes,
      context: context,
      contactPresent: true,
    );
  }

  List<String> _resolveCandidateAssetSubtypes({
    required List<String> rawCandidates,
    required String? resolvedAssetType,
    required Map<String, List<String>> availableSubtypesByType,
  }) {
    if (resolvedAssetType == null) {
      return const <String>[];
    }
    final availableSubtypes =
        availableSubtypesByType[resolvedAssetType] ?? const <String>[];
    if (availableSubtypes.isEmpty) {
      return const <String>[];
    }

    final resolved = <String>[];
    for (final raw in rawCandidates) {
      final candidate =
          _resolveAssetSubtype(
            rawAssetSubtype: raw,
            resolvedAssetType: resolvedAssetType,
            availableSubtypesByType: availableSubtypesByType,
          ) ??
          _canonicalizeSubtype(_normalizeText(raw), resolvedAssetType);
      if (candidate != null && !resolved.contains(candidate)) {
        resolved.add(candidate);
      }
    }
    return resolved;
  }

  String? _resolveAssetType(String? rawAssetType, List<String> availableTypes) {
    final normalized = _normalizeText(rawAssetType);
    if (normalized == null) return null;

    final directMatch = availableTypes.cast<String?>().firstWhere(
      (value) => value?.trim().toLowerCase() == normalized.toLowerCase(),
      orElse: () => null,
    );
    if (directMatch != null) {
      return directMatch;
    }

    switch (normalized.toUpperCase()) {
      case 'RESIDENTIAL':
        return availableTypes.contains('Urbano') ? 'Urbano' : null;
      case 'COMMERCIAL':
        return availableTypes.contains('Comercial') ? 'Comercial' : null;
      case 'INDUSTRIAL':
        return availableTypes.contains('Industrial') ? 'Industrial' : null;
      case 'RURAL':
        return availableTypes.contains('Rural') ? 'Rural' : null;
      default:
        return null;
    }
  }

  String? _resolveAssetSubtype({
    required String? rawAssetSubtype,
    required String? resolvedAssetType,
    required Map<String, List<String>> availableSubtypesByType,
  }) {
    final normalized = _normalizeText(rawAssetSubtype);
    if (normalized == null || resolvedAssetType == null) return null;

    final availableSubtypes =
        availableSubtypesByType[resolvedAssetType] ?? const <String>[];
    if (availableSubtypes.isEmpty) {
      return null;
    }

    final directMatch = availableSubtypes.cast<String?>().firstWhere(
      (value) => value?.trim().toLowerCase() == normalized.toLowerCase(),
      orElse: () => null,
    );
    if (directMatch != null) {
      return directMatch;
    }

    final normalizedSubtype = normalized.toLowerCase();
    if (normalizedSubtype.contains('apart')) {
      return _containsSubtype(availableSubtypes, 'Apartamento');
    }
    if (normalizedSubtype.contains('sobrado')) {
      return _containsSubtype(availableSubtypes, 'Sobrado');
    }
    if (normalizedSubtype.contains('casa')) {
      return _containsSubtype(availableSubtypes, 'Casa');
    }
    if (normalizedSubtype.contains('terreno')) {
      return _containsSubtype(availableSubtypes, 'Terreno');
    }
    if (normalizedSubtype.contains('sitio') ||
        normalizedSubtype.contains('sítio')) {
      return _containsSubtype(availableSubtypes, 'Sitio') ??
          _containsSubtype(availableSubtypes, 'Sítio');
    }
    if (normalizedSubtype.contains('chacara') ||
        normalizedSubtype.contains('chácara')) {
      return _containsSubtype(availableSubtypes, 'Chacara') ??
          _containsSubtype(availableSubtypes, 'Chácara');
    }
    if (normalizedSubtype.contains('fazenda')) {
      return _containsSubtype(availableSubtypes, 'Fazenda');
    }
    if (normalizedSubtype.contains('loja')) {
      return _containsSubtype(availableSubtypes, 'Loja');
    }
    if (normalizedSubtype.contains('sala')) {
      return _containsSubtype(availableSubtypes, 'Sala comercial');
    }
    if (normalizedSubtype.contains('galp')) {
      return _containsSubtype(availableSubtypes, 'Galpao') ??
          _containsSubtype(availableSubtypes, 'Galpão');
    }
    return _canonicalizeSubtype(normalizedSubtype, resolvedAssetType);
  }

  String? _containsSubtype(List<String> availableSubtypes, String expected) {
    return availableSubtypes.cast<String?>().firstWhere(
      (value) => value?.trim().toLowerCase() == expected.toLowerCase(),
      orElse: () => null,
    );
  }

  String? _canonicalizeSubtype(String? normalizedSubtype, String? assetType) {
    if (normalizedSubtype == null || normalizedSubtype.isEmpty) {
      return null;
    }

    if (normalizedSubtype.contains('triplex')) {
      return 'Triplex';
    }
    if (normalizedSubtype.contains('duplex')) {
      return 'Duplex';
    }
    if (normalizedSubtype.contains('alto padrao') ||
        normalizedSubtype.contains('alto padrão')) {
      return 'Apartamento alto padrao';
    }
    if (normalizedSubtype.contains('apartamento padrao') ||
        normalizedSubtype.contains('apartamento padrão')) {
      return 'Apartamento padrao';
    }
    if (normalizedSubtype.contains('apart')) {
      return 'Apartamento';
    }
    if (normalizedSubtype.contains('sobrado')) {
      return 'Sobrado';
    }
    if (normalizedSubtype.contains('casa geminada') ||
        normalizedSubtype.contains('casa')) {
      return 'Casa';
    }
    if (normalizedSubtype.contains('terreno') ||
        normalizedSubtype.contains('lote')) {
      return 'Terreno';
    }
    if (normalizedSubtype.contains('sitio') ||
        normalizedSubtype.contains('sÃ­tio')) {
      return 'Sitio';
    }
    if (normalizedSubtype.contains('chacara') ||
        normalizedSubtype.contains('chÃ¡cara')) {
      return 'Chacara';
    }
    if (normalizedSubtype.contains('fazenda')) {
      return 'Fazenda';
    }
    if (normalizedSubtype.contains('loja')) {
      return 'Loja';
    }
    if (normalizedSubtype.contains('sala')) {
      return 'Sala comercial';
    }
    if (normalizedSubtype.contains('galp')) {
      return 'Galpao';
    }
    return assetType == 'Urbano' ? _titleCase(normalizedSubtype) : null;
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .map(
          (item) =>
              '${item.substring(0, 1).toUpperCase()}${item.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String? _resolveContext(String? rawContext, List<String> availableContexts) {
    final normalized = _normalizeText(rawContext);
    if (normalized == null) return null;

    final directMatch = availableContexts.cast<String?>().firstWhere(
      (value) => value?.trim().toLowerCase() == normalized.toLowerCase(),
      orElse: () => null,
    );
    if (directMatch != null) {
      return directMatch;
    }

    switch (normalized.toLowerCase()) {
      case 'street':
        return availableContexts.contains('Rua') ? 'Rua' : null;
      case 'external area':
        return availableContexts.contains('Area externa')
            ? 'Area externa'
            : (availableContexts.contains('Ãrea externa')
                ? 'Ãrea externa'
                : null);
      case 'internal area':
        return availableContexts.contains('Area interna')
            ? 'Area interna'
            : (availableContexts.contains('Ãrea interna')
                ? 'Ãrea interna'
                : null);
      default:
        return null;
    }
  }

  String? _normalizeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

class SmartStep1Hydration {
  const SmartStep1Hydration({
    required this.assetType,
    required this.assetSubtype,
    required this.candidateAssetSubtypes,
    required this.context,
    required this.contactPresent,
  });

  final String? assetType;
  final String? assetSubtype;
  final List<String> candidateAssetSubtypes;
  final String? context;
  final bool contactPresent;
}
