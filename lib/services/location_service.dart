import 'package:geolocator/geolocator.dart';
import 'dart:math';

class LocationService {

  /// 📍 PEGAR LOCALIZAÇÃO ATUAL
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    /// 🔍 GPS ligado?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS desativado');
    }

    /// 🔐 PERMISSÃO
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão negada');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão negada permanentemente');
    }

    /// 📡 POSIÇÃO
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  /// 📏 CALCULAR DISTÂNCIA (metros)
  double calcularDistancia({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const R = 6371000; // raio da Terra em metros

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _toRad(double degree) {
    return degree * pi / 180;
  }
}