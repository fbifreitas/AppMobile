import 'package:appmobile/services/inspection_context_actions_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionContextActionsService.instance;

  test('builds contextual duplicate label from current ambiente', () {
    expect(service.duplicateActionLabelFor('Quarto 2'), 'Novo Quarto');
  });

  test('returns next duplicated ambiente label', () {
    final next = service.nextDuplicatedAmbienteLabel(
      selectedAmbiente: 'Quarto',
      existingLabels: const <String>['Quarto', 'Quarto 2'],
    );

    expect(next, 'Quarto 3');
  });
}
