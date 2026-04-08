/// BL-069: Testes de InspectionTaxonomyService — flat options + fallback taxonomy.
library;

import 'package:appmobile/services/inspection_taxonomy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionTaxonomyService.instance;

  group('InspectionTaxonomyService — flat review options', () {
    test('environmentOptions contém ambientes imobiliários principais', () {
      expect(
        service.environmentOptions(),
        containsAll(<String>['Fachada', 'Banheiro', 'Garagem']),
      );
    });

    test('elementOptions, materialOptions, stateOptions não estão vazios', () {
      expect(service.elementOptions(), contains('Janela'));
      expect(service.materialOptions(), contains('Madeira'));
      expect(service.stateOptions(), contains('Bom'));
    });
  });

  group('InspectionTaxonomyService — fallbackMacroLocals', () {
    test('urbano retorna Rua, Área externa e Área interna', () {
      final options = service.fallbackMacroLocals('urbano');
      expect(options.map((o) => o.label), containsAll(['Rua', 'Área externa', 'Área interna']));
    });

    test('rural retorna apenas Rua e Área externa', () {
      final options = service.fallbackMacroLocals('rural');
      final labels = options.map((o) => o.label).toList();
      expect(labels, containsAll(['Rua', 'Área externa']));
      expect(labels, isNot(contains('Área interna')));
    });

    test('propertyType em maiúsculas é normalizado', () {
      final options = service.fallbackMacroLocals('URBANO');
      expect(options.map((o) => o.label), contains('Área interna'));
    });
  });

  group('InspectionTaxonomyService — fallbackAmbientes', () {
    test('Rua urbano retorna Fachada e Logradouro', () {
      final options = service.fallbackAmbientes('urbano', 'Rua');
      expect(options.map((o) => o.label), containsAll(['Fachada', 'Logradouro']));
    });

    test('Rua rural retorna Acesso principal', () {
      final options = service.fallbackAmbientes('rural', 'Rua');
      expect(options.map((o) => o.label), contains('Acesso principal'));
    });

    test('Área externa retorna Garagem', () {
      final options = service.fallbackAmbientes('urbano', 'Área externa');
      expect(options.map((o) => o.label), contains('Garagem'));
    });

    test('macroLocal desconhecido retorna Sala como default', () {
      final options = service.fallbackAmbientes('urbano', 'Outro');
      expect(options.map((o) => o.label), contains('Sala'));
    });
  });

  group('InspectionTaxonomyService — fallbackElementos', () {
    test('Fachada retorna Visão geral e Número', () {
      final options = service.fallbackElementos('Fachada');
      expect(options.map((o) => o.label), containsAll(['Visão geral', 'Número']));
    });

    test('Sala retorna Piso, Parede e Teto', () {
      final options = service.fallbackElementos('Sala');
      expect(options.map((o) => o.label), containsAll(['Piso', 'Parede', 'Teto']));
    });

    test('ambiente desconhecido retorna Visão geral e Outro elemento', () {
      final options = service.fallbackElementos('Desconhecido');
      final labels = options.map((o) => o.label).toList();
      expect(labels, contains('Visão geral'));
      expect(labels, contains('Outro elemento'));
    });
  });

  group('InspectionTaxonomyService — fallbackMateriais', () {
    test('Piso retorna Cerâmico e Madeira', () {
      final options = service.fallbackMateriais('Piso');
      expect(options.map((o) => o.label), containsAll(['Cerâmico', 'Madeira']));
    });

    test('elemento desconhecido retorna lista vazia', () {
      expect(service.fallbackMateriais('Desconhecido'), isEmpty);
    });
  });

  group('InspectionTaxonomyService — fallbackEstados', () {
    test('retorna estados de condição padrão', () {
      final labels = service.fallbackEstados().map((o) => o.label).toList();
      expect(labels, containsAll(['Bom', 'Regular', 'Ruim']));
    });

    test('Novo está presente com maior score', () {
      final estados = service.fallbackEstados();
      expect(estados.first.label, 'Novo');
    });
  });
}
