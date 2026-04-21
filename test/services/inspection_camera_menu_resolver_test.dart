import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/services/inspection_camera_menu_resolver.dart';
import 'package:appmobile/services/inspection_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('keeps current environment instance without mixing prior context items', () async {
    final menuService = InspectionMenuService.instance;
    await menuService.ensureLoaded();
    final resolver = InspectionCameraMenuResolver(menuService: menuService);

    final viewState = await resolver.resolve(
      propertyType: 'Urbano',
      subtipo: 'Casa',
      currentKnownAmbientes: const <String>[
        'Quarto',
        'Sala',
        'Quarto 2',
        'Quarto 3',
      ],
      showMacroLocalSelector: true,
      initialLoad: false,
      initialSuggestedSelection: FlowSelection.empty,
      currentSelection: const FlowSelection(
        subjectContext: 'Area interna',
        targetItem: 'Quarto 3',
        targetItemBase: 'Quarto',
        targetItemInstanceIndex: 3,
      ),
    );

    expect(viewState.ambientes, contains('Quarto 3'));
    expect(viewState.ambientes, isNot(contains('Quarto 2')));
    expect(viewState.currentSelection.targetItem, 'Quarto 3');
  });
}
