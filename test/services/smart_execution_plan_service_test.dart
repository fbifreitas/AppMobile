import 'dart:convert';
import 'dart:io';

import 'package:appmobile/models/smart_execution_plan.dart';
import 'package:appmobile/services/smart_execution_plan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads execution plan with authenticated mobile headers', () async {
    SharedPreferences.setMockInitialValues({
      'auth_tenant_id': 'tenant-smart',
      'auth_user_id': '91',
      'auth_access_token': 'smart-token',
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/mobile/jobs/321/execution-plan');
      expect(request.headers.value('X-Tenant-Id'), 'tenant-smart');
      expect(request.headers.value('X-Actor-Id'), '91');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer smart-token',
      );

      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'snapshotId': 7,
          'caseId': 99,
          'status': 'PUBLISHED',
          'plan': {
            'assetType': 'RESIDENTIAL',
            'assetSubtype': 'Apartamento',
            'requiresManualReview': false,
            'propertyProfile': {
              'taxonomy': 'RESIDENTIAL_VERTICAL',
              'canonicalAssetType': 'Urbano',
              'canonicalAssetSubtype': 'Apartamento',
              'refinedAssetSubtype': 'Apartamento',
              'propertyStandard': 'Padrao',
              'availablePhotoLocations': ['Cozinha', 'Sala de estar'],
            },
            'step1Config': {
              'initialAssetType': 'Urbano',
              'initialAssetSubtype': 'Apartamento',
              'candidateAssetSubtypes': ['Apartamento', 'Duplex'],
              'initialContext': 'Rua',
              'availableContexts': ['Rua', 'Area interna', 'Area externa'],
            },
            'step2Config': {
              'requiredEvidence': ['front_elevation', 'access_point'],
            },
            'cameraConfig': {
              'mode': 'guided',
              'availableMacroLocations': ['Rua', 'Area interna', 'Area externa'],
              'suggestedPhotoLocations': ['Cozinha', 'Sala de estar'],
              'capturePlan': [
                {
                  'macroLocal': 'Rua',
                  'environment': 'Fachada',
                  'element': 'Porta',
                  'material': 'Concrete',
                  'condition': 'Good',
                  'required': true,
                  'minPhotos': 2,
                  'source': 'HYBRID',
                  'normativeBindings': [
                    {
                      'dimension': 'IDENTIFICACAO_EXTERNA',
                      'title': 'Identificacao externa',
                      'requiredWhenEnabled': true,
                      'blockingOnFinalization': true,
                      'minPhotos': 2,
                      'acceptedAlternatives': ['Fachada + Numero'],
                    },
                  ],
                },
              ],
              'compositionProfiles': [
                {
                  'macroLocal': 'Rua',
                  'photoLocation': 'Logradouro',
                  'required': true,
                  'minPhotos': 1,
                  'source': 'NORMATIVE',
                  'normativeBindings': [
                    {
                      'dimension': 'IDENTIFICACAO_EXTERNA',
                      'title': 'Identificacao externa',
                      'requiredWhenEnabled': true,
                      'blockingOnFinalization': true,
                      'minPhotos': 1,
                      'acceptedAlternatives': ['Logradouro'],
                    },
                  ],
                  'elements': [
                    {
                      'element': 'Visao geral',
                      'materials': [],
                      'states': ['Bom'],
                    },
                  ],
                },
              ],
            },
            'reviewReasons': ['INSUFFICIENT_STRUCTURAL_EVIDENCE_FOR_SUBTYPE'],
          },
        }),
      );
      await request.response.close();
    });

    final service = SmartExecutionPlanService(
      baseUrl: 'http://${server.address.host}:${server.port}',
    );

    final plan = await service.fetchForJob('321');

    expect(plan, isNotNull);
    expect(plan, isA<SmartExecutionPlan>());
    expect(plan!.snapshotId, 7);
    expect(plan.caseId, 99);
    expect(plan.jobId, '321');
    expect(plan.propertyTaxonomy, 'RESIDENTIAL_VERTICAL');
    expect(plan.initialAssetType, 'Urbano');
    expect(plan.initialAssetSubtype, 'Apartamento');
    expect(plan.propertyStandard, 'Padrao');
    expect(plan.initialContext, 'Rua');
    expect(plan.availableContexts, ['Rua', 'Area interna', 'Area externa']);
    expect(plan.candidateAssetSubtypes, ['Apartamento', 'Duplex']);
    expect(plan.cameraMode, 'guided');
    expect(plan.availableMacroLocations, ['Rua', 'Area interna', 'Area externa']);
    expect(plan.firstEnvironment, 'Fachada');
    expect(plan.firstElement, 'Porta');
    expect(plan.firstMaterial, 'Concrete');
    expect(plan.firstCondition, 'Good');
    expect(plan.suggestedPhotoLocations, contains('Cozinha'));
    expect(plan.compositionProfiles, hasLength(1));
    expect(plan.compositionProfiles.single.photoLocation, 'Logradouro');
    expect(plan.compositionProfiles.single.source, 'NORMATIVE');
    expect(plan.capturePlan.single.source, 'HYBRID');
    expect(
      plan.capturePlan.single.normativeBindings.single.dimension,
      'IDENTIFICACAO_EXTERNA',
    );
    expect(plan.capturePlan, hasLength(1));
    expect(plan.capturePlan.single.macroLocal, 'Rua');
    expect(plan.capturePlan.single.required, isTrue);
    expect(plan.capturePlan.single.minPhotos, 2);
    expect(plan.requiredEvidenceCount, 2);
    expect(plan.requiresManualReview, isFalse);
    expect(
      plan.reviewReasons,
      ['INSUFFICIENT_STRUCTURAL_EVIDENCE_FOR_SUBTYPE'],
    );
  });

  test('returns null when execution plan is not found', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      request.response.statusCode = 404;
      await request.response.close();
    });

    final service = SmartExecutionPlanService(
      baseUrl: 'http://${server.address.host}:${server.port}',
    );

    expect(await service.fetchForJob('404'), isNull);
  });
}
