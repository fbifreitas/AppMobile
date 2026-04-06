import 'package:appmobile/models/inspection_capture_context.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/services/inspection_capture_recovery_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = InspectionCaptureRecoveryAdapter.instance;

  OverlayCameraCaptureResult capture({
    required String filePath,
    required String ambiente,
  }) {
    return OverlayCameraCaptureResult(
      filePath: filePath,
      macroLocal: 'Interna',
      ambiente: ambiente,
      ambienteBase: 'Quarto',
      ambienteInstanceIndex: ambiente == 'Quarto 2' ? 2 : 1,
      elemento: 'Janela',
      material: 'Madeira',
      estado: 'Bom',
      capturedAt: DateTime(2026, 4, 6),
      latitude: -23,
      longitude: -46,
      accuracy: 5,
    );
  }

  test('prefers latest current capture for resume context', () {
    final context = adapter.resolveResumeContext(
      currentCaptures: <OverlayCameraCaptureResult>[
        capture(filePath: '/tmp/1.jpg', ambiente: 'Quarto'),
        capture(filePath: '/tmp/2.jpg', ambiente: 'Quarto 2'),
      ],
      inspectionRecoveryPayload: const <String, dynamic>{},
    );

    expect(context?.macroLocal, 'Interna');
    expect(context?.ambiente, 'Quarto 2');
    expect(context?.ambienteBase, 'Quarto');
    expect(context?.ambienteInstanceIndex, 2);
  });

  test('falls back to persisted review cameraContext payload', () {
    final context = adapter.resolveResumeContext(
      currentCaptures: const <OverlayCameraCaptureResult>[],
      inspectionRecoveryPayload: <String, dynamic>{
        'review': <String, dynamic>{
          'cameraContext': <String, dynamic>{
            'macroLocal': 'Externa',
            'ambiente': 'Fachada',
            'elemento': 'Portão',
          },
        },
      },
    );

    expect(context?.macroLocal, 'Externa');
    expect(context?.ambiente, 'Fachada');
    expect(context?.elemento, 'Portão');
  });

  test('serializes empty context as empty map', () {
    expect(
      adapter.serializeContext(InspectionCaptureContext.empty),
      isEmpty,
    );
  });
}
