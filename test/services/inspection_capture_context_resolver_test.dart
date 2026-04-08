import 'package:appmobile/config/inspection_menu_package.dart';
import 'package:appmobile/services/inspection_capture_context_resolver.dart';
import 'package:appmobile/services/inspection_semantic_field_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = InspectionCaptureContextResolver.instance;

  test('resolves canonical FlowSelection from semantic step1 levels', () {
    final levels = <ConfigLevelDefinition>[
      ConfigLevelDefinition(
        id: 'contexto',
        label: 'Por onde deseja começar?',
        required: true,
        dependsOn: null,
        options: const <String>['Interna', 'Externa'],
        semanticKey: InspectionSemanticFieldKeys.captureContext,
      ),
      ConfigLevelDefinition(
        id: 'ambiente',
        label: 'Onde estou?',
        required: true,
        dependsOn: null,
        options: const <String>['Quarto', 'Sala'],
        semanticKey: InspectionSemanticFieldKeys.photoLocation,
      ),
      ConfigLevelDefinition(
        id: 'elemento',
        label: 'Elemento',
        required: false,
        dependsOn: null,
        options: const <String>['Janela'],
        semanticKey: InspectionSemanticFieldKeys.photoElement,
      ),
    ];

    final selection = resolver.resolveFromStep1(
      levels: levels,
      selectedLevels: const <String, String>{
        'contexto': 'Interna',
        'ambiente': 'Quarto',
        'elemento': 'Janela',
      },
    );

    expect(selection.subjectContext, 'Interna');
    expect(selection.targetItem, 'Quarto');
    expect(selection.targetQualifier, 'Janela');
  });

  test('returns empty FlowSelection when selections are missing', () {
    final selection = resolver.resolveFromStep1(
      levels: const <ConfigLevelDefinition>[],
      selectedLevels: const <String, String>{},
    );

    expect(selection.hasAnyValue, isFalse);
    expect(selection.subjectContext, isNull);
    expect(selection.targetItem, isNull);
    expect(selection.targetQualifier, isNull);
    expect(selection.attributeText('inspection.material'), isNull);
    expect(selection.targetCondition, isNull);
  });
}
