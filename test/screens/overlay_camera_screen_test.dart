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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'OverlayCameraScreen hides material and estado when subtipo overrides camera levels',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OverlayCameraScreen(
            title: 'Câmera',
            tipoImovel: 'Urbano',
            subtipoImovel: 'Galpão',
            preselectedMacroLocal: 'Rua',
            initialAmbiente: 'Fachada',
            initialElemento: 'Portão',
            useTestMenuData: true,
            testCameraLevelOrder: <String>['ambiente', 'elemento'],
            testMacroLocais: <String>['Rua'],
            testAmbientes: <String>['Fachada'],
            testElementos: <String>['Portão'],
            testMateriais: <String>['Metal'],
            testEstados: <String>['Bom'],
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
        const MaterialApp(
          home: OverlayCameraScreen(
            title: 'Câmera',
            tipoImovel: 'Urbano',
            subtipoImovel: 'Casa',
            preselectedMacroLocal: 'Rua',
            initialAmbiente: 'Fachada',
            initialElemento: 'Portão',
            initialMaterial: 'Metal',
            useTestMenuData: true,
            testCameraLevelOrder: <String>[
              'ambiente',
              'elemento',
              'material',
              'estado',
            ],
            testMacroLocais: <String>['Rua'],
            testAmbientes: <String>['Fachada'],
            testElementos: <String>['Portão'],
            testMateriais: <String>['Metal'],
            testEstados: <String>['Bom'],
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
}
