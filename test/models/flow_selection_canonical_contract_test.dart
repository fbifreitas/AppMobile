/// BL-069: Testes de unidade — contrato canônico de FlowSelection e FlowSelectionState.
library;

import 'package:appmobile/models/flow_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowSelection — copyWith', () {
    const base = FlowSelection(
      subjectContext: 'Área interna',
      targetItem: 'Sala',
      targetItemBase: 'Sala',
      targetItemInstanceIndex: 1,
      targetQualifier: 'Parede',
      targetCondition: 'Regular',
      domainAttributes: <String, dynamic>{'inspection.material': 'Alvenaria'},
    );

    test('mantém campos não tocados', () {
      final copy = base.copyWith(targetCondition: 'Bom');
      expect(copy.subjectContext, 'Área interna');
      expect(copy.targetItem, 'Sala');
      expect(copy.targetQualifier, 'Parede');
      expect(copy.targetCondition, 'Bom');
      expect(copy.attributeText('inspection.material'), 'Alvenaria');
    });

    test('clearTargetItem limpa targetItem e dependentes', () {
      final copy = base.copyWith(
        clearTargetItem: true,
        clearTargetItemBase: true,
        clearTargetItemInstanceIndex: true,
        clearTargetQualifier: true,
        clearTargetCondition: true,
        clearDomainAttributes: true,
      );
      expect(copy.subjectContext, 'Área interna');
      expect(copy.targetItem, isNull);
      expect(copy.targetItemBase, isNull);
      expect(copy.targetItemInstanceIndex, isNull);
      expect(copy.targetQualifier, isNull);
      expect(copy.targetCondition, isNull);
      expect(copy.domainAttributes, isEmpty);
    });

    test('clearSubjectContext limpa subjectContext', () {
      final copy = base.copyWith(clearSubjectContext: true);
      expect(copy.subjectContext, isNull);
      expect(copy.targetItem, 'Sala');
    });
  });

  group('FlowSelection — hasAnyValue', () {
    test('empty retorna false', () {
      expect(FlowSelection.empty.hasAnyValue, isFalse);
    });

    test('apenas subjectContext já torna verdadeiro', () {
      expect(
        const FlowSelection(subjectContext: 'X').hasAnyValue,
        isTrue,
      );
    });

    test('apenas domainAttribute torna verdadeiro', () {
      expect(
        const FlowSelection(
          domainAttributes: <String, dynamic>{'k': 'v'},
        ).hasAnyValue,
        isTrue,
      );
    });
  });

  group('FlowSelection — attributeText', () {
    test('retorna null para chave ausente', () {
      expect(FlowSelection.empty.attributeText('any'), isNull);
    });

    test('retorna null para valor null', () {
      const sel = FlowSelection(
        domainAttributes: <String, dynamic>{'k': null},
      );
      expect(sel.attributeText('k'), isNull);
    });

    test('retorna null para string vazia', () {
      const sel = FlowSelection(
        domainAttributes: <String, dynamic>{'k': ''},
      );
      expect(sel.attributeText('k'), isNull);
    });

    test('retorna valor texto presente', () {
      const sel = FlowSelection(
        domainAttributes: <String, dynamic>{'inspection.material': 'Cerâmica'},
      );
      expect(sel.attributeText('inspection.material'), 'Cerâmica');
    });
  });

  group('FlowSelection — toMap / fromMap (round-trip)', () {
    final original = FlowSelection(
      subjectContext: 'Rua',
      targetItem: 'Fachada 2',
      targetItemBase: 'Fachada',
      targetItemInstanceIndex: 2,
      targetQualifier: 'Porta',
      targetCondition: 'Bom',
      domainAttributes: const <String, dynamic>{'inspection.material': 'Madeira'},
    );

    test('round-trip canônico preserva todos os campos', () {
      final map = original.toMap(includeCanonical: true);
      final restored = FlowSelection.fromMap(map);
      expect(restored.subjectContext, original.subjectContext);
      expect(restored.targetItem, original.targetItem);
      expect(restored.targetItemBase, original.targetItemBase);
      expect(restored.targetItemInstanceIndex, original.targetItemInstanceIndex);
      expect(restored.targetQualifier, original.targetQualifier);
      expect(restored.targetCondition, original.targetCondition);
      expect(
        restored.attributeText('inspection.material'),
        original.attributeText('inspection.material'),
      );
    });

    test('toMap com includeLegacy emite chaves legacy', () {
      final map = original.toMap(includeCanonical: true, includeLegacy: true);
      expect(map['macroLocal'], 'Rua');
      expect(map['ambiente'], 'Fachada 2');
      expect(map['elemento'], 'Porta');
      expect(map['material'], 'Madeira');
      expect(map['estado'], 'Bom');
    });

    test('fromMap lê chaves legacy (backward compat)', () {
      final legacyMap = <String, dynamic>{
        'macroLocal': 'Área interna',
        'ambiente': 'Quarto',
        'elemento': 'Piso',
        'material': 'Cerâmico',
        'estado': 'Regular',
      };
      final sel = FlowSelection.fromMap(legacyMap);
      expect(sel.subjectContext, 'Área interna');
      expect(sel.targetItem, 'Quarto');
      expect(sel.targetQualifier, 'Piso');
      expect(sel.targetCondition, 'Regular');
      expect(sel.attributeText('inspection.material'), 'Cerâmico');
    });

    test('toMap sem includeLegacy não emite chaves legadas', () {
      final map = original.toMap(includeCanonical: true, includeLegacy: false);
      expect(map.containsKey('macroLocal'), isFalse);
      expect(map.containsKey('ambiente'), isFalse);
      expect(map.containsKey('elemento'), isFalse);
      expect(map.containsKey('material'), isFalse);
    });
  });

  group('FlowSelectionState — bootstrap e copyWith', () {
    test('bootstrap retorna estado vazio', () {
      final state = FlowSelectionState.bootstrap();
      expect(state.initialSuggestedSelection.hasAnyValue, isFalse);
      expect(state.currentSelection.hasAnyValue, isFalse);
      expect(state.resumeSelection, isNull);
    });

    test('copyWith preserva initialSuggested ao mudar currentSelection', () {
      final initial = const FlowSelection(subjectContext: 'Sugerido');
      final state = FlowSelectionState(
        initialSuggestedSelection: initial,
        currentSelection: FlowSelection.empty,
      );
      final updated = state.copyWith(
        currentSelection: const FlowSelection(subjectContext: 'Atual'),
      );
      expect(updated.initialSuggestedSelection.subjectContext, 'Sugerido');
      expect(updated.currentSelection.subjectContext, 'Atual');
    });

    test('clearResume remove resumeSelection', () {
      final state = FlowSelectionState(
        initialSuggestedSelection: FlowSelection.empty,
        currentSelection: FlowSelection.empty,
        resumeSelection: const FlowSelection(subjectContext: 'Resume'),
      );
      final cleared = state.copyWith(clearResumeSelection: true);
      expect(cleared.resumeSelection, isNull);
    });
  });
}
