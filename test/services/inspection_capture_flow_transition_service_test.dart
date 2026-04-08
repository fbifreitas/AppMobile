import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appmobile/models/inspection_capture_context.dart';
import 'package:appmobile/services/inspection_capture_flow_transition_service.dart';
import 'package:appmobile/services/inspection_context_actions_service.dart';
import 'package:appmobile/services/inspection_environment_instance_service.dart';
import 'package:appmobile/services/inspection_menu_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final service = InspectionCaptureFlowTransitionService(
    menuService: InspectionMenuService.instance,
    environmentInstanceService: InspectionEnvironmentInstanceService.instance,
    contextActionsService: InspectionContextActionsService.instance,
  );

  test('selectMacroLocal clears downstream capture state', () async {
    final result = await service.selectMacroLocal(
      propertyType: 'urbano',
      flowState: InspectionCaptureFlowState.bootstrap(
        macroLocal: 'Área interna',
        ambiente: 'Sala',
        elemento: 'Parede',
        material: 'Alvenaria',
        estado: 'Bom',
      ),
      value: 'Rua',
    );

    expect(result.flowState.current.macroLocal, 'Rua');
    expect(result.flowState.current.ambiente, isNull);
    expect(result.flowState.current.elemento, isNull);
    expect(result.flowState.current.material, isNull);
    expect(result.flowState.current.estado, isNull);
  });

  test('duplicateAmbiente returns next instance and keeps list updated', () async {
    final result = await service.duplicateAmbiente(
      propertyType: 'urbano',
      flowState: InspectionCaptureFlowState.bootstrap(
        macroLocal: 'Área interna',
        ambiente: 'Sala',
      ),
      selectedAmbiente: 'Sala',
      existingAmbientes: const <String>['Sala', 'Quarto', 'Sala 2'],
      useTestMenuData: true,
    );

    expect(result, isNotNull);
    expect(result!.flowState.current.ambiente, 'Sala 3');
    expect(result.flowState.current.ambienteBase, 'Sala');
    expect(result.ambientes, contains('Sala 3'));
  });

  test('selectMaterial clears estado and selectEstado stores final state', () {
    final materialResult = service.selectMaterial(
      flowState: InspectionCaptureFlowState.bootstrap(
        macroLocal: 'Área interna',
        ambiente: 'Sala',
        elemento: 'Parede',
        material: 'Alvenaria',
        estado: 'Bom',
      ),
      value: 'Pintura',
    );

    expect(materialResult.flowState.current.material, 'Pintura');
    expect(materialResult.flowState.current.estado, isNull);

    final estadoResult = service.selectEstado(
      flowState: materialResult.flowState,
      value: 'Regular',
    );

    expect(estadoResult.flowState.current.material, 'Pintura');
    expect(estadoResult.flowState.current.estado, 'Regular');
  });
}
