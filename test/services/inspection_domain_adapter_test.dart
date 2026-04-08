/// BL-069: Contrato do InspectionDomainAdapter — tradução FlowSelection ↔ InspectionCaptureContext.
library;

import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/inspection_capture_context.dart';
import 'package:appmobile/services/inspection_domain_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = InspectionDomainAdapter.instance;

  group('InspectionDomainAdapter — toInspectionContext', () {
    test('converte FlowSelection completo para InspectionCaptureContext', () {
      final selection = FlowSelection(
        subjectContext: 'Área interna',
        targetItem: 'Sala 2',
        targetItemBase: 'Sala',
        targetItemInstanceIndex: 2,
        targetQualifier: 'Piso',
        targetCondition: 'Regular',
        domainAttributes: const <String, dynamic>{
          'inspection.material': 'Cerâmico',
        },
      );

      final ctx = adapter.toInspectionContext(selection);

      expect(ctx.macroLocal, 'Área interna');
      expect(ctx.ambiente, 'Sala 2');
      expect(ctx.ambienteBase, 'Sala');
      expect(ctx.ambienteInstanceIndex, 2);
      expect(ctx.elemento, 'Piso');
      expect(ctx.estado, 'Regular');
      expect(ctx.material, 'Cerâmico');
    });

    test('converte FlowSelection vazio para contexto sem valores', () {
      final ctx = adapter.toInspectionContext(FlowSelection.empty);
      expect(ctx.hasAnyValue, isFalse);
    });
  });

  group('InspectionDomainAdapter — inspectionMaterialOf', () {
    test('lê material de domainAttributes', () {
      final selection = FlowSelection(
        domainAttributes: const <String, dynamic>{
          'inspection.material': 'Madeira',
        },
      );
      expect(adapter.inspectionMaterialOf(selection), 'Madeira');
    });

    test('retorna null quando material ausente', () {
      expect(adapter.inspectionMaterialOf(FlowSelection.empty), isNull);
    });
  });

  group('InspectionDomainAdapter — duplicateActionLabelFor', () {
    test('prefixo feminino para ambientes terminados em a', () {
      expect(adapter.duplicateActionLabelFor('Sala'), 'Nova Sala');
    });

    test('prefixo masculino para ambientes não terminados em a', () {
      expect(adapter.duplicateActionLabelFor('Quarto'), 'Novo Quarto');
    });

    test('retorna null para targetItem nulo ou vazio', () {
      expect(adapter.duplicateActionLabelFor(null), isNull);
      expect(adapter.duplicateActionLabelFor(''), isNull);
    });
  });

  group('InspectionDomainAdapter — taxonomy options delegam a InspectionTaxonomyService', () {
    test('environmentOptions não está vazio', () {
      expect(adapter.environmentOptions(), isNotEmpty);
    });

    test('elementOptions contém Piso', () {
      expect(adapter.elementOptions(), contains('Piso'));
    });

    test('materialOptions contém Madeira', () {
      expect(adapter.materialOptions(), contains('Madeira'));
    });

    test('stateOptions contém Bom', () {
      expect(adapter.stateOptions(), contains('Bom'));
    });
  });

  group('InspectionCaptureContext — round-trip via FlowSelection', () {
    test('selection getter e fromCanonical são inversos', () {
      final ctx = InspectionCaptureContext(
        macroLocal: 'Rua',
        ambiente: 'Fachada',
        ambienteBase: 'Fachada',
        elemento: 'Porta',
        material: 'Madeira',
        estado: 'Bom',
      );

      final selection = ctx.selection;
      final restored = InspectionCaptureContext.canonical(
        subjectContext: selection.subjectContext,
        targetItem: selection.targetItem,
        targetItemBase: selection.targetItemBase,
        targetQualifier: selection.targetQualifier,
        targetCondition: selection.targetCondition,
        domainAttributes: selection.domainAttributes,
      );

      expect(restored.macroLocal, ctx.macroLocal);
      expect(restored.ambiente, ctx.ambiente);
      expect(restored.elemento, ctx.elemento);
      expect(restored.material, ctx.material);
      expect(restored.estado, ctx.estado);
    });
  });
}
