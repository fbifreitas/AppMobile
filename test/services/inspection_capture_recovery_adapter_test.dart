import 'package:appmobile/models/flow_selection.dart';
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

  test('prefers latest current capture for resume selection', () {
    final selection = adapter.resolveResumeSelection(
      currentCaptures: <OverlayCameraCaptureResult>[
        capture(filePath: '/tmp/1.jpg', ambiente: 'Quarto'),
        capture(filePath: '/tmp/2.jpg', ambiente: 'Quarto 2'),
      ],
      inspectionRecoveryPayload: const <String, dynamic>{},
    );

    expect(selection?.subjectContext, 'Interna');
    expect(selection?.targetItem, 'Quarto 2');
    expect(selection?.targetItemBase, 'Quarto');
    expect(selection?.targetItemInstanceIndex, 2);
  });

  test('falls back to persisted review cameraContext payload', () {
    final selection = adapter.resolveResumeSelection(
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

    expect(selection?.subjectContext, 'Externa');
    expect(selection?.targetItem, 'Fachada');
    expect(selection?.targetQualifier, 'Portão');
  });

  test('builds camera flow request with resume from latest capture', () {
    final request = adapter.buildCameraFlowRequest(
      title: 'Fotos Obrigatorias do Check-In',
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
      initialSelection: const FlowSelection(
        subjectContext: 'Interna',
        targetItem: 'Quarto',
      ),
      currentCaptures: <OverlayCameraCaptureResult>[
        capture(filePath: '/tmp/2.jpg', ambiente: 'Quarto 2'),
      ],
      inspectionRecoveryPayload: const <String, dynamic>{},
    );

    expect(
      request.selectionState.initialSuggestedSelection.targetItem,
      'Quarto',
    );
    expect(request.selectionState.currentSelection.targetItem, 'Quarto 2');
    expect(request.selectionState.resumeSelection?.targetItem, 'Quarto 2');
  });

  test('builds review payload with legacy cameraContext compatibility', () {
    final payload = adapter.buildReviewPayload(
      tipoImovel: 'Urbano',
      currentCaptures: <OverlayCameraCaptureResult>[
        capture(filePath: '/tmp/2.jpg', ambiente: 'Quarto 2'),
      ],
      reviewedCaptures: const <Map<String, dynamic>>[
        <String, dynamic>{'filePath': '/tmp/2.jpg'},
      ],
      inspectionRecoveryPayload: const <String, dynamic>{},
      existingReviewPayload: const <String, dynamic>{
        'legacyField': 'keep',
      },
    );

    expect(payload['legacyField'], 'keep');
    expect(payload['cameraContext'], isA<Map<String, dynamic>>());
    expect(
      (payload['cameraContext'] as Map<String, dynamic>)['ambiente'],
      'Quarto 2',
    );
  });

  test('merges persisted review captures with current batch without duplicating filePath', () {
    final merged = adapter.mergeReviewCaptures(
      currentCaptures: <OverlayCameraCaptureResult>[
        capture(filePath: '/tmp/2.jpg', ambiente: 'Quarto 2'),
        capture(filePath: '/tmp/3.jpg', ambiente: 'Sala'),
      ],
      inspectionRecoveryPayload: <String, dynamic>{
        'review': <String, dynamic>{
          'captures': <Map<String, dynamic>>[
            capture(filePath: '/tmp/1.jpg', ambiente: 'Quarto').toMap(),
            capture(filePath: '/tmp/2.jpg', ambiente: 'Quarto antigo').toMap(),
          ],
        },
      },
    );

    expect(merged.map((c) => c.filePath), <String>[
      '/tmp/1.jpg',
      '/tmp/2.jpg',
      '/tmp/3.jpg',
    ]);
    expect(merged[1].ambiente, 'Quarto 2');
  });
}
