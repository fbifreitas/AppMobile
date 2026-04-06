import '../models/inspection_capture_context.dart';
import '../models/overlay_camera_capture_result.dart';

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

  Map<String, dynamic> serializeContext(InspectionCaptureContext? context) {
    if (context == null || !context.hasAnyValue) {
      return const <String, dynamic>{};
    }
    return context.toMap();
  }

  InspectionCaptureContext contextFromCapture(
    OverlayCameraCaptureResult capture,
  ) {
    return InspectionCaptureContext(
      macroLocal: capture.macroLocal,
      ambiente: capture.ambiente,
      ambienteBase: capture.ambienteBase,
      ambienteInstanceIndex: capture.ambienteInstanceIndex,
      elemento: capture.elemento,
      material: capture.material,
      estado: capture.estado,
    );
  }
}
