import 'dart:convert';
import 'dart:io';

import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/services/checkin_dynamic_config_service.dart';
import 'package:crypto/crypto.dart';
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

  test('loadStep1Config resolves levels by subtype when provided', () async {
    final service = CheckinDynamicConfigService.instance;
    await service.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'step1': {
          'tipos': <String>['Urbano'],
          'contextos': <String>['Rua'],
          'levels': [
            {
              'id': 'contexto',
              'label': 'Por onde deseja começar?',
              'required': true,
              'options': <String>['Rua'],
            },
          ],
          'subtiposPorTipo': {
            'Urbano': <String>['Apartamento'],
          },
          'levelsBySubtipo': {
            'Urbano': {
              'Apartamento': [
                {
                  'id': 'torre',
                  'label': 'Torre',
                  'required': false,
                  'options': <String>['A', 'B'],
                },
              ],
            },
          },
        },
      }),
    );

    final result = await service.loadStep1Config(
      fallbackTipos: defaultTipos,
      fallbackSubtiposPorTipo: defaultSubtipos,
      fallbackContextos: defaultContextos,
    );

    expect(
      result.levelsFor(tipo: 'Urbano', subtipo: 'Apartamento').first.id,
      'torre',
    );
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

    expect(serialized['minPhotos'], fallback.minFotos);
    expect(serialized['maxPhotos'], fallback.maxFotos);
    expect(serialized['blocksCapture'], isFalse);
    expect(serialized.containsKey('camposFotos'), isFalse);
    expect(serialized.containsKey('gruposOpcoes'), isFalse);
  });

  test('parseStep2ConfigMap parses visible and required step2 policy', () {
    final service = CheckinDynamicConfigService.instance;
    final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

    final parsed = service.parseStep2ConfigMap(
      tipo: TipoImovel.urbano,
      raw: <String, dynamic>{
        'visivel': false,
        'obrigatoria': true,
        'bloqueiaCaptura': false,
        'camposFotos': <Map<String, dynamic>>[
          {
            'id': 'fachada_dynamic',
            'titulo': 'Fachada dinamica',
            'icon': 'home_work_outlined',
            'obrigatorio': true,
            'cameraMacroLocal': 'Rua',
            'cameraAmbiente': 'Fachada',
          },
        ],
      },
      fallback: fallback,
    );

    expect(parsed.visivelNoFluxo, isFalse);
    expect(parsed.obrigatoriaParaEntrega, isTrue);
    expect(parsed.obrigatoriaNoFluxo, isTrue);
    expect(parsed.bloqueiaCaptura, isFalse);
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

  test(
    'loadStep2Config calls backend with required integration headers',
    () async {
      SharedPreferences.setMockInitialValues({
        'integration_tenant_id_v1': 'tenant-ops',
        'integration_actor_id_v1': 'actor-ops',
        'integration_api_version_v1': 'v1',
      });

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/mobile/checkin-config');
        expect(request.uri.queryParameters['tipoImovel'], 'urbano');
        expect(request.headers.value('X-Tenant-Id'), 'tenant-ops');
        expect(request.headers.value('X-Actor-Id'), 'actor-ops');
        expect(request.headers.value('X-Api-Version'), 'v1');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token-checkin',
        );
        final correlationId = request.headers.value('X-Correlation-Id') ?? '';
        expect(correlationId, startsWith('mob-'));

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'step2': {
              'byTipo': {
                'urbano': {
                  'tituloTela': 'Config remota real',
                  'camposFotos': [
                    {
                      'id': 'fachada_remota',
                      'titulo': 'Fachada remota',
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
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final result = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(result.tituloTela, 'Config remota real');
      expect(result.camposFotos.first.id, 'fachada_remota');
    },
  );

  test(
    'loadStep2Config uses authenticated session headers without token override',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_tenant_id': 'tenant-compass',
        'auth_user_id': '77',
        'auth_access_token': 'session-token',
        'integration_tenant_id_v1': 'tenant-ops',
        'integration_actor_id_v1': 'actor-ops',
        'integration_api_version_v1': 'v1',
      });

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        expect(request.headers.value('X-Tenant-Id'), 'tenant-compass');
        expect(request.headers.value('X-Actor-Id'), '77');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer session-token',
        );

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'step2': {
              'byTipo': {
                'urbano': {
                  'tituloTela': 'Config por sessao',
                  'camposFotos': [
                    {
                      'id': 'fachada_sessao',
                      'titulo': 'Fachada sessao',
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
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final result = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(result.tituloTela, 'Config por sessao');
      expect(result.camposFotos.first.id, 'fachada_sessao');
    },
  );

  test(
    'loadStep2Config sends config package ACK when backend exposes applied package ids',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_tenant_id': 'tenant-compass',
        'auth_user_id': '77',
        'auth_access_token': 'session-token',
      });

      var ackSeen = false;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        if (request.method == 'POST') {
          expect(
            request.uri.path,
            '/api/mobile/config-packages/application-status',
          );
          expect(request.headers.value('X-Tenant-Id'), 'tenant-compass');
          expect(request.headers.value('X-Actor-Id'), '77');
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer session-token',
          );
          final body = jsonDecode(await utf8.decoder.bind(request).join());
          expect(body['packageId'], 'cfg-tenant-compass');
          expect(body['packageVersion'], 'cfg-compass-v1');
          expect(body['status'], 'APPLIED');
          ackSeen = true;

          request.response.statusCode = 202;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'status': 'applied'}));
          await request.response.close();
          return;
        }

        expect(request.method, 'GET');
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'version': 'cfg-compass-v1',
            'appliedPackageIds': <String>['cfg-tenant-compass'],
            'step2': {
              'byTipo': {
                'urbano': {
                  'tituloTela': 'Config com ACK',
                  'camposFotos': [
                    {
                      'id': 'fachada_ack',
                      'titulo': 'Fachada ACK',
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
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final result = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(result.tituloTela, 'Config com ACK');
      expect(ackSeen, isTrue);
    },
  );

  test(
    'loadStep2Config accepts remote payload with valid hmac signature',
    () async {
      const signingKey = 'tenant-hmac-secret';
      SharedPreferences.setMockInitialValues({
        'integration_tenant_id_v1': 'tenant-ops',
        'integration_actor_id_v1': 'actor-ops',
        'integration_api_version_v1': 'v1',
      });

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        final payload = jsonEncode({
          'step2': {
            'byTipo': {
              'urbano': {
                'tituloTela': 'Config assinada',
                'camposFotos': [
                  {
                    'id': 'fachada_assinada',
                    'titulo': 'Fachada assinada',
                    'icon': 'home_work_outlined',
                    'obrigatorio': true,
                    'cameraMacroLocal': 'Rua',
                    'cameraAmbiente': 'Fachada',
                  },
                ],
              },
            },
          },
        });
        final signature = base64Encode(
          Hmac(
            sha256,
            utf8.encode(signingKey),
          ).convert(utf8.encode(payload)).bytes,
        );

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.headers.set('X-Config-Signature', signature);
        request.response.headers.set('X-Config-Signature-Alg', 'hmac-sha256');
        request.response.write(payload);
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
        configSigningHmacKey: signingKey,
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final result = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(result.tituloTela, 'Config assinada');
      expect(result.camposFotos.first.id, 'fachada_assinada');
    },
  );

  test(
    'loadStep2Config rejects remote payload with invalid hmac signature',
    () async {
      const signingKey = 'tenant-hmac-secret';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        final payload = jsonEncode({
          'step2': {
            'byTipo': {
              'urbano': {
                'tituloTela': 'Config invalida',
                'camposFotos': [
                  {
                    'id': 'fachada_invalida',
                    'titulo': 'Fachada invalida',
                    'icon': 'home_work_outlined',
                    'obrigatorio': true,
                    'cameraMacroLocal': 'Rua',
                    'cameraAmbiente': 'Fachada',
                  },
                ],
              },
            },
          },
        });

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.headers.set(
          'X-Config-Signature',
          'assinatura-invalida',
        );
        request.response.headers.set('X-Config-Signature-Alg', 'hmac-sha256');
        request.response.write(payload);
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
        configSigningHmacKey: signingKey,
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final result = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(result.tituloTela, fallback.tituloTela);
      expect(result.camposFotos.first.id, fallback.camposFotos.first.id);
    },
  );

  test(
    'loadStep1Config accepts remote payload with valid hmac signature',
    () async {
      const signingKey = 'tenant-hmac-secret';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        final payload = jsonEncode({
          'version': 'cfg-signed-v1',
          'step1': {
            'tipos': <String>['Comercial'],
            'contextos': <String>['Area interna'],
            'subtiposPorTipo': {
              'Comercial': <String>['Loja'],
            },
          },
        });
        final signature = base64Encode(
          Hmac(
            sha256,
            utf8.encode(signingKey),
          ).convert(utf8.encode(payload)).bytes,
        );

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.headers.set('X-Config-Signature', signature);
        request.response.headers.set('X-Config-Signature-Alg', 'hmac-sha256');
        request.response.write(payload);
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
        configSigningHmacKey: signingKey,
      );

      final result = await service.loadStep1Config(
        fallbackTipos: defaultTipos,
        fallbackSubtiposPorTipo: defaultSubtipos,
        fallbackContextos: defaultContextos,
      );

      expect(result.tipos, <String>['Comercial']);
      expect(result.contextos, <String>['Area interna']);
      expect(result.subtiposPorTipo['Comercial'], <String>['Loja']);
    },
  );

  test(
    'loadStep1Config falls back to cached document when remote signature is invalid',
    () async {
      const signingKey = 'tenant-hmac-secret';
      SharedPreferences.setMockInitialValues({
        'checkin_dynamic_step1_config_v1': jsonEncode({
          'step1': {
            'tipos': <String>['Rural'],
            'contextos': <String>['Estrada'],
            'subtiposPorTipo': {
              'Rural': <String>['Sitio'],
            },
          },
        }),
      });

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        final payload = jsonEncode({
          'version': 'cfg-invalid-signature',
          'step1': {
            'tipos': <String>['Comercial'],
            'contextos': <String>['Area interna'],
            'subtiposPorTipo': {
              'Comercial': <String>['Loja'],
            },
          },
        });

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.headers.set(
          'X-Config-Signature',
          'assinatura-invalida',
        );
        request.response.headers.set('X-Config-Signature-Alg', 'hmac-sha256');
        request.response.write(payload);
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
        configSigningHmacKey: signingKey,
      );

      final result = await service.loadStep1Config(
        fallbackTipos: defaultTipos,
        fallbackSubtiposPorTipo: defaultSubtipos,
        fallbackContextos: defaultContextos,
      );

      expect(result.tipos, <String>['Rural']);
      expect(result.contextos, <String>['Estrada']);
      expect(result.subtiposPorTipo['Rural'], <String>['Sitio']);
    },
  );

  test(
    'loadStep2Config reflects remote rollback on next fetch instead of stale cache',
    () async {
      var requestCount = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        requestCount += 1;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        if (requestCount == 1) {
          request.response.write(
            jsonEncode({
              'version': 'cfg-v1',
              'step2': {
                'byTipo': {
                  'urbano': {
                    'tituloTela': 'Config publicada',
                    'camposFotos': [
                      {
                        'id': 'fachada_publicada',
                        'titulo': 'Fachada publicada',
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
        } else {
          request.response.write(
            jsonEncode({
              'version': 'cfg-v2-rollback',
              'step1': {
                'tipos': <String>['Urbano'],
                'contextos': <String>['Rua'],
                'subtiposPorTipo': {
                  'Urbano': <String>['Casa'],
                },
              },
            }),
          );
        }
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final published = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );
      final rolledBack = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(published.tituloTela, 'Config publicada');
      expect(published.camposFotos.first.id, 'fachada_publicada');
      expect(rolledBack.tituloTela, fallback.tituloTela);
      expect(rolledBack.camposFotos.first.id, fallback.camposFotos.first.id);
    },
  );

  test(
    'loadStep2Config reuses cached payload when remote version is unchanged',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      var requestCount = 0;
      server.listen((request) async {
        requestCount += 1;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        if (requestCount == 1) {
          request.response.write(
            jsonEncode({
              'version': 'cfg-stable-v1',
              'step2': {
                'byTipo': {
                  'urbano': {
                    'tituloTela': 'Config cacheada',
                    'camposFotos': [
                      {
                        'id': 'fachada_cacheada',
                        'titulo': 'Fachada cacheada',
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
        } else {
          request.response.write(
            jsonEncode({
              'version': 'cfg-stable-v1',
              'step2': {
                'byTipo': {
                  'urbano': {
                    'tituloTela': 'Config alterada sem bump',
                    'camposFotos': [
                      {
                        'id': 'fachada_alterada_sem_bump',
                        'titulo': 'Fachada alterada sem bump',
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
        }
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final first = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );
      final second = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(first.tituloTela, 'Config cacheada');
      expect(first.camposFotos.first.id, 'fachada_cacheada');
      expect(second.tituloTela, 'Config cacheada');
      expect(second.camposFotos.first.id, 'fachada_cacheada');
    },
  );

  test(
    'loadStep2Config applies fresh payload when remote version changes',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      var requestCount = 0;
      server.listen((request) async {
        requestCount += 1;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        if (requestCount == 1) {
          request.response.write(
            jsonEncode({
              'version': 'cfg-v1',
              'step2': {
                'byTipo': {
                  'urbano': {
                    'tituloTela': 'Config publicada v1',
                    'camposFotos': [
                      {
                        'id': 'fachada_v1',
                        'titulo': 'Fachada v1',
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
        } else {
          request.response.write(
            jsonEncode({
              'version': 'cfg-v2',
              'step2': {
                'byTipo': {
                  'urbano': {
                    'tituloTela': 'Config publicada v2',
                    'camposFotos': [
                      {
                        'id': 'fachada_v2',
                        'titulo': 'Fachada v2',
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
        }
        await request.response.close();
      });

      final service = CheckinDynamicConfigService(
        baseUrl: 'http://${server.address.host}:${server.port}',
        authToken: 'token-checkin',
        checkinConfigEndpoint: '/api/mobile/checkin-config',
      );
      final fallback = CheckinStep2Configs.byTipo(TipoImovel.urbano);

      final first = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );
      final second = await service.loadStep2Config(
        tipo: TipoImovel.urbano,
        fallback: fallback,
      );

      expect(first.tituloTela, 'Config publicada v1');
      expect(first.camposFotos.first.id, 'fachada_v1');
      expect(second.tituloTela, 'Config publicada v2');
      expect(second.camposFotos.first.id, 'fachada_v2');
    },
  );
}
