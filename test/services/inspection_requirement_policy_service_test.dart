import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/models/checkin_step2_model.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/services/inspection_requirement_policy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionRequirementPolicyService.instance;

  OverlayCameraCaptureResult capture({
    required String path,
    required String ambiente,
    String? elemento,
  }) {
    return OverlayCameraCaptureResult(
      filePath: path,
      ambiente: ambiente,
      elemento: elemento,
      capturedAt: DateTime(2026, 4, 5, 10),
      latitude: -23.5505,
      longitude: -46.6333,
      accuracy: 5,
    );
  }

  const quartoObrigatorio = CheckinStep2PhotoFieldConfig(
    id: 'foto_quarto',
    titulo: 'Quarto',
    icon: Icons.bed,
    obrigatorio: true,
    cameraMacroLocal: 'Area interna',
    cameraAmbiente: 'Quarto',
    cameraElementoInicial: 'Porta',
  );

  const salaOpcional = CheckinStep2PhotoFieldConfig(
    id: 'foto_sala',
    titulo: 'Sala',
    icon: Icons.chair,
    obrigatorio: false,
    cameraMacroLocal: 'Area interna',
    cameraAmbiente: 'Sala',
    cameraElementoInicial: null,
  );

  group('InspectionRequirementPolicyService', () {
    test('find matching capture by ambiente and elemento', () {
      final result = service.findMatchingCapture(
        field: quartoObrigatorio,
        captures: <OverlayCameraCaptureResult>[
          capture(path: '1.jpg', ambiente: 'Quarto', elemento: 'Janela'),
          capture(path: '2.jpg', ambiente: 'Quarto', elemento: 'Porta'),
        ],
      );

      expect(result?.filePath, '2.jpg');
    });

    test('find matching capture by ambiente base when instance label is used', () {
      final result = service.findMatchingCapture(
        field: quartoObrigatorio,
        captures: <OverlayCameraCaptureResult>[
          capture(
            path: '3.jpg',
            ambiente: 'Quarto 2',
            elemento: 'Porta',
          ).copyWith(
            ambienteBase: 'Quarto',
            ambienteInstanceIndex: 2,
          ),
        ],
      );

      expect(result?.filePath, '3.jpg');
    });

    test('evaluate statuses combines current captures and persisted photos', () {
      final persisted = CheckinStep2Model.empty(TipoImovel.urbano).setPhoto(
        fieldId: 'foto_quarto',
        titulo: 'Quarto',
        imagePath: 'persisted.jpg',
        geoPoint: GeoPointData(
          latitude: -23.5505,
          longitude: -46.6333,
          accuracy: 5,
          capturedAt: DateTime(2026, 4, 5, 9),
        ),
      );

      final statuses = service.evaluateMandatoryFieldStatuses(
        fields: const <CheckinStep2PhotoFieldConfig>[
          quartoObrigatorio,
          salaOpcional,
        ],
        persistedModel: persisted,
        captures: <OverlayCameraCaptureResult>[],
      );

      expect(statuses, hasLength(1));
      expect(statuses.single.field.id, 'foto_quarto');
      expect(statuses.single.isDone, isTrue);
      expect(statuses.single.matchedPersistedPhoto, isTrue);
      expect(statuses.single.matchedCapture, isFalse);
    });

    test('count completed mandatory fields counts only required fields', () {
      final count = service.countCompletedMandatoryFields(
        fields: const <CheckinStep2PhotoFieldConfig>[
          quartoObrigatorio,
          salaOpcional,
        ],
        persistedModel: CheckinStep2Model.empty(TipoImovel.urbano),
        captures: <OverlayCameraCaptureResult>[
          capture(path: '1.jpg', ambiente: 'Quarto', elemento: 'Porta'),
          capture(path: '2.jpg', ambiente: 'Sala'),
        ],
      );

      expect(count, 1);
    });
  });
}
