import '../models/flow_selection.dart';
import '../models/inspection_camera_flow_request.dart';
import '../models/overlay_camera_capture_result.dart';

class InspectionCaptureRecoveryAdapter {
  const InspectionCaptureRecoveryAdapter._();

  static const InspectionCaptureRecoveryAdapter instance =
      InspectionCaptureRecoveryAdapter._();

  FlowSelection? resolveResumeSelection({
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    if (currentCaptures.isNotEmpty) {
      return currentCaptures.last.selection;
    }

    final reviewPayload = inspectionRecoveryPayload['review'];
    if (reviewPayload is! Map) return null;

    final rawContext = reviewPayload['cameraContext'];
    Map<String, dynamic>? map;
    if (rawContext is Map<String, dynamic>) {
      map = rawContext;
    } else if (rawContext is Map) {
      map = rawContext.map((key, value) => MapEntry('$key', value));
    }
    if (map == null) return null;

    final selection = FlowSelection.fromMap(map);
    return selection.hasAnyValue ? selection : null;
  }

  Map<String, dynamic> serializeSelection(FlowSelection? selection) {
    if (selection == null || !selection.hasAnyValue) {
      return const <String, dynamic>{};
    }
    return selection.toMap(includeCanonical: true, includeLegacy: true);
  }

  List<OverlayCameraCaptureResult> readPersistedReviewCaptures(
    Map<String, dynamic> inspectionRecoveryPayload,
  ) {
    final reviewPayload = inspectionRecoveryPayload['review'];
    if (reviewPayload is! Map) {
      return const <OverlayCameraCaptureResult>[];
    }

    final rawCaptures = reviewPayload['captures'];
    if (rawCaptures is! List) {
      return const <OverlayCameraCaptureResult>[];
    }

    final captures = <OverlayCameraCaptureResult>[];
    for (final raw in rawCaptures) {
      if (raw is Map<String, dynamic>) {
        captures.add(OverlayCameraCaptureResult.fromMap(raw));
        continue;
      }
      if (raw is Map) {
        captures.add(
          OverlayCameraCaptureResult.fromMap(
            raw.map((key, value) => MapEntry('$key', value)),
          ),
        );
      }
    }
    return captures;
  }

  List<OverlayCameraCaptureResult> mergeReviewCaptures({
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    final persistedCaptures = readPersistedReviewCaptures(
      inspectionRecoveryPayload,
    );
    final currentPaths =
        currentCaptures.map((capture) => capture.filePath).toSet();
    return <OverlayCameraCaptureResult>[
      ...persistedCaptures.where(
        (persisted) => !currentPaths.contains(persisted.filePath),
      ),
      ...currentCaptures,
    ];
  }

  List<OverlayCameraCaptureResult> resolveReviewCaptures({
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    final mergedCaptures = mergeReviewCaptures(
      currentCaptures: currentCaptures,
      inspectionRecoveryPayload: inspectionRecoveryPayload,
    );

    final reviewPayload = inspectionRecoveryPayload['review'];
    if (reviewPayload is! Map) {
      return mergedCaptures;
    }

    final reviewedRaw = reviewPayload['capturesRevisadas'];
    if (reviewedRaw is! List) {
      return mergedCaptures;
    }

    final reviewedByPath = <String, Map<String, dynamic>>{};
    for (final raw in reviewedRaw) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(
        raw.map((key, value) => MapEntry('$key', value)),
      );
      final filePath = '${map['filePath'] ?? ''}'.trim();
      if (filePath.isEmpty) continue;
      reviewedByPath[filePath] = map;
    }

    if (reviewedByPath.isEmpty) {
      return mergedCaptures;
    }

    return mergedCaptures.map((capture) {
      final reviewed = reviewedByPath[capture.filePath];
      if (reviewed == null) {
        return capture;
      }

      final selection = FlowSelection.fromMap(reviewed);
      final isComplete = reviewed['isComplete'] == true;

      return capture.copyWith(
        macroLocal: selection.subjectContext ?? capture.macroLocal,
        ambiente: selection.targetItem ?? capture.ambiente,
        ambienteBase: selection.targetItemBase ?? capture.ambienteBase,
        ambienteInstanceIndex:
            selection.targetItemInstanceIndex ?? capture.ambienteInstanceIndex,
        elemento: selection.targetQualifier,
        material:
            selection.attributeText('inspection.material') ?? capture.material,
        estado: selection.targetCondition,
        classificationConfirmed: isComplete || capture.classificationConfirmed,
      );
    }).toList();
  }

  bool hasPersistedPhotos({
    required Map<String, dynamic> step2Payload,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    if (readPersistedReviewCaptures(inspectionRecoveryPayload).isNotEmpty) {
      return true;
    }

    final fotos = step2Payload['fotos'];
    if (fotos is! Map) {
      return false;
    }

    for (final value in fotos.values) {
      if (value is! Map) {
        continue;
      }
      final hasImage = value['hasImage'] == true;
      final imagePath = value['imagePath']?.toString().trim();
      if (hasImage || (imagePath != null && imagePath.isNotEmpty)) {
        return true;
      }
    }
    return false;
  }

  InspectionCameraFlowRequest buildCameraFlowRequest({
    required String title,
    String? tipoImovel,
    String? assetType,
    String? subtipoImovel,
    String? assetSubtype,
    bool singleCaptureMode = false,
    bool cameFromCheckinStep1 = false,
    FlowSelection? initialSelection,
    bool preferInitialSelection = false,
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    final resolvedAssetType = (assetType ?? tipoImovel ?? '').trim();
    final resolvedAssetSubtype = (assetSubtype ?? subtipoImovel ?? '').trim();
    return InspectionCameraFlowRequest.bootstrap(
      title: title,
      tipoImovel: resolvedAssetType,
      subtipoImovel: resolvedAssetSubtype,
      singleCaptureMode: singleCaptureMode,
      cameFromCheckinStep1: cameFromCheckinStep1,
      initialSelection: initialSelection,
      preferInitialSelection: preferInitialSelection,
      resumeSelection: resolveResumeSelection(
        currentCaptures: currentCaptures,
        inspectionRecoveryPayload: inspectionRecoveryPayload,
      ),
    );
  }

  Map<String, dynamic> buildReviewPayload({
    String? tipoImovel,
    String? assetType,
    required List<OverlayCameraCaptureResult> currentCaptures,
    required List<Map<String, dynamic>> reviewedCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
    Map<String, dynamic>? existingReviewPayload,
  }) {
    final resolvedAssetType = (assetType ?? tipoImovel ?? '').trim();
    final reviewPayload = <String, dynamic>{
      ...?existingReviewPayload,
      'assetType': resolvedAssetType,
      'tipoImovel': resolvedAssetType,
      'captures': currentCaptures.map((capture) => capture.toMap()).toList(),
      'capturesRevisadas': reviewedCaptures,
    };

    final serializedContext = serializeSelection(
      resolveResumeSelection(
        currentCaptures: currentCaptures,
        inspectionRecoveryPayload: inspectionRecoveryPayload,
      ),
    );
    if (serializedContext.isEmpty) {
      reviewPayload.remove('cameraContext');
    } else {
      reviewPayload['cameraContext'] = serializedContext;
    }

    return reviewPayload;
  }
}
