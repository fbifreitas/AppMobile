import 'dart:convert';

import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/services/checkin_dynamic_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const defaultTipos = <String>['Urbano', 'Rural'];
  const defaultSubtipos = <String, List<String>>{
    'Urbano': <String>['Apartamento'],
    'Rural': <String>['Sitio'],
  };
  const defaultContextos = <String>['Rua'];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadStep1Config returns fallback when cache is absent', () async {
    final service = CheckinDynamicConfigService.instance;

    final result = await service.loadStep1Config(
      fallbackTipos: defaultTipos,
      fallbackSubtiposPorTipo: defaultSubtipos,
      fallbackContextos: defaultContextos,
    );

    expect(result.tipos, defaultTipos);
    expect(result.contextos, defaultContextos);
    expect(result.subtiposPorTipo['Urbano'], <String>['Apartamento']);
  });

  test('loadStep1Config reads cached configuration', () async {
    final cached = {
      'step1': {
        'tipos': <String>['Comercial'],
        'contextos': <String>['Area interna', 'Area externa'],
        'subtiposPorTipo': {
          'Comercial': <String>['Loja', 'Galpao'],
        },
      },
    };

    SharedPreferences.setMockInitialValues({
      'checkin_dynamic_step1_config_v1': jsonEncode(cached),
    });

    final service = CheckinDynamicConfigService.instance;
    final result = await service.loadStep1Config(
      fallbackTipos: defaultTipos,
      fallbackSubtiposPorTipo: defaultSubtipos,
      fallbackContextos: defaultContextos,
    );

    expect(result.tipos, <String>['Comercial']);
    expect(result.contextos, <String>['Area interna', 'Area externa']);
    expect(result.subtiposPorTipo['Comercial'], <String>['Loja', 'Galpao']);
  });

  test('parseStep2ConfigMap parses dynamic photo fields and options', () {
    final service = CheckinDynamicConfigService.instance;
    final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

    final raw = <String, dynamic>{
      'tituloTela': 'Check-in Configuravel',
      'subtituloTela': 'Etapa externa configuravel',
      'camposFotos': <Map<String, dynamic>>[
        {
          'id': 'fachada_nbr',
          'titulo': 'Fachada NBR',
          'icon': 'home_work_outlined',
          'obrigatorio': true,
          'cameraMacroLocal': 'Rua',
          'cameraAmbiente': 'Fachada',
          'cameraElementoInicial': 'Visao geral',
        },
      ],
      'gruposOpcoes': <Map<String, dynamic>>[
        {
          'id': 'infra',
          'titulo': 'Infraestrutura',
          'multiplaEscolha': true,
          'permiteObservacao': true,
          'opcoes': <Map<String, dynamic>>[
            {'id': 'agua', 'label': 'Rede de agua'},
          ],
        },
      ],
    };

    final parsed = service.parseStep2ConfigMap(
      tipo: TipoImovel.urbano,
      raw: raw,
      fallback: fallback,
    );

    expect(parsed.tituloTela, 'Check-in Configuravel');
    expect(parsed.subtituloTela, 'Etapa externa configuravel');
    expect(parsed.camposFotos.length, 1);
    expect(parsed.camposFotos.first.id, 'fachada_nbr');
    expect(parsed.camposFotos.first.obrigatorio, isTrue);
    expect(parsed.gruposOpcoes.length, 1);
    expect(parsed.gruposOpcoes.first.id, 'infra');
    expect(parsed.gruposOpcoes.first.opcoes.first.id, 'agua');
  });

  test(
    'parseStep2ConfigMap returns fallback when dynamic fields are invalid',
    () {
      final service = CheckinDynamicConfigService.instance;
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.rural);

      final parsed = service.parseStep2ConfigMap(
        tipo: TipoImovel.rural,
        raw: const <String, dynamic>{'camposFotos': <Map<String, dynamic>>[]},
        fallback: fallback,
      );

      expect(parsed.tituloTela, fallback.tituloTela);
      expect(parsed.camposFotos.length, fallback.camposFotos.length);
      expect(parsed.camposFotos.first.id, fallback.camposFotos.first.id);
    },
  );

  test('loadStep1Config reads developer mock document when enabled', () async {
    final service = CheckinDynamicConfigService.instance;
    await service.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'step1': {
          'tipos': <String>['Comercial'],
          'contextos': <String>['Área interna'],
          'subtiposPorTipo': {
            'Comercial': <String>['Loja'],
          },
        },
      }),
    );

    final result = await service.loadStep1Config(
      fallbackTipos: defaultTipos,
      fallbackSubtiposPorTipo: defaultSubtipos,
      fallbackContextos: defaultContextos,
    );

    expect(result.tipos, <String>['Comercial']);
    expect(result.contextos, <String>['Área interna']);
    expect(result.subtiposPorTipo['Comercial'], <String>['Loja']);
  });

  test(
    'loadStep2Config resolves byTipo node from developer mock document',
    () async {
      final service = CheckinDynamicConfigService.instance;
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      await service.configureDeveloperMock(
        enabled: true,
        documentJson: jsonEncode({
          'step2': {
            'byTipo': {
              'urbano': {
                'tituloTela': 'Tela dinâmica mock',
                'subtituloTela': 'Subtítulo mock',
                'camposFotos': [
                  {
                    'id': 'fachada_mock',
                    'titulo': 'Fachada mock',
                    'icon': 'home_work_outlined',
                    'obrigatorio': true,
                    'cameraMacroLocal': 'Rua',
                    'cameraAmbiente': 'Fachada',
                  },
                ],
              },
            },
          },
        }),
      );

      final parsed = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(parsed.tituloTela, 'Tela dinâmica mock');
      expect(parsed.camposFotos.first.id, 'fachada_mock');
      expect(parsed.camposFotos.first.obrigatorio, isTrue);
    },
  );

  test('parseStep2ConfigMap parses min/max photos policy', () {
    final service = CheckinDynamicConfigService.instance;
    final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

    final parsed = service.parseStep2ConfigMap(
      tipo: TipoImovel.urbano,
      raw: <String, dynamic>{
        'minFotos': 5,
        'maxFotos': 12,
        'camposFotos': <Map<String, dynamic>>[
          {
            'id': 'fachada_dynamic',
            'titulo': 'Fachada dinâmica',
            'icon': 'home_work_outlined',
            'obrigatorio': true,
            'cameraMacroLocal': 'Rua',
            'cameraAmbiente': 'Fachada',
          },
        ],
      },
      fallback: fallback,
    );

    expect(parsed.minFotos, 5);
    expect(parsed.maxFotos, 12);
  });

  test('serializeStep2Config exports min/max photos policy', () {
    final service = CheckinDynamicConfigService.instance;
    final fallback = CheckinStep2Configs.byTipo(TipoImovel.comercial);

    final serialized = service.serializeStep2Config(fallback);

    expect(serialized['minFotos'], fallback.minFotos);
    expect(serialized['maxFotos'], fallback.maxFotos);
  });

  test(
    'loadDeveloperMockDocument exposes unified developer document',
    () async {
      final service = CheckinDynamicConfigService.instance;

      await service.configureDeveloperMock(
        enabled: true,
        documentJson: jsonEncode({
          'step1': {
            'tipos': <String>['Urbano'],
            'contextos': <String>['Rua'],
            'subtiposPorTipo': {
              'Urbano': <String>['Casa'],
            },
          },
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

      final document = await service.loadDeveloperMockDocument();

      expect(document, isNotNull);
      expect(document!['step1'], isA<Map<String, dynamic>>());
      expect(document['camera'], isA<Map<String, dynamic>>());
    },
  );
}
