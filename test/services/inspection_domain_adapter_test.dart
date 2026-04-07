import 'package:appmobile/services/inspection_domain_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = InspectionDomainAdapter.instance;

  test('exposes clean taxonomy labels for review dropdowns', () {
    expect(adapter.environmentOptions(), containsAll(<String>[
      'Acesso ao imóvel',
      'Dormitório',
      'Área de serviço',
    ]));
    expect(adapter.elementOptions(), containsAll(<String>[
      'Visão geral',
      'Portão',
    ]));
    expect(adapter.materialOptions(), contains('Cerâmica'));
    expect(adapter.stateOptions(), contains('Não se aplica'));
  });

  test('builds contextual duplicate action label without leaking core semantics', () {
    expect(adapter.duplicateActionLabelFor('Quarto'), 'Novo Quarto');
    expect(adapter.duplicateActionLabelFor('Sala'), 'Nova Sala');
  });
}
