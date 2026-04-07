import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/services/inspection_camera_selector_section_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionCameraSelectorSectionService.instance;

  test('builds inline ambiente section with duplicate action from canonical flow state', () {
    final sections = service.buildSections(
      levelOrder: const <String>['ambiente', 'elemento'],
      labelsByLevel: const <String, String>{
        'ambiente': 'Local da foto',
        'elemento': 'Elemento fotografado',
      },
      selectionState: const FlowSelectionState(
        initialSuggestedSelection: FlowSelection(
          subjectContext: 'Area interna',
        ),
        currentSelection: FlowSelection(
          subjectContext: 'Area interna',
          targetItem: 'Sala',
        ),
      ),
      macroLocais: const <String>['Area interna'],
      ambientes: const <String>['Sala', 'Quarto'],
      elementos: const <String>['Janela'],
      materiais: const <String>[],
      estados: const <String>[],
    );

    expect(sections.length, 2);
    expect(sections.first.levelId, 'ambiente');
    expect(sections.first.title, 'Local da foto');
    expect(sections.first.allowDuplicate, isTrue);
    expect(sections.first.duplicateLabel, 'Nova Sala');
    expect(sections.last.levelId, 'elemento');
  });

  test('keeps macro section visible when bootstrap already fixed macro local', () {
    final sections = service.buildSections(
      levelOrder: const <String>['macroLocal', 'ambiente'],
      labelsByLevel: const <String, String>{},
      selectionState: const FlowSelectionState(
        initialSuggestedSelection: FlowSelection(
          subjectContext: 'Rua',
        ),
        currentSelection: FlowSelection(
          subjectContext: 'Rua',
        ),
      ),
      macroLocais: const <String>['Rua'],
      ambientes: const <String>['Fachada'],
      elementos: const <String>[],
      materiais: const <String>[],
      estados: const <String>[],
    );

    expect(
      sections.map((section) => section.levelId),
      <String>['macroLocal', 'ambiente'],
    );
    expect(sections.first.selected, 'Rua');
  });
}
