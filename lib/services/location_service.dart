import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS desativado');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  double calcularDistancia({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const raioTerra = 6371000.0;

    final dLat = _grausParaRad(lat2 - lat1);
    final dLon = _grausParaRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_grausParaRad(lat1)) *
            cos(_grausParaRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return raioTerra * c;
  }

  double _grausParaRad(double graus) {
    return graus * pi / 180;
  }
}