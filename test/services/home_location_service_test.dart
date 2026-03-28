import 'package:appmobile/models/home_location_snapshot.dart';
import 'package:appmobile/services/home_location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomeLocationService returns success snapshot', () async {
    const service = HomeLocationService();

    double? writtenLatitude;
    double? writtenLongitude;

    final result = await service.refresh(
      current: HomeLocationSnapshot.initial(),
      readCurrentLocation: () async {
        return const HomeLocationPoint(
          latitude: -23.550520,
          longitude: -46.633308,
        );
      },
      writeLocation: (latitude, longitude) {
        writtenLatitude = latitude;
        writtenLongitude = longitude;
      },
    );

    expect(result.loading, isFalse);
    expect(result.latitude, -23.550520);
    expect(result.longitude, -46.633308);
    expect(result.errorMessage, isNull);
    expect(writtenLatitude, -23.550520);
    expect(writtenLongitude, -46.633308);
  });

  test('HomeLocationService returns error snapshot', () async {
    const service = HomeLocationService();

    final result = await service.refresh(
      current: HomeLocationSnapshot.initial(),
      readCurrentLocation: () async {
        throw Exception('Falha ao obter localização');
      },
      writeLocation: (_, __) {},
    );

    expect(result.loading, isFalse);
    expect(result.errorMessage, 'Falha ao obter localização');
  });
}
