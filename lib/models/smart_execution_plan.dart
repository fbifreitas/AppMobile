class SmartExecutionPlan {
  const SmartExecutionPlan({
    required this.snapshotId,
    required this.caseId,
    required this.status,
    required this.jobId,
    this.propertyTaxonomy,
    this.propertyLatitude,
    this.propertyLongitude,
    this.initialAssetType,
    this.initialAssetSubtype,
    this.candidateAssetSubtypes = const <String>[],
    this.refinedAssetSubtype,
    this.propertyStandard,
    this.initialContext,
    this.availableContexts = const <String>[],
    this.cameraMode,
    this.availableMacroLocations = const <String>[],
    this.firstEnvironment,
    this.firstElement,
    this.firstMaterial,
    this.firstCondition,
    this.suggestedPhotoLocations = const <String>[],
    this.compositionProfiles = const <SmartExecutionCameraEnvironmentProfile>[],
    this.requiredEvidenceCount = 0,
    this.requiresManualReview = false,
    this.capturePlan = const <SmartExecutionCapturePlanItem>[],
    this.reviewReasons = const <String>[],
  });

  final int snapshotId;
  final int caseId;
  final String status;
  final String jobId;
  final String? propertyTaxonomy;
  final double? propertyLatitude;
  final double? propertyLongitude;
  final String? initialAssetType;
  final String? initialAssetSubtype;
  final List<String> candidateAssetSubtypes;
  final String? refinedAssetSubtype;
  final String? propertyStandard;
  final String? initialContext;
  final List<String> availableContexts;
  final String? cameraMode;
  final List<String> availableMacroLocations;
  final String? firstEnvironment;
  final String? firstElement;
  final String? firstMaterial;
  final String? firstCondition;
  final List<String> suggestedPhotoLocations;
  final List<SmartExecutionCameraEnvironmentProfile> compositionProfiles;
  final int requiredEvidenceCount;
  final bool requiresManualReview;
  final List<SmartExecutionCapturePlanItem> capturePlan;
  final List<String> reviewReasons;

  SmartExecutionCapturePlanItem? get firstRequiredCapturePlanItem {
    for (final item in capturePlan) {
      if (item.required) {
        return item;
      }
    }
    return capturePlan.isEmpty ? null : capturePlan.first;
  }

  Map<String, dynamic> toEnvelopeMap() {
    return <String, dynamic>{
      'snapshotId': snapshotId,
      'caseId': caseId,
      'jobId': jobId,
      'status': status,
      'plan': <String, dynamic>{
        'status': status,
        'requiresManualReview': requiresManualReview,
        'reviewReasons': reviewReasons,
        'assetType': initialAssetType,
        'assetSubtype': initialAssetSubtype,
        'refinedAssetSubtype': refinedAssetSubtype,
        'propertyStandard': propertyStandard,
        'propertyProfile': <String, dynamic>{
          'taxonomy': propertyTaxonomy,
          'latitude': propertyLatitude,
          'longitude': propertyLongitude,
          'canonicalAssetType': initialAssetType,
          'canonicalAssetSubtype': initialAssetSubtype,
          'refinedAssetSubtype': refinedAssetSubtype,
          'propertyStandard': propertyStandard,
          'availablePhotoLocations': suggestedPhotoLocations,
          'candidateAssetSubtypes': candidateAssetSubtypes,
        },
        'step1Config': <String, dynamic>{
          'initialAssetType': initialAssetType,
          'initialAssetSubtype': initialAssetSubtype,
          'candidateAssetSubtypes': candidateAssetSubtypes,
          'initialContext': initialContext,
          'availableContexts': availableContexts,
        },
        'cameraConfig': <String, dynamic>{
          'mode': cameraMode,
          'availableMacroLocations': availableMacroLocations,
          'suggestedPhotoLocations': suggestedPhotoLocations,
          'compositionProfiles': compositionProfiles.map((item) => item.toMap()).toList(),
          'capturePlan': capturePlan.map((item) => item.toMap()).toList(),
        },
        'step2Config': <String, dynamic>{
          'mandatory': requiresManualReview,
          'requiredEvidence': List<int>.filled(requiredEvidenceCount, 1),
        },
      },
    };
  }
}

class SmartExecutionCameraEnvironmentProfile {
  const SmartExecutionCameraEnvironmentProfile({
    required this.macroLocal,
    required this.photoLocation,
    required this.required,
    required this.minPhotos,
    this.elements = const <SmartExecutionCameraElementProfile>[],
    this.source,
    this.normativeBindings = const <SmartExecutionNormativeBinding>[],
  });

  final String macroLocal;
  final String photoLocation;
  final bool required;
  final int minPhotos;
  final List<SmartExecutionCameraElementProfile> elements;
  final String? source;
  final List<SmartExecutionNormativeBinding> normativeBindings;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'macroLocal': macroLocal,
      'photoLocation': photoLocation,
      'required': required,
      'minPhotos': minPhotos,
      'elements': elements.map((item) => item.toMap()).toList(),
      if (source != null) 'source': source,
      if (normativeBindings.isNotEmpty)
        'normativeBindings': normativeBindings.map((item) => item.toMap()).toList(),
    };
  }
}

class SmartExecutionCameraElementProfile {
  const SmartExecutionCameraElementProfile({
    required this.element,
    this.materials = const <String>[],
    this.states = const <String>[],
  });

  final String element;
  final List<String> materials;
  final List<String> states;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'element': element,
      'materials': materials,
      'states': states,
    };
  }
}

class SmartExecutionCapturePlanItem {
  const SmartExecutionCapturePlanItem({
    this.macroLocal,
    this.environment,
    this.element,
    this.material,
    this.condition,
    this.required = false,
    this.minPhotos = 0,
    this.source,
    this.normativeBindings = const <SmartExecutionNormativeBinding>[],
  });

  final String? macroLocal;
  final String? environment;
  final String? element;
  final String? material;
  final String? condition;
  final bool required;
  final int minPhotos;
  final String? source;
  final List<SmartExecutionNormativeBinding> normativeBindings;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (macroLocal != null) 'macroLocal': macroLocal,
      if (environment != null) 'environment': environment,
      if (element != null) 'element': element,
      if (material != null) 'material': material,
      if (condition != null) 'condition': condition,
      'required': required,
      'minPhotos': minPhotos,
      if (source != null) 'source': source,
      if (normativeBindings.isNotEmpty)
        'normativeBindings': normativeBindings.map((item) => item.toMap()).toList(),
    };
  }
}

class SmartExecutionNormativeBinding {
  const SmartExecutionNormativeBinding({
    required this.dimension,
    required this.title,
    this.requiredWhenEnabled = false,
    this.blockingOnFinalization = false,
    this.minPhotos = 0,
    this.maxPhotos,
    this.acceptedAlternatives = const <String>[],
  });

  final String dimension;
  final String title;
  final bool requiredWhenEnabled;
  final bool blockingOnFinalization;
  final int minPhotos;
  final int? maxPhotos;
  final List<String> acceptedAlternatives;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dimension': dimension,
      'title': title,
      'requiredWhenEnabled': requiredWhenEnabled,
      'blockingOnFinalization': blockingOnFinalization,
      'minPhotos': minPhotos,
      if (maxPhotos != null) 'maxPhotos': maxPhotos,
      'acceptedAlternatives': acceptedAlternatives,
    };
  }
}
