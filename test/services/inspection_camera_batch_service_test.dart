import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/services/inspection_camera_batch_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  final service = InspectionCameraBatchService.instance;

  test('builds capture result preserving semantic ambiente instance data', () {
    final result = service.buildCaptureResult(
      filePath: '/tmp/camera.jpg',
      macroLocal: 'Interna',
      ambiente: 'Quarto 2',
      elemento: 'Janela',
      material: 'Madeira',
      estado: 'Bom',
      capturedAt: DateTime(2026, 4, 6, 10, 0),
      position: Position(
        longitude: -46,
        latitude: -23,
        timestamp: DateTime(2026, 4, 6, 10, 0),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
      predictionSummary: 'Janela • Madeira • Bom',
    );

    expect(result.ambienteBase, 'Quarto');
    expect(result.ambienteInstanceIndex, 2);
    expect(result.usedSuggestion, isTrue);
  });

  test('buildStep2PayloadFromCaptures keeps matching mandatory evidence', () {
    final payload = service.buildStep2PayloadFromCaptures(
      existingStep2Payload: const <String, dynamic>{},
      inspectionRecoveryPayload: <String, dynamic>{
        'step2': <String, dynamic>{
          'tipo': 'urbano',
        },
      },
      captures: <OverlayCameraCaptureResult>[
        OverlayCameraCaptureResult(
          filePath: '/tmp/fachada.jpg',
          macroLocal: 'Externa',
          ambiente: 'Fachada',
          ambienteBase: 'Fachada',
          ambienteInstanceIndex: 1,
          elemento: 'Portão Social',
          material: 'Metal',
          estado: 'Bom',
          capturedAt: DateTime(2026, 4, 6),
          latitude: -23,
          longitude: -46,
          accuracy: 5,
        ),
      ],
      tipoImovel: 'Urbano',
    );

    expect(payload, isA<Map<String, dynamic>>());
    expect((payload['fotos'] as Map<String, dynamic>).isNotEmpty, isTrue);
  });
}
