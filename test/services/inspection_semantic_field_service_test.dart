import 'package:appmobile/config/inspection_menu_package.dart';
import 'package:appmobile/services/inspection_semantic_field_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionSemanticFieldService.instance;

  group('InspectionSemanticFieldService', () {
    test('resolve selected value by configured semantic key first', () {
      const levels = <ConfigLevelDefinition>[
        ConfigLevelDefinition(
          id: 'contexto_inicial',
          label: 'Por onde comecar?',
          required: true,
          dependsOn: null,
          options: <String>['Area interna'],
          semanticKey: InspectionSemanticFieldKeys.captureContext,
        ),
      ];

      final value = service.resolveSelectedValueForSemantic(
        levels: levels,
        semanticKey: InspectionSemanticFieldKeys.captureContext,
        selectedLevels: const <String, String>{
          'contexto_inicial': 'Area interna',
          'macroLocal': 'Fachada',
        },
      );

      expect(value, 'Area interna');
    });

    test('resolve selected value by fallback aliases when semantic is absent', () {
      final value = service.resolveSelectedValueForSemantic(
        levels: const <ConfigLevelDefinition>[],
        semanticKey: InspectionSemanticFieldKeys.photoLocation,
        selectedLevels: const <String, String>{
          'cameraAmbiente': 'Quarto 1',
        },
      );

      expect(value, 'Quarto 1');
    });

    test('map camera aliases to canonical camera level ids', () {
      expect(service.mapCameraLevelId('contexto'), 'macroLocal');
      expect(service.mapCameraLevelId('local_foto'), 'ambiente');
      expect(service.mapCameraLevelId('item'), 'elemento');
      expect(service.mapCameraLevelId('materiais'), 'material');
      expect(service.mapCameraLevelId('condicao'), 'estado');
      expect(service.mapCameraLevelId('subjectContext'), 'macroLocal');
      expect(service.mapCameraLevelId('targetItem'), 'ambiente');
      expect(service.mapCameraLevelId('targetQualifier'), 'elemento');
      expect(service.mapCameraLevelId('targetCondition'), 'estado');
    });

    test('exposes canonical field ids for semantics', () {
      expect(
        service.canonicalFieldIdForSemantic(
          InspectionSemanticFieldKeys.captureContext,
        ),
        InspectionCanonicalFieldKeys.subjectContext,
      );
      expect(
        service.canonicalFieldIdForSemantic(
          InspectionSemanticFieldKeys.photoLocation,
        ),
        InspectionCanonicalFieldKeys.targetItem,
      );
      expect(
        service.canonicalFieldIdForSemantic(
          InspectionSemanticFieldKeys.photoElement,
        ),
        InspectionCanonicalFieldKeys.targetQualifier,
      );
      expect(
        service.canonicalFieldIdForSemantic(
          InspectionSemanticFieldKeys.photoState,
        ),
        InspectionCanonicalFieldKeys.targetCondition,
      );
    });

    test('labelForLevel prefers surface label over default label', () {
      const level = ConfigLevelDefinition(
        id: 'contexto',
        label: 'Por onde comecar?',
        required: true,
        dependsOn: null,
        options: <String>[],
        labelsBySurface: <String, String>{
          InspectionSurfaceKeys.camera: 'Onde estou?',
        },
      );

      expect(
        service.labelForLevel(
          level: level,
          surface: InspectionSurfaceKeys.camera,
        ),
        'Onde estou?',
      );
      expect(
        service.labelForLevel(
          level: level,
          surface: InspectionSurfaceKeys.checkinStep1,
        ),
        'Por onde comecar?',
      );
    });
  });
}
