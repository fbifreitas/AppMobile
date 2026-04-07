import 'package:appmobile/config/inspection_menu_package.dart';
import 'package:appmobile/services/inspection_menu_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionMenuCatalogService.instance;

  test('returns fallback macro locals when package is missing', () {
    expect(
      service.macroLocals(
        package: null,
        usage: const <String, dynamic>{},
        propertyType: 'Urbano',
      ),
      <String>['Rua', 'Área externa', 'Área interna'],
    );
  });

  test('resolves configured hierarchy before fallback catalog', () {
    final package = InspectionMenuPackage.fromJson({
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
    });

    expect(
      service.ambientes(
        package: package,
        usage: const <String, dynamic>{},
        propertyType: 'Urbano',
        macroLocal: 'Rua',
      ),
      <String>['Fachada'],
    );
    expect(
      service.elementos(
        package: package,
        usage: const <String, dynamic>{},
        propertyType: 'Urbano',
        macroLocal: 'Rua',
        ambiente: 'Fachada',
      ),
      <String>['Portão'],
    );
    expect(
      service.materiais(
        package: package,
        usage: const <String, dynamic>{},
        propertyType: 'Urbano',
        macroLocal: 'Rua',
        ambiente: 'Fachada',
        elemento: 'Portão',
      ),
      <String>['Metal'],
    );
    expect(
      service.estados(
        package: package,
        usage: const <String, dynamic>{},
        propertyType: 'Urbano',
        macroLocal: 'Rua',
        ambiente: 'Fachada',
        elemento: 'Portão',
      ),
      <String>['Bom'],
    );
  });
}
