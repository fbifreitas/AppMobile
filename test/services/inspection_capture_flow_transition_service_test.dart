import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/services/inspection_capture_flow_transition_service.dart';
import 'package:appmobile/services/inspection_context_actions_service.dart';
import 'package:appmobile/services/inspection_environment_instance_service.dart';
import 'package:appmobile/services/inspection_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final service = InspectionCaptureFlowTransitionService(
    menuService: InspectionMenuService.instance,
    environmentInstanceService: InspectionEnvironmentInstanceService.instance,
    contextActionsService: InspectionContextActionsService.instance,
  );

  test('selectMacroLocal clears downstream capture state', () async {
    final state = FlowSelectionState(
      initialSuggestedSelection: FlowSelection.empty,
      currentSelection: const FlowSelection(
        subjectContext: 'Área interna',
        targetItem: 'Sala',
        targetQualifier: 'Parede',
        targetCondition: 'Bom',
        domainAttributes: <String, dynamic>{'inspection.material': 'Alvenaria'},
      ),
    );

    final result = await service.selectMacroLocal(
      propertyType: 'urbano',
      selectionState: state,
      value: 'Rua',
    );

    expect(result.selectionState.currentSelection.subjectContext, 'Rua');
    expect(result.selectionState.currentSelection.targetItem, isNull);
    expect(result.selectionState.currentSelection.targetQualifier, isNull);
    expect(result.selectionState.currentSelection.targetCondition, isNull);
    expect(result.selectionState.currentSelection.domainAttributes, isEmpty);
  });

  test('duplicateAmbiente returns next instance and keeps list updated', () async {
    final state = FlowSelectionState(
      initialSuggestedSelection: FlowSelection.empty,
      currentSelection: const FlowSelection(
        subjectContext: 'Área interna',
        targetItem: 'Sala',
        targetItemBase: 'Sala',
      ),
    );

    final result = await service.duplicateAmbiente(
      propertyType: 'urbano',
      selectionState: state,
      selectedAmbiente: 'Sala',
      existingAmbientes: const <String>['Sala', 'Quarto', 'Sala 2'],
      useTestMenuData: true,
    );

    expect(result, isNotNull);
    expect(result!.selectionState.currentSelection.targetItem, 'Sala 3');
    expect(result.selectionState.currentSelection.targetItemBase, 'Sala');
    expect(result.ambientes, contains('Sala 3'));
  });

  test('selectMaterial clears estado and selectEstado stores final state', () {
    final state = FlowSelectionState(
      initialSuggestedSelection: FlowSelection.empty,
      currentSelection: const FlowSelection(
        subjectContext: 'Área interna',
        targetItem: 'Sala',
        targetQualifier: 'Parede',
        targetCondition: 'Bom',
        domainAttributes: <String, dynamic>{'inspection.material': 'Alvenaria'},
      ),
    );

    final materialResult = service.selectMaterial(
      selectionState: state,
      value: 'Pintura',
    );

    expect(
      materialResult.selectionState.currentSelection.attributeText(
        'inspection.material',
      ),
      'Pintura',
    );
    expect(materialResult.selectionState.currentSelection.targetCondition, isNull);

    final estadoResult = service.selectEstado(
      selectionState: materialResult.selectionState,
      value: 'Regular',
    );

    expect(
      estadoResult.selectionState.currentSelection.attributeText(
        'inspection.material',
      ),
      'Pintura',
    );
    expect(estadoResult.selectionState.currentSelection.targetCondition, 'Regular');
  });
}
