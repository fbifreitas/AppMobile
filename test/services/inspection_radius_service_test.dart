import 'package:appmobile/services/inspection_radius_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionRadiusService();

  test('returns 500m for casa urbana', () {
    final info = service.resolve(
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
    );

    expect(info.radiusMeters, 500);
    expect(info.label, 'Raio Casa: 500m');
  });

  test('returns 5000m for fazenda rural', () {
    final info = service.resolve(
      tipoImovel: 'Rural',
      subtipoImovel: 'Fazenda',
    );

    expect(info.radiusMeters, 5000);
    expect(info.label, 'Raio Fazenda: 5000m');
  });

  test('falls back to type rule when subtype is missing', () {
    final info = service.resolve(
      tipoImovel: 'Industrial',
      subtipoImovel: null,
    );

    expect(info.radiusMeters, 600);
  });

  test('falls back to default rule when type is unknown', () {
    final info = service.resolve(
      tipoImovel: 'Outro',
      subtipoImovel: 'Qualquer',
    );

    expect(info.radiusMeters, 100);
    expect(info.label, 'Raio padrão: 100m');
  });

  test('identifies outside radius correctly', () {
    final allowed = service.isWithinRadius(
      distanceMeters: 750,
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
    );

    expect(allowed, isFalse);
  });
}
