/// BL-070: Teste de integração — fluxo crítico de captura de câmera.
///
/// Cobre o ciclo completo: seleção de contexto → duplicação de ambiente
/// → classificação completa → serialização → retomada via recovery adapter.
library;

import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/inspection_capture_context.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/services/inspection_capture_flow_transition_service.dart';
import 'package:appmobile/services/inspection_capture_recovery_adapter.dart';
import 'package:appmobile/services/inspection_context_actions_service.dart';
import 'package:appmobile/services/inspection_environment_instance_service.dart';
import 'package:appmobile/services/inspection_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InspectionCaptureFlowTransitionService transitionService;
  const adapter = InspectionCaptureRecoveryAdapter.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    transitionService = InspectionCaptureFlowTransitionService(
      menuService: InspectionMenuService.instance,
      environmentInstanceService: InspectionEnvironmentInstanceService.instance,
      contextActionsService: InspectionContextActionsService.instance,
    );
  });

  group('Fluxo crítico — seleção sequencial de contexto', () {
    test('selectSubjectContext → selectTargetItem → selectTargetQualifier → selectMaterial → selectTargetCondition', () async {
      FlowSelectionState state = FlowSelectionState.bootstrap();

      // 1. Seleciona macroLocal
      final r1 = await transitionService.selectSubjectContext(
        propertyType: 'urbano',
        selectionState: state,
        value: 'Área interna',
      );
      state = r1.selectionState;
      expect(state.currentSelection.subjectContext, 'Área interna');
      expect(state.currentSelection.targetItem, isNull);

      // 2. Seleciona ambiente
      final r2 = await transitionService.selectTargetItem(
        propertyType: 'urbano',
        selectionState: state,
        value: 'Sala',
      );
      state = r2.selectionState;
      expect(state.currentSelection.targetItem, 'Sala');
      expect(state.currentSelection.targetQualifier, isNull);

      // 3. Seleciona elemento
      final r3 = await transitionService.selectTargetQualifier(
        propertyType: 'urbano',
        selectionState: state,
        value: 'Piso',
      );
      state = r3.selectionState;
      expect(state.currentSelection.targetQualifier, 'Piso');
      expect(state.currentSelection.targetCondition, isNull);

      // 4. Seleciona material
      final r4 = transitionService.selectMaterial(
        selectionState: state,
        value: 'Cerâmico',
      );
      state = r4.selectionState;
      expect(
        state.currentSelection.attributeText('inspection.material'),
        'Cerâmico',
      );
      // selectMaterial clears targetCondition
      expect(state.currentSelection.targetCondition, isNull);

      // 5. Seleciona targetCondition
      final r5 = transitionService.selectTargetCondition(
        selectionState: state,
        value: 'Bom',
      );
      state = r5.selectionState;
      expect(state.currentSelection.targetCondition, 'Bom');

      // Seleção completa preserva macroLocal
      expect(state.currentSelection.subjectContext, 'Área interna');
    });

    test('selectSubjectContext clears entire downstream chain', () async {
      // Estado com seleção completa
      var state = FlowSelectionState(
        initialSuggestedSelection: FlowSelection.empty,
        currentSelection: FlowSelection(
          subjectContext: 'Área interna',
          targetItem: 'Sala',
          targetQualifier: 'Piso',
          targetCondition: 'Bom',
          domainAttributes: const <String, dynamic>{
            'inspection.material': 'Cerâmico',
          },
        ),
      );

      final result = await transitionService.selectSubjectContext(
        propertyType: 'urbano',
        selectionState: state,
        value: 'Rua',
      );
      state = result.selectionState;

      expect(state.currentSelection.subjectContext, 'Rua');
      expect(state.currentSelection.targetItem, isNull);
      expect(state.currentSelection.targetQualifier, isNull);
      expect(state.currentSelection.targetCondition, isNull);
      expect(state.currentSelection.domainAttributes, isEmpty);
    });
  });

  group('Fluxo crítico — duplicação de ambiente (instâncias)', () {
    test('duplicateTargetItem creates next instance and updates state', () async {
      final state = FlowSelectionState(
        initialSuggestedSelection: FlowSelection.empty,
        currentSelection: const FlowSelection(
          subjectContext: 'Área interna',
          targetItem: 'Quarto',
          targetItemBase: 'Quarto',
        ),
      );

      final result = await transitionService.duplicateTargetItem(
        propertyType: 'urbano',
        selectionState: state,
        selectedAmbiente: 'Quarto',
        existingAmbientes: const <String>['Quarto', 'Sala'],
        useTestMenuData: true,
      );

      expect(result, isNotNull);
      expect(result!.selectionState.currentSelection.targetItem, 'Quarto 2');
      expect(result.selectionState.currentSelection.targetItemBase, 'Quarto');
      expect(result.selectionState.currentSelection.targetItemInstanceIndex, 2);
      expect(result.ambientes, contains('Quarto 2'));
      // downstream limpo
      expect(result.selectionState.currentSelection.targetQualifier, isNull);
    });

    test('duplicate null target item returns null', () async {
      final state = FlowSelectionState.bootstrap();
      final result = await transitionService.duplicateTargetItem(
        propertyType: 'urbano',
        selectionState: state,
        selectedAmbiente: null,
        existingAmbientes: const <String>[],
        useTestMenuData: true,
      );
      expect(result, isNull);
    });
  });

  group('Fluxo crítico — serialização e retomada de contexto', () {
    test('FlowSelection serializa e desserializa mantendo contexto completo', () {
      final selection = FlowSelection(
        subjectContext: 'Área interna',
        targetItem: 'Quarto 2',
        targetItemBase: 'Quarto',
        targetItemInstanceIndex: 2,
        targetQualifier: 'Parede',
        targetCondition: 'Regular',
        domainAttributes: const <String, dynamic>{
          'inspection.material': 'Pintura',
        },
      );

      final map = selection.toMap(includeCanonical: true, includeLegacy: true);
      final restored = FlowSelection.fromMap(map);

      expect(restored.subjectContext, selection.subjectContext);
      expect(restored.targetItem, selection.targetItem);
      expect(restored.targetItemBase, selection.targetItemBase);
      expect(restored.targetItemInstanceIndex, selection.targetItemInstanceIndex);
      expect(restored.targetQualifier, selection.targetQualifier);
      expect(restored.targetCondition, selection.targetCondition);
      expect(
        restored.attributeText('inspection.material'),
        selection.attributeText('inspection.material'),
      );
    });

    test('recovery adapter retorna seleção da última captura para retomada', () {
      final captures = <OverlayCameraCaptureResult>[
        OverlayCameraCaptureResult(
          filePath: 'first.jpg',
          macroLocal: 'Área interna',
          ambiente: 'Sala',
          elemento: 'Parede',
          material: 'Pintura',
          estado: 'Bom',
          capturedAt: DateTime(2026, 1, 1),
          latitude: 0,
          longitude: 0,
          accuracy: 0,
        ),
        OverlayCameraCaptureResult(
          filePath: 'last.jpg',
          macroLocal: 'Área interna',
          ambiente: 'Quarto 2',
          ambienteBase: 'Quarto',
          ambienteInstanceIndex: 2,
          elemento: 'Piso',
          material: 'Cerâmico',
          estado: 'Regular',
          capturedAt: DateTime(2026, 1, 2),
          latitude: 0,
          longitude: 0,
          accuracy: 0,
        ),
      ];

      final resume = adapter.resolveResumeSelection(
        currentCaptures: captures,
        inspectionRecoveryPayload: const <String, dynamic>{},
      );

      expect(resume, isNotNull);
      expect(resume!.targetItem, 'Quarto 2');
      expect(resume.targetItemBase, 'Quarto');
      expect(resume.targetItemInstanceIndex, 2);
      expect(resume.targetQualifier, 'Piso');
      expect(resume.attributeText('inspection.material'), 'Cerâmico');
    });

    test('InspectionCaptureContext.fromMap lê formato legacy e canônico', () {
      // Formato legacy (serializado antes da migração)
      final legacyMap = <String, dynamic>{
        'macroLocal': 'Rua',
        'ambiente': 'Fachada',
        'elemento': 'Porta',
        'material': 'Madeira',
        'estado': 'Bom',
      };
      final ctx = InspectionCaptureContext.fromMap(legacyMap);
      expect(ctx.macroLocal, 'Rua');
      expect(ctx.ambiente, 'Fachada');
      expect(ctx.elemento, 'Porta');
      expect(ctx.material, 'Madeira');
      expect(ctx.estado, 'Bom');

      // Formato canônico (serializado após a migração)
      final canonicalMap = ctx.selection.toMap(
        includeCanonical: true,
        includeLegacy: false,
      );
      final restored = InspectionCaptureContext.fromMap(canonicalMap);
      expect(restored.macroLocal, ctx.macroLocal);
      expect(restored.ambiente, ctx.ambiente);
      expect(restored.elemento, ctx.elemento);
      expect(restored.material, ctx.material);
    });
  });

  group('Fluxo crítico — troca de contexto preserva initialSuggested', () {
    test('initialSuggestedSelection não muda quando currentSelection evolui', () async {
      const suggested = FlowSelection(
        subjectContext: 'Área interna',
        targetItem: 'Sala',
      );
      var state = FlowSelectionState(
        initialSuggestedSelection: suggested,
        currentSelection: suggested,
      );

      // Usuário muda para outro ambiente
      final result = await transitionService.selectTargetItem(
        propertyType: 'urbano',
        selectionState: state,
        value: 'Quarto',
      );
      state = result.selectionState;

      expect(state.initialSuggestedSelection.targetItem, 'Sala');
      expect(state.currentSelection.targetItem, 'Quarto');
    });
  });
}
