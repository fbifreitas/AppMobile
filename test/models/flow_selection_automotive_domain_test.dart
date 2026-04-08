/// Structural proof: [FlowSelection] é genuinamente neutro de domínio.
///
/// Os mesmos campos canônicos (subjectContext → targetItem → targetQualifier
/// → targetCondition + domainAttributes) acomodam qualquer domínio de vistoria
/// — imobiliário, automotivo, ou outro — sem alteração de modelo ou código de
/// plataforma. O domínio é apenas o vocabulário aplicado sobre o contrato.
library;

import 'package:appmobile/models/flow_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowSelection — neutralidade de domínio', () {
    test('imobiliário: campos canônicos acomodam vocabulário de inspeção predial', () {
      final selection = FlowSelection(
        subjectContext: 'Área interna',
        targetItem: 'Sala de estar',
        targetQualifier: 'Parede',
        targetCondition: 'Regular',
        domainAttributes: const <String, dynamic>{
          'inspection.material': 'Alvenaria',
        },
      );

      expect(selection.subjectContext, 'Área interna');
      expect(selection.targetItem, 'Sala de estar');
      expect(selection.targetQualifier, 'Parede');
      expect(selection.targetCondition, 'Regular');
      expect(selection.attributeText('inspection.material'), 'Alvenaria');
      expect(selection.hasAnyValue, isTrue);
    });

    test('automotivo: mesmos campos canônicos acomodam vocabulário de vistoria veicular', () {
      final selection = FlowSelection(
        subjectContext: 'Lateral direita',
        targetItem: 'Porta dianteira',
        targetQualifier: 'Painel de lataria',
        targetCondition: 'Amassado',
        domainAttributes: const <String, dynamic>{
          'automotive.damage_code': 'D-001',
        },
      );

      expect(selection.subjectContext, 'Lateral direita');
      expect(selection.targetItem, 'Porta dianteira');
      expect(selection.targetQualifier, 'Painel de lataria');
      expect(selection.targetCondition, 'Amassado');
      expect(selection.attributeText('automotive.damage_code'), 'D-001');
      expect(selection.hasAnyValue, isTrue);
    });

    test('mesma estrutura FlowSelectionState serve os dois domínios sem adaptação de modelo', () {
      FlowSelectionState buildState(FlowSelection selection) =>
          FlowSelectionState(
            initialSuggestedSelection: selection,
            currentSelection: selection,
          );

      final predial = buildState(
        const FlowSelection(
          subjectContext: 'Fachada',
          targetItem: 'Portão',
          targetQualifier: 'Ferragem',
          targetCondition: 'Necessita reparo',
        ),
      );

      final veicular = buildState(
        const FlowSelection(
          subjectContext: 'Frente',
          targetItem: 'Para-choque',
          targetQualifier: 'Suporte inferior',
          targetCondition: 'Trincado',
        ),
      );

      // Ambos usam exatamente o mesmo tipo — nenhuma especialização de modelo
      expect(predial.currentSelection.runtimeType, veicular.currentSelection.runtimeType);
      expect(predial.runtimeType, veicular.runtimeType);

      // Cada domínio preserva seu vocabulário independentemente
      expect(predial.currentSelection.subjectContext, 'Fachada');
      expect(veicular.currentSelection.subjectContext, 'Frente');
    });

    test('toMap canônico não impõe vocabulário de nenhum domínio específico', () {
      final selection = FlowSelection(
        subjectContext: 'Teto',
        targetItem: 'Calha',
        targetCondition: 'Enferrujado',
      );

      final map = selection.toMap(includeCanonical: true);

      // Chaves canônicas neutras presentes
      expect(map.containsKey('subjectContext'), isTrue);
      expect(map.containsKey('targetItem'), isTrue);
      expect(map.containsKey('targetCondition'), isTrue);

      // Nenhuma chave de domínio imobiliário ou automotivo imposta pelo modelo
      expect(map.containsKey('macroLocal'), isFalse);
      expect(map.containsKey('ambiente'), isFalse);
      expect(map.containsKey('elemento'), isFalse);
    });

    test('fromMap restaura qualquer domínio via chaves canônicas', () {
      final original = FlowSelection(
        subjectContext: 'Bloco A',
        targetItem: 'Apartamento 12',
        targetQualifier: 'Banheiro',
        targetCondition: 'Bom',
      );

      final restored = FlowSelection.fromMap(
        original.toMap(includeCanonical: true),
      );

      expect(restored.subjectContext, original.subjectContext);
      expect(restored.targetItem, original.targetItem);
      expect(restored.targetQualifier, original.targetQualifier);
      expect(restored.targetCondition, original.targetCondition);
    });
  });
}
