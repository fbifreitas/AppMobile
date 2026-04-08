/// Structural proof: [FlowSelection] suporta um segundo domínio (automotivo)
/// sem nenhuma dependência de código de inspeção.
///
/// Valida que o contrato canônico é genuinamente agnóstico de domínio:
/// qualquer domínio de campo (inspeção, automotivo, etc.) é apenas
/// uma especialização — a plataforma não precisa conhecer os termos de domínio.
library;

import 'package:appmobile/models/flow_selection.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Automotive Domain Pack (inline — sem arquivo de produção necessário)
// Prova que um Domain Pack pode ser criado com o contrato canônico puro.
// ---------------------------------------------------------------------------

/// Vocabulário do domínio automotivo mapeado sobre [FlowSelection]:
///   subjectContext   → lado do veículo  (ex.: "lateral_direita")
///   targetItem       → componente       (ex.: "porta_dianteira")
///   targetQualifier  → parte do componente (ex.: "painel_lataria")
///   targetCondition  → estado encontrado   (ex.: "amassado")
///   domainAttributes → extras do domínio   (ex.: "automotive.damage_code")
abstract final class AutomotiveDomainKeys {
  static const String damageCode = 'automotive.damage_code';
  static const String mileage = 'automotive.mileage';
}

FlowSelectionState automotiveSelection({
  String? side,
  String? component,
  String? part,
  String? condition,
  String? damageCode,
  int? mileage,
}) {
  final domainAttributes = <String, dynamic>{
    if (damageCode != null) AutomotiveDomainKeys.damageCode: damageCode,
    if (mileage != null) AutomotiveDomainKeys.mileage: mileage,
  };
  final selection = FlowSelection(
    subjectContext: side,
    targetItem: component,
    targetQualifier: part,
    targetCondition: condition,
    domainAttributes: domainAttributes,
  );
  return FlowSelectionState(
    initialSuggestedSelection: selection,
    currentSelection: selection,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FlowSelection — automotive domain proof', () {
    test('canonical fields carry automotive vocabulary without inspection imports', () {
      final state = automotiveSelection(
        side: 'lateral_direita',
        component: 'porta_dianteira',
        part: 'painel_lataria',
        condition: 'amassado',
        damageCode: 'D-001',
        mileage: 45000,
      );

      final current = state.currentSelection;

      expect(current.subjectContext, 'lateral_direita');
      expect(current.targetItem, 'porta_dianteira');
      expect(current.targetQualifier, 'painel_lataria');
      expect(current.targetCondition, 'amassado');
      expect(current.attributeText(AutomotiveDomainKeys.damageCode), 'D-001');
      expect(current.attributeText(AutomotiveDomainKeys.mileage), '45000');
      expect(current.hasAnyValue, isTrue);
    });

    test('copyWith transitions mirror domain-agnostic step-by-step selection', () {
      // Passo 1: selecionar lado
      FlowSelectionState state = FlowSelectionState.bootstrap();
      state = state.copyWith(
        currentSelection: state.currentSelection.copyWith(
          subjectContext: 'frente',
          clearTargetItem: true,
          clearTargetQualifier: true,
          clearTargetCondition: true,
          clearDomainAttributes: true,
        ),
      );
      expect(state.currentSelection.subjectContext, 'frente');
      expect(state.currentSelection.targetItem, isNull);

      // Passo 2: selecionar componente
      state = state.copyWith(
        currentSelection: state.currentSelection.copyWith(
          targetItem: 'para-choque',
          clearTargetQualifier: true,
          clearTargetCondition: true,
        ),
      );
      expect(state.currentSelection.targetItem, 'para-choque');
      expect(state.currentSelection.targetQualifier, isNull);

      // Passo 3: selecionar parte
      state = state.copyWith(
        currentSelection: state.currentSelection.copyWith(
          targetQualifier: 'suporte_inferior',
          clearTargetCondition: true,
        ),
      );
      expect(state.currentSelection.targetQualifier, 'suporte_inferior');

      // Passo 4: selecionar condição
      state = state.copyWith(
        currentSelection: state.currentSelection.copyWith(
          targetCondition: 'trincado',
        ),
      );
      expect(state.currentSelection.targetCondition, 'trincado');

      // Estado final completo
      final s = state.currentSelection;
      expect(s.subjectContext, 'frente');
      expect(s.targetItem, 'para-choque');
      expect(s.targetQualifier, 'suporte_inferior');
      expect(s.targetCondition, 'trincado');
    });

    test('toMap round-trips through fromMap preserving automotive values', () {
      final state = automotiveSelection(
        side: 'lateral_esquerda',
        component: 'retrovisor',
        part: 'espelho',
        condition: 'quebrado',
        damageCode: 'D-007',
      );

      final map = state.currentSelection.toMap(includeCanonical: true);
      final restored = FlowSelection.fromMap(map);

      expect(restored.subjectContext, 'lateral_esquerda');
      expect(restored.targetItem, 'retrovisor');
      expect(restored.targetQualifier, 'espelho');
      expect(restored.targetCondition, 'quebrado');
      expect(restored.attributeText(AutomotiveDomainKeys.damageCode), 'D-007');
    });

    test('two domains coexist in isolation — automotive map has no inspection keys', () {
      final automotive = automotiveSelection(
        side: 'teto',
        component: 'calha_chuva',
        condition: 'enferrujado',
        damageCode: 'D-012',
      );

      final map = automotive.currentSelection.toMap(includeCanonical: true);

      // Canonical keys present
      expect(map.containsKey('subjectContext'), isTrue);
      expect(map.containsKey('targetItem'), isTrue);
      expect(map.containsKey('targetCondition'), isTrue);

      // No inspection legacy keys leaked into a non-legacy map
      expect(map.containsKey('macroLocal'), isFalse);
      expect(map.containsKey('ambiente'), isFalse);
      expect(map.containsKey('elemento'), isFalse);
      expect(map.containsKey('material'), isFalse);
      expect(map.containsKey('estado'), isFalse);
    });

    test('empty selection has no value regardless of domain', () {
      expect(FlowSelection.empty.hasAnyValue, isFalse);
      expect(FlowSelectionState.bootstrap().currentSelection.hasAnyValue, isFalse);
    });
  });
}
