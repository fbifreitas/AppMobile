import 'package:appmobile/config/inspection_menu_package.dart';
import 'package:appmobile/services/inspection_menu_intelligence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = InspectionMenuIntelligenceService.instance;

  test('resolves suggested context from confirmed usage snapshot', () {
    final now = DateTime.now().toIso8601String();
    final suggestion = service.getSuggestedContext(
      featureFlags: const FeatureFlagsConfig.fallback(),
      predictionPolicy: const PredictionPolicyConfig.fallback(),
      usage: <String, dynamic>{
        'camera_confirmed.urbano.macro::Área interna': <String, dynamic>{
          'count': 3,
          'lastUsedAt': now,
        },
        'camera_confirmed.urbano.Área interna.ambiente::Sala':
            <String, dynamic>{
              'count': 3,
              'lastUsedAt': now,
            },
      },
      propertyType: 'Urbano',
      availableMacroLocals: const <String>['Área interna', 'Rua'],
      availableAmbientes: const <String>['Sala', 'Quarto'],
    );

    expect(suggestion?.macroLocal, 'Área interna');
    expect(suggestion?.ambiente, 'Sala');
  });

  test('resolves prediction from persisted capture snapshot', () {
    final prediction = service.getPrediction(
      featureFlags: const FeatureFlagsConfig.fallback(),
      predictionPolicy: const PredictionPolicyConfig.fallback(),
      prediction: <String, dynamic>{
        service.predictionContextKey(
          propertyType: 'Urbano',
          macroLocal: 'Área interna',
          ambiente: 'Sala',
        ): <String, dynamic>{
          'captures': 3,
          'lastUsedAt': DateTime.now().toIso8601String(),
          'elementos': <String, dynamic>{'Piso': 3},
          'materiais': <String, dynamic>{'Cerâmico': 2},
          'estados': <String, dynamic>{'Bom': 2},
        },
      },
      propertyType: 'Urbano',
      macroLocal: 'Área interna',
      ambiente: 'Sala',
      availableElementos: const <String>['Piso'],
      availableMateriais: const <String>['Cerâmico'],
      availableEstados: const <String>['Bom'],
    );

    expect(prediction?.elemento, 'Piso');
    expect(prediction?.material, 'Cerâmico');
    expect(prediction?.estado, 'Bom');
  });
}
