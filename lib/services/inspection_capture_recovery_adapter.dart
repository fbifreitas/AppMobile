import '../models/inspection_camera_flow_request.dart';
import '../models/inspection_capture_context.dart';
import '../models/overlay_camera_capture_result.dart';
import '../models/flow_selection.dart';

class InspectionCaptureRecoveryAdapter {
  const InspectionCaptureRecoveryAdapter._();

  static const InspectionCaptureRecoveryAdapter instance =
      InspectionCaptureRecoveryAdapter._();

  InspectionCaptureContext? resolveResumeContext({
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    if (currentCaptures.isNotEmpty) {
      return contextFromCapture(currentCaptures.last);
    }

    final reviewPayload = inspectionRecoveryPayload['review'];
    if (reviewPayload is! Map) return null;

    final rawContext = reviewPayload['cameraContext'];
    if (rawContext is Map<String, dynamic>) {
      final context = InspectionCaptureContext.fromMap(rawContext);
      return context.hasAnyValue ? context : null;
    }
    if (rawContext is Map) {
      final context = InspectionCaptureContext.fromMap(
        rawContext.map((key, value) => MapEntry('$key', value)),
      );
      return context.hasAnyValue ? context : null;
    }

    return null;
  }

  FlowSelection? resolveResumeSelection({
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    return resolveResumeContext(
      currentCaptures: currentCaptures,
      inspectionRecoveryPayload: inspectionRecoveryPayload,
    )?.selection;
  }

  Map<String, dynamic> serializeContext(InspectionCaptureContext? context) {
    if (context == null || !context.hasAnyValue) {
      return const <String, dynamic>{};
    }
    return context.toMap();
  }

  Map<String, dynamic> serializeSelection(FlowSelection? selection) {
    if (selection == null || !selection.hasAnyValue) {
      return const <String, dynamic>{};
    }
    return selection.toMap(includeCanonical: true, includeLegacy: true);
  }

  InspectionCaptureContext contextFromCapture(
    OverlayCameraCaptureResult capture,
  ) {
    return InspectionCaptureContext(
      macroLocal: capture.subjectContext,
      ambiente: capture.targetItem,
      ambienteBase: capture.ambienteBase,
      ambienteInstanceIndex: capture.ambienteInstanceIndex,
      elemento: capture.targetQualifier,
      material: capture.material,
      estado: capture.targetCondition,
    );
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
    final currentPaths = currentCaptures.map((capture) => capture.filePath).toSet();
    return <OverlayCameraCaptureResult>[
      ...persistedCaptures.where(
        (persisted) => !currentPaths.contains(persisted.filePath),
      ),
      ...currentCaptures,
    ];
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
    required String tipoImovel,
    required String subtipoImovel,
    bool singleCaptureMode = false,
    bool cameFromCheckinStep1 = false,
    InspectionCaptureContext? initialContext,
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    return buildCameraFlowRequestFromSelection(
      title: title,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      singleCaptureMode: singleCaptureMode,
      cameFromCheckinStep1: cameFromCheckinStep1,
      initialSelection: initialContext?.selection,
      currentCaptures: currentCaptures,
      inspectionRecoveryPayload: inspectionRecoveryPayload,
    );
  }

  InspectionCameraFlowRequest buildCameraFlowRequestFromSelection({
    required String title,
    required String tipoImovel,
    required String subtipoImovel,
    bool singleCaptureMode = false,
    bool cameFromCheckinStep1 = false,
    FlowSelection? initialSelection,
    required List<OverlayCameraCaptureResult> currentCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    final resumeSelection = resolveResumeSelection(
      currentCaptures: currentCaptures,
      inspectionRecoveryPayload: inspectionRecoveryPayload,
    );
    return InspectionCameraFlowRequest.bootstrap(
      title: title,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      singleCaptureMode: singleCaptureMode,
      cameFromCheckinStep1: cameFromCheckinStep1,
      initialContext:
          initialSelection == null
              ? null
              : InspectionCaptureContext.canonical(
                subjectContext: initialSelection.subjectContext,
                targetItem: initialSelection.targetItem,
                targetItemBase: initialSelection.targetItemBase,
                targetItemInstanceIndex:
                    initialSelection.targetItemInstanceIndex,
                targetQualifier: initialSelection.targetQualifier,
                targetCondition: initialSelection.targetCondition,
                domainAttributes: initialSelection.domainAttributes,
              ),
      resumeContext:
          resumeSelection == null
              ? null
              : InspectionCaptureContext.canonical(
                subjectContext: resumeSelection.subjectContext,
                targetItem: resumeSelection.targetItem,
                targetItemBase: resumeSelection.targetItemBase,
                targetItemInstanceIndex:
                    resumeSelection.targetItemInstanceIndex,
                targetQualifier: resumeSelection.targetQualifier,
                targetCondition: resumeSelection.targetCondition,
                domainAttributes: resumeSelection.domainAttributes,
              ),
    );
  }

  Map<String, dynamic> buildReviewPayload({
    required String tipoImovel,
    required List<OverlayCameraCaptureResult> currentCaptures,
    required List<Map<String, dynamic>> reviewedCaptures,
    required Map<String, dynamic> inspectionRecoveryPayload,
    Map<String, dynamic>? existingReviewPayload,
  }) {
    final reviewPayload = <String, dynamic>{
      ...?existingReviewPayload,
      'tipoImovel': tipoImovel,
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
