import 'dart:convert';

import 'package:appmobile/services/checkin_dynamic_config_service.dart';
import 'package:appmobile/services/inspection_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: false,
      documentJson: null,
    );
    await InspectionMenuService.instance.reload();
  });

  test('reads camera hierarchy from unified developer mock document', () async {
    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'camera': {
          'byTipo': {
            'urbano': {
              'macroLocals': [
                {
                  'label': 'Rua',
                  'baseScore': 100,
                  'ambientes': [
                    {
                      'label': 'Fachada',
                      'baseScore': 100,
                      'elements': [
                        {
                          'label': 'Portão',
                          'baseScore': 100,
                          'materials': [
                            {'label': 'Metal', 'baseScore': 100},
                          ],
                          'states': [
                            {'label': 'Bom', 'baseScore': 100},
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          },
        },
      }),
    );

    final service = InspectionMenuService.instance;
    await service.reload();

    expect(await service.getMacroLocals(propertyType: 'Urbano'), <String>[
      'Rua',
    ]);
    expect(
      await service.getAmbientes(propertyType: 'Urbano', macroLocal: 'Rua'),
      <String>['Fachada'],
    );
    expect(
      await service.getElementos(
        propertyType: 'Urbano',
        macroLocal: 'Rua',
        ambiente: 'Fachada',
      ),
      <String>['Portão'],
    );
    expect(
      await service.getMateriais(
        propertyType: 'Urbano',
        macroLocal: 'Rua',
        ambiente: 'Fachada',
        elemento: 'Portão',
      ),
      <String>['Metal'],
    );
    expect(
      await service.getEstados(
        propertyType: 'Urbano',
        macroLocal: 'Rua',
        ambiente: 'Fachada',
        elemento: 'Portão',
      ),
      <String>['Bom'],
    );
  });
}
