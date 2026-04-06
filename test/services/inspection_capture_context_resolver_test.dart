import 'package:appmobile/config/inspection_menu_package.dart';
import 'package:appmobile/models/inspection_capture_context.dart';
import 'package:appmobile/services/inspection_capture_context_resolver.dart';
import 'package:appmobile/services/inspection_semantic_field_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = InspectionCaptureContextResolver.instance;

  test('resolves capture context from semantic step1 levels', () {
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

    final context = resolver.resolveFromStep1(
      levels: levels,
      selectedLevels: const <String, String>{
        'contexto': 'Interna',
        'ambiente': 'Quarto',
        'elemento': 'Janela',
      },
    );

    expect(context.macroLocal, 'Interna');
    expect(context.ambiente, 'Quarto');
    expect(context.elemento, 'Janela');
  });

  test('returns empty context when selections are missing', () {
    final context = resolver.resolveFromStep1(
      levels: const <ConfigLevelDefinition>[],
      selectedLevels: const <String, String>{},
    );

    expect(context.hasAnyValue, isFalse);
    expect(context.macroLocal, isNull);
    expect(context.ambiente, isNull);
    expect(context.elemento, isNull);
    expect(context.material, isNull);
    expect(context.estado, isNull);
  });
}
