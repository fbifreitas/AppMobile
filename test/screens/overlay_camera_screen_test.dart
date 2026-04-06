import 'package:appmobile/models/inspection_capture_context.dart';
import 'package:appmobile/screens/overlay_camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxTicks = 40,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

InspectionCaptureFlowState _flowState({
  String? macroLocal,
  String? ambiente,
  String? elemento,
  String? material,
  String? estado,
}) {
  return InspectionCaptureFlowState.bootstrap(
    macroLocal: macroLocal,
    ambiente: ambiente,
    elemento: elemento,
    material: material,
    estado: estado,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'OverlayCameraScreen hides material and estado when subtipo overrides camera levels',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OverlayCameraScreen(
            title: 'Camera',
            tipoImovel: 'Urbano',
            subtipoImovel: 'Galpao',
            initialFlowState: _flowState(
              macroLocal: 'Rua',
              ambiente: 'Fachada',
              elemento: 'Portao',
            ),
            useTestMenuData: true,
            testCameraLevelOrder: const <String>['ambiente', 'elemento'],
            testMacroLocais: const <String>['Rua'],
            testAmbientes: const <String>['Fachada'],
            testElementos: const <String>['Portao'],
            testMateriais: const <String>['Metal'],
            testEstados: const <String>['Bom'],
            skipDeviceInitialization: true,
            showVoiceActions: false,
          ),
        ),
      );
      await _pumpUntilFound(tester, find.text('Elemento fotografado'));

      expect(find.text('Local da foto'), findsOneWidget);
      expect(find.text('Elemento fotografado'), findsOneWidget);
      expect(find.text('Material'), findsNothing);
      expect(find.text('Estado'), findsNothing);

      final ambienteDy = tester.getTopLeft(find.text('Local da foto')).dy;
      final elementoDy =
          tester.getTopLeft(find.text('Elemento fotografado')).dy;

      expect(ambienteDy < elementoDy, isTrue);
    },
  );

  testWidgets(
    'OverlayCameraScreen falls back to tipo camera levels when subtipo has no override',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OverlayCameraScreen(
            title: 'Camera',
            tipoImovel: 'Urbano',
            subtipoImovel: 'Casa',
            initialFlowState: _flowState(
              macroLocal: 'Rua',
              ambiente: 'Fachada',
              elemento: 'Portao',
              material: 'Metal',
            ),
            useTestMenuData: true,
            testCameraLevelOrder: const <String>[
              'ambiente',
              'elemento',
              'material',
              'estado',
            ],
            testMacroLocais: const <String>['Rua'],
            testAmbientes: const <String>['Fachada'],
            testElementos: const <String>['Portao'],
            testMateriais: const <String>['Metal'],
            testEstados: const <String>['Bom'],
            skipDeviceInitialization: true,
            showVoiceActions: false,
          ),
        ),
      );
      await _pumpUntilFound(tester, find.text('Material'));

      expect(find.text('Material'), findsOneWidget);
      await _pumpUntilFound(tester, find.text('Estado'));

      expect(find.text('Estado'), findsOneWidget);
    },
  );

  testWidgets(
    'OverlayCameraScreen creates a new ambiente instance through contextual action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OverlayCameraScreen(
            title: 'Camera',
            tipoImovel: 'Urbano',
            subtipoImovel: 'Casa',
            initialFlowState: _flowState(
              macroLocal: 'Area interna',
              ambiente: 'Quarto',
            ),
            useTestMenuData: true,
            testCameraLevelOrder: const <String>['ambiente'],
            testMacroLocais: const <String>['Area interna'],
            testAmbientes: const <String>['Quarto', 'Sala'],
            skipDeviceInitialization: true,
            showVoiceActions: false,
          ),
        ),
      );

      await _pumpUntilFound(tester, find.text('Trocar'));
      expect(find.text('Novo Quarto'), findsOneWidget);

      await tester.tap(find.text('Novo Quarto'));
      await tester.pumpAndSettle();

      expect(find.text('Quarto 2'), findsWidgets);
      expect(find.text('Novo Quarto'), findsOneWidget);
    },
  );

  testWidgets(
    'OverlayCameraScreen keeps ambiente actions inline with local selector',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OverlayCameraScreen(
            title: 'Camera',
            tipoImovel: 'Urbano',
            subtipoImovel: 'Casa',
            initialFlowState: _flowState(
              macroLocal: 'Area interna',
              ambiente: 'Sala',
            ),
            useTestMenuData: true,
            testCameraLevelOrder: const <String>['ambiente'],
            testMacroLocais: const <String>['Area interna'],
            testAmbientes: const <String>['Sala', 'Quarto', 'Cozinha'],
            skipDeviceInitialization: true,
            showVoiceActions: false,
          ),
        ),
      );

      await _pumpUntilFound(tester, find.text('Local da foto'));
      expect(find.text('Local da foto'), findsOneWidget);
      expect(find.text('Nova Sala'), findsOneWidget);
      expect(find.text('Trocar'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('camera_ambiente_selector_list')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('camera_current_ambiente_label')),
        findsNothing,
      );
      expect(find.text('Sala'), findsWidgets);
      expect(find.text('Quarto'), findsOneWidget);
      expect(find.text('Cozinha'), findsOneWidget);

      final titleDy = tester.getTopLeft(find.text('Local da foto')).dy;
      final duplicateDy = tester.getTopLeft(find.text('Nova Sala')).dy;
      final changeDy = tester.getTopLeft(find.text('Trocar')).dy;
      final selectorListDy =
          tester
              .getTopLeft(
                find.byKey(const ValueKey('camera_ambiente_selector_list')),
              )
              .dy;

      expect(duplicateDy <= selectorListDy, isTrue);
      expect(changeDy <= selectorListDy, isTrue);
      expect(titleDy <= selectorListDy, isTrue);
    },
  );
}
