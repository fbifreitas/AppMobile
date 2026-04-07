import 'package:appmobile/config/inspection_menu_package.dart';
import 'package:appmobile/services/inspection_camera_level_presentation_service.dart';
import 'package:appmobile/services/inspection_semantic_field_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionCameraLevelPresentationService(
    semanticFieldService: InspectionSemanticFieldService.instance,
  );

  test('normalizes legacy and semantic camera levels into canonical order', () {
    expect(
      service.normalizeLevelOrder(<String>[
        'macro_local',
        'ambiente',
        'photo_element',
        'estado',
        'macroLocal',
      ]),
      <String>['macroLocal', 'ambiente', 'elemento', 'estado'],
    );
  });

  test('falls back to default order when no valid camera level exists', () {
    expect(
      service.normalizeLevelOrder(<String>['desconhecido']),
      <String>['macroLocal', 'ambiente', 'elemento', 'material', 'estado'],
    );
  });

  test('resolves camera labels by surface with semantic fallback', () {
    final labels = service.resolveLabelsByLevel(
      levels: const <ConfigLevelDefinition>[
        ConfigLevelDefinition(
          id: 'ambiente',
          label: 'Ambiente',
          required: true,
          dependsOn: null,
          options: <String>[],
          semanticKey: InspectionSemanticFieldKeys.photoLocation,
          labelsBySurface: <String, String>{'camera': 'Onde estou?'},
        ),
        ConfigLevelDefinition(
          id: 'macro_local',
          label: 'Contexto',
          required: true,
          dependsOn: null,
          options: <String>[],
          semanticKey: InspectionSemanticFieldKeys.captureContext,
          labelsBySurface: <String, String>{'camera': 'Área da foto'},
        ),
      ],
      surface: InspectionSurfaceKeys.camera,
    );

    expect(labels['ambiente'], 'Onde estou?');
    expect(labels['macroLocal'], 'Área da foto');
    expect(
      service.labelForLevel(levelId: 'elemento', labelsByLevel: labels),
      'Elemento fotografado',
    );
  });
}
