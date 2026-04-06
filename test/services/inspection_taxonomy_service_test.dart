import 'package:appmobile/services/inspection_taxonomy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionTaxonomyService.instance;

  test('exposes inspection review environment options', () {
    expect(
      service.environmentOptions(),
      containsAll(<String>['Fachada', 'Banheiro']),
    );
  });

  test('exposes inspection review classification options', () {
    expect(service.elementOptions(), contains('Janela'));
    expect(service.materialOptions(), contains('Madeira'));
    expect(service.stateOptions(), contains('Bom'));
  });
}
