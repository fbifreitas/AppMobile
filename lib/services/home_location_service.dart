import '../models/home_location_snapshot.dart';

typedef HomeLocationReader = Future<HomeLocationPoint> Function();
typedef HomeLocationWriter = void Function(double latitude, double longitude);

class HomeLocationPoint {
  const HomeLocationPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class HomeLocationService {
  const HomeLocationService();

  Future<HomeLocationSnapshot> refresh({
    required HomeLocationSnapshot current,
    required HomeLocationReader readCurrentLocation,
    required HomeLocationWriter writeLocation,
  }) async {
    final loadingSnapshot = current.copyWith(
      loading: true,
      clearErrorMessage: true,
    );

    try {
      final point = await readCurrentLocation();

      writeLocation(point.latitude, point.longitude);

      return loadingSnapshot.copyWith(
        loading: false,
        latitude: point.latitude,
        longitude: point.longitude,
        lastSyncAt: DateTime.now(),
        clearErrorMessage: true,
      );
    } catch (e) {
      return loadingSnapshot.copyWith(
        loading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
