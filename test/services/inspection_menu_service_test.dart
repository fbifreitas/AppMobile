import 'dart:convert';

import 'package:appmobile/config/inspection_menu_package.dart';
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

  test('resolves camera level order by subtype from unified package', () async {
    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'camera': {
          'byTipo': {
            'urbano': {
              'levels': [
                {'id': 'macroLocal', 'label': 'Área da foto'},
                {'id': 'ambiente', 'label': 'Local da foto'},
              ],
              'levelsBySubtipo': {
                'Apartamento': [
                  {'id': 'ambiente', 'label': 'Local da foto'},
                  {'id': 'elemento', 'label': 'Elemento'},
                ],
              },
              'macroLocals': [
                {'label': 'Rua', 'baseScore': 100},
              ],
            },
          },
        },
      }),
    );

    final service = InspectionMenuService.instance;
    await service.reload();

    expect(
      await service.getCameraLevelOrder(
        propertyType: 'Urbano',
        subtipo: 'Apartamento',
      ),
      <String>['ambiente', 'elemento'],
    );
  });

  test(
    'falls back to tipo camera levels when subtype is not configured',
    () async {
      await CheckinDynamicConfigService.instance.configureDeveloperMock(
        enabled: true,
        documentJson: jsonEncode({
          'camera': {
            'byTipo': {
              'urbano': {
                'levels': [
                  {'id': 'macroLocal', 'label': 'Área da foto'},
                  {'id': 'ambiente', 'label': 'Local da foto'},
                  {'id': 'elemento', 'label': 'Elemento'},
                ],
                'levelsBySubtipo': {
                  'Apartamento': [
                    {'id': 'ambiente', 'label': 'Local da foto'},
                  ],
                },
                'macroLocals': [
                  {'label': 'Rua', 'baseScore': 100},
                ],
              },
            },
          },
        }),
      );

      final service = InspectionMenuService.instance;
      await service.reload();

      expect(
        await service.getCameraLevelOrder(
          propertyType: 'Urbano',
          subtipo: 'Casa',
        ),
        <String>['macroLocal', 'ambiente', 'elemento'],
      );
    },
  );

  test(
    'returns default camera level order when package has no camera levels',
    () async {
      await CheckinDynamicConfigService.instance.configureDeveloperMock(
        enabled: true,
        documentJson: jsonEncode({
          'camera': {
            'byTipo': {
              'urbano': {
                'macroLocals': [
                  {'label': 'Rua', 'baseScore': 100},
                ],
              },
            },
          },
        }),
      );

      final service = InspectionMenuService.instance;
      await service.reload();

      expect(
        await service.getCameraLevelOrder(
          propertyType: 'Urbano',
          subtipo: 'Casa',
        ),
        <String>['macroLocal', 'ambiente', 'elemento', 'material', 'estado'],
      );
    },
  );

  test('ignores blank camera level ids from package configuration', () async {
    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'camera': {
          'byTipo': {
            'urbano': {
              'levels': [
                {'id': 'macroLocal', 'label': 'Área da foto'},
                {'id': '   ', 'label': 'Inválido'},
                {'id': '', 'label': 'Inválido 2'},
                {'id': 'ambiente', 'label': 'Local da foto'},
              ],
              'macroLocals': [
                {'label': 'Rua', 'baseScore': 100},
              ],
            },
          },
        },
      }),
    );

    final service = InspectionMenuService.instance;
    await service.reload();

    expect(await service.getCameraLevelOrder(propertyType: 'Urbano'), <String>[
      'macroLocal',
      'ambiente',
    ]);
  });

  test('parses unified package with step1 and step2 sections', () {
    final package = InspectionMenuPackage.fromJson({
      'step1': {
        'tipos': ['Urbano'],
        'contextos': ['Interna'],
        'levels': [
          {'id': 'contexto', 'label': 'Contexto', 'required': true},
        ],
        'subtiposPorTipo': {
          'Urbano': ['Apartamento Duplex'],
        },
        'levelsBySubtipo': {
          'Urbano': {
            'Apartamento Duplex': [
              {'id': 'piso', 'label': 'Piso', 'required': true},
            ],
          },
        },
      },
      'step2': {
        'byTipo': {
          'urbano': {
            'tituloTela': 'Etapa 2',
            'camposFotos': [
              {
                'id': 'suite_master',
                'titulo': 'Suite Master',
                'cameraMacroLocal': 'Interna',
                'cameraAmbiente': 'Suite Master',
              },
            ],
          },
        },
      },
      'camera': {
        'byTipo': {
          'urbano': {
            'levels': [
              {'id': 'macroLocal', 'label': 'Área da foto'},
              {'id': 'ambiente', 'label': 'Local da foto'},
            ],
            'levelsBySubtipo': {
              'Apartamento Duplex': [
                {'id': 'piso', 'label': 'Piso', 'required': true},
                {'id': 'ambiente', 'label': 'Local da foto'},
              ],
            },
            'macroLocals': [
              {'label': 'Interna', 'baseScore': 100},
            ],
          },
        },
      },
    });

    expect(package.step1Config, isNotNull);
    expect(package.step1Config!.tipos, <String>['Urbano']);
    expect(package.step1Config!.subtiposPorTipo['Urbano'], <String>[
      'Apartamento Duplex',
    ]);
    expect(package.step2For('urbano'), isNotNull);
    expect(package.configFor('urbano'), isNotNull);
    expect(
      package.step1Config!
          .levelsFor(tipo: 'Urbano', subtipo: 'Apartamento Duplex')
          .first
          .id,
      'piso',
    );
    expect(
      package
          .cameraLevelsFor(
            propertyType: 'urbano',
            subtipo: 'Apartamento Duplex',
          )
          .first
          .id,
      'piso',
    );
  });
}
