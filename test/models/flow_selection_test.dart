import 'package:appmobile/models/flow_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports a second domain without inspection-centric fields', () {
    const selection = FlowSelection(
      subjectContext: 'lateral_direita',
      targetItem: 'porta_dianteira',
      targetQualifier: 'lataria',
      targetCondition: 'amassado',
    );

    final serialized = selection.toMap();
    final hydrated = FlowSelection.fromMap(serialized);

    expect(hydrated.subjectContext, 'lateral_direita');
    expect(hydrated.targetItem, 'porta_dianteira');
    expect(hydrated.targetQualifier, 'lataria');
    expect(hydrated.targetCondition, 'amassado');
    expect(serialized.containsKey('macroLocal'), isFalse);
    expect(serialized.containsKey('ambiente'), isFalse);
  });

  test('keeps legacy inspection payload compatibility through adapter fields', () {
    final hydrated = FlowSelection.fromMap(const <String, dynamic>{
      'macroLocal': 'Interna',
      'ambiente': 'Quarto 2',
      'ambienteBase': 'Quarto',
      'ambienteInstanceIndex': 2,
      'elemento': 'Janela',
      'material': 'Madeira',
      'estado': 'Bom',
    });

    expect(hydrated.subjectContext, 'Interna');
    expect(hydrated.targetItem, 'Quarto 2');
    expect(hydrated.targetItemBase, 'Quarto');
    expect(hydrated.targetItemInstanceIndex, 2);
    expect(hydrated.targetQualifier, 'Janela');
    expect(hydrated.targetCondition, 'Bom');
    expect(hydrated.attributeText('inspection.material'), 'Madeira');
  });
}
