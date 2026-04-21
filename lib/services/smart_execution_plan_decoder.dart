import '../models/smart_execution_plan.dart';

class SmartExecutionPlanDecoder {
  const SmartExecutionPlanDecoder();

  static const SmartExecutionPlanDecoder instance = SmartExecutionPlanDecoder();

  SmartExecutionPlan? decodeEnvelope(
    Map<String, dynamic>? envelope, {
    String? fallbackJobId,
  }) {
    if (envelope == null || envelope.isEmpty) {
      return null;
    }

    final map = Map<String, dynamic>.from(
      envelope.map((key, value) => MapEntry(key, value)),
    );
    final plan = _extractMap(map['plan']) ?? const <String, dynamic>{};
    final propertyProfile =
        _extractMap(plan['propertyProfile']) ?? const <String, dynamic>{};
    final step1Config =
        _extractMap(plan['step1Config']) ?? const <String, dynamic>{};
    final step2Config =
        _extractMap(plan['step2Config']) ?? const <String, dynamic>{};
    final cameraConfig =
        _extractMap(plan['cameraConfig']) ?? const <String, dynamic>{};
    final requiredEvidence = step2Config['requiredEvidence'];
    final capturePlanItems = _extractCapturePlan(cameraConfig['capturePlan']);
    final suggestedPhotoLocations = _extractStringList(
      cameraConfig['suggestedPhotoLocations'] ??
          propertyProfile['availablePhotoLocations'],
    );
    final compositionProfiles = _extractCompositionProfiles(
      cameraConfig['compositionProfiles'],
    );
    final firstCapturePlan =
        capturePlanItems.isEmpty ? null : capturePlanItems.first;
    final jobId =
        _textOrNull(map['jobId']) ?? fallbackJobId?.trim() ?? '';

    if (jobId.isEmpty) {
      return null;
    }

    return SmartExecutionPlan(
      snapshotId: _intOrZero(map['snapshotId']),
      caseId: _intOrZero(map['caseId']),
      status: map['status']?.toString().trim() ?? 'UNKNOWN',
      jobId: jobId,
      propertyTaxonomy: _textOrNull(propertyProfile['taxonomy']),
      propertyLatitude: _doubleOrNull(
        propertyProfile['latitude'] ?? propertyProfile['propertyLatitude'],
      ),
      propertyLongitude: _doubleOrNull(
        propertyProfile['longitude'] ?? propertyProfile['propertyLongitude'],
      ),
      initialAssetType:
          _textOrNull(step1Config['initialAssetType']) ??
          _textOrNull(propertyProfile['canonicalAssetType']) ??
          _textOrNull(plan['assetType']),
      initialAssetSubtype:
          _textOrNull(step1Config['initialAssetSubtype']) ??
          _textOrNull(propertyProfile['canonicalAssetSubtype']) ??
          _textOrNull(plan['assetSubtype']),
      candidateAssetSubtypes: _extractStringList(
        step1Config['candidateAssetSubtypes'] ??
            propertyProfile['candidateAssetSubtypes'],
      ),
      refinedAssetSubtype:
          _textOrNull(propertyProfile['refinedAssetSubtype']) ??
          _textOrNull(plan['refinedAssetSubtype']),
      propertyStandard:
          _textOrNull(propertyProfile['propertyStandard']) ??
          _textOrNull(plan['propertyStandard']),
      initialContext: _textOrNull(step1Config['initialContext']),
      availableContexts: _extractStringList(step1Config['availableContexts']),
      cameraMode: _textOrNull(cameraConfig['mode']),
      availableMacroLocations: _extractStringList(
        cameraConfig['availableMacroLocations'],
      ),
      firstEnvironment: firstCapturePlan?.environment,
      firstElement: firstCapturePlan?.element,
      firstMaterial: firstCapturePlan?.material,
      firstCondition: firstCapturePlan?.condition,
      suggestedPhotoLocations: suggestedPhotoLocations,
      compositionProfiles: compositionProfiles,
      requiredEvidenceCount:
          requiredEvidence is List ? requiredEvidence.length : 0,
      requiresManualReview:
          _boolOrFalse(step2Config['mandatory']) ||
          _boolOrFalse(plan['requiresManualReview']),
      capturePlan: capturePlanItems,
      reviewReasons: _extractStringList(plan['reviewReasons']),
    );
  }

  List<String> _extractStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic>? _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, item) => MapEntry('$key', item)),
      );
    }
    return null;
  }

  List<SmartExecutionCapturePlanItem> _extractCapturePlan(Object? value) {
    if (value is! List) {
      return const <SmartExecutionCapturePlanItem>[];
    }

    final items = <SmartExecutionCapturePlanItem>[];
    for (final raw in value) {
      final map = _extractMap(raw);
      if (map == null) {
        continue;
      }
      items.add(
        SmartExecutionCapturePlanItem(
          macroLocal:
              _textOrNull(map['macroLocal']) ??
              _textOrNull(map['macro_location']) ??
              _textOrNull(map['macro_local']),
          environment:
              _textOrNull(map['environment']) ?? _textOrNull(map['ambiente']),
          element:
              _textOrNull(map['element']) ?? _textOrNull(map['elemento']),
          material:
              _textOrNull(map['material']) ??
              _textOrNull(map['inspection.material']),
          condition:
              _textOrNull(map['condition']) ?? _textOrNull(map['estado']),
          required: _boolOrFalse(map['required']),
          minPhotos: _intOrZero(map['minPhotos']),
          source: _textOrNull(map['source']),
          normativeBindings: _extractNormativeBindings(map['normativeBindings']),
        ),
      );
    }
    return items;
  }

  List<SmartExecutionCameraEnvironmentProfile> _extractCompositionProfiles(
    Object? value,
  ) {
    if (value is! List) {
      return const <SmartExecutionCameraEnvironmentProfile>[];
    }

    final profiles = <SmartExecutionCameraEnvironmentProfile>[];
    for (final raw in value) {
      final map = _extractMap(raw);
      if (map == null) continue;
      profiles.add(
        SmartExecutionCameraEnvironmentProfile(
          macroLocal:
              _textOrNull(map['macroLocal']) ??
              _textOrNull(map['macro_location']) ??
              _textOrNull(map['macro_local']) ??
              '',
          photoLocation:
              _textOrNull(map['photoLocation']) ??
              _textOrNull(map['environment']) ??
              _textOrNull(map['ambiente']) ??
              '',
          required: _boolOrFalse(map['required']),
          minPhotos: _intOrZero(map['minPhotos']),
          elements: _extractCompositionElements(map['elements']),
          source: _textOrNull(map['source']),
          normativeBindings: _extractNormativeBindings(map['normativeBindings']),
        ),
      );
    }
    return profiles
        .where(
          (profile) =>
              profile.macroLocal.trim().isNotEmpty &&
              profile.photoLocation.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  List<SmartExecutionCameraElementProfile> _extractCompositionElements(
    Object? value,
  ) {
    if (value is! List) {
      return const <SmartExecutionCameraElementProfile>[];
    }

    final elements = <SmartExecutionCameraElementProfile>[];
    for (final raw in value) {
      final map = _extractMap(raw);
      if (map == null) continue;
      final element =
          _textOrNull(map['element']) ?? _textOrNull(map['elemento']) ?? '';
      if (element.isEmpty) continue;
      elements.add(
        SmartExecutionCameraElementProfile(
          element: element,
          materials: _extractStringList(map['materials'] ?? map['materiais']),
          states: _extractStringList(map['states'] ?? map['estados']),
        ),
      );
    }
    return elements.toList(growable: false);
  }

  List<SmartExecutionNormativeBinding> _extractNormativeBindings(Object? value) {
    if (value is! List) {
      return const <SmartExecutionNormativeBinding>[];
    }

    final bindings = <SmartExecutionNormativeBinding>[];
    for (final raw in value) {
      final map = _extractMap(raw);
      if (map == null) continue;
      final dimension = _textOrNull(map['dimension']);
      final title = _textOrNull(map['title']);
      if (dimension == null || title == null) continue;
      bindings.add(
        SmartExecutionNormativeBinding(
          dimension: dimension,
          title: title,
          requiredWhenEnabled: _boolOrFalse(map['requiredWhenEnabled']),
          blockingOnFinalization: _boolOrFalse(map['blockingOnFinalization']),
          minPhotos: _intOrZero(map['minPhotos']),
          maxPhotos: _intOrNull(map['maxPhotos']),
          acceptedAlternatives: _extractStringList(map['acceptedAlternatives']),
        ),
      );
    }
    return bindings.toList(growable: false);
  }

  String? _textOrNull(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  int _intOrZero(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _intOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _doubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  bool _boolOrFalse(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }
}
