import 'package:appmobile/services/inspection_environment_instance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionEnvironmentInstanceService.instance;

  group('InspectionEnvironmentInstanceService', () {
    test('parse base label and instance index from suffixed label', () {
      final parsed = service.parse('Quarto 2');

      expect(parsed.baseLabel, 'Quarto');
      expect(parsed.instanceIndex, 2);
      expect(parsed.displayLabel, 'Quarto 2');
    });

    test('parse unsuffixed label as first instance', () {
      final parsed = service.parse('Sala');

      expect(parsed.baseLabel, 'Sala');
      expect(parsed.instanceIndex, 1);
      expect(parsed.displayLabel, 'Sala');
    });

    test('derive next display label from existing instances', () {
      final next = service.nextDisplayLabel(
        selectedLabel: 'Quarto',
        existingLabels: const <String>['Quarto', 'Sala', 'Quarto 2'],
      );

      expect(next, 'Quarto 3');
    });
  });
}
