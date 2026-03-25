import 'dart:io';

import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inspection_session_model.dart';

class CheckinPhotoCaptureException implements Exception {
  final String message;

  const CheckinPhotoCaptureException(this.message);

  @override
  String toString() => message;
}

class CheckinPhotoCaptureService {
  CheckinPhotoCaptureService({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<void> ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const CheckinPhotoCaptureException(
        'Ative o GPS do aparelho para registrar a evidência.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const CheckinPhotoCaptureException(
        'Permissão de localização negada.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const CheckinPhotoCaptureException(
        'Permissão de localização negada permanentemente. Libere nas configurações do aparelho.',
      );
    }
  }

  Future<GeoPointData> getCurrentGeoPoint() async {
    await ensureLocationReady();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return GeoPointData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      capturedAt: DateTime.now(),
    );
  }

  Future<({String path, GeoPointData geoPoint})> captureFromCamera() async {
    final geoPoint = await getCurrentGeoPoint();

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (file == null) {
      throw const CheckinPhotoCaptureException(
        'Captura cancelada pelo usuário.',
      );
    }

    return (path: file.path, geoPoint: geoPoint);
  }

  Future<({String path, GeoPointData geoPoint})> captureFromGallery() async {
    await ensureLocationReady();

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (file == null) {
      throw const CheckinPhotoCaptureException(
        'Seleção cancelada pelo usuário.',
      );
    }

    final geoPoint = await _extractGeoFromExif(file.path);
    if (geoPoint == null) {
      throw const CheckinPhotoCaptureException(
        'A imagem selecionada não possui geolocalização válida no EXIF.',
      );
    }

    return (path: file.path, geoPoint: geoPoint);
  }

  Future<GeoPointData?> _extractGeoFromExif(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);

    final lat = _parseCoordinate(
      data: data,
      valueKey: 'GPS GPSLatitude',
      refKey: 'GPS GPSLatitudeRef',
    );
    final lon = _parseCoordinate(
      data: data,
      valueKey: 'GPS GPSLongitude',
      refKey: 'GPS GPSLongitudeRef',
    );

    if (lat == null || lon == null) return null;

    final timestamp = _parseExifDate(
          data['EXIF DateTimeOriginal']?.printable,
        ) ??
        _parseExifDate(data['Image DateTime']?.printable) ??
        DateTime.now();

    return GeoPointData(
      latitude: lat,
      longitude: lon,
      accuracy: 0,
      capturedAt: timestamp,
    );
  }

  double? _parseCoordinate({
    required Map<String, IfdTag> data,
    required String valueKey,
    required String refKey,
  }) {
    final tag = data[valueKey];
    final ref = data[refKey]?.printable.trim().toUpperCase();

    if (tag == null || ref == null || ref.isEmpty) {
      return null;
    }

    final values = tag.values.toList();
    if (values.length < 3) {
      return null;
    }

    final degrees = _parseExifNumber(values[0]);
    final minutes = _parseExifNumber(values[1]);
    final seconds = _parseExifNumber(values[2]);

    if (degrees == null || minutes == null || seconds == null) {
      return null;
    }

    var result = degrees + (minutes / 60) + (seconds / 3600);

    if (ref == 'S' || ref == 'W') {
      result = -result;
    }

    return result;
  }

  double? _parseExifNumber(dynamic value) {
    final raw = value.toString().trim();

    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length != 2) return null;

      final numerator = double.tryParse(parts[0].trim());
      final denominator = double.tryParse(parts[1].trim());

      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }

      return numerator / denominator;
    }

    return double.tryParse(raw);
  }

  DateTime? _parseExifDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = value.trim().replaceFirstMapped(
          RegExp(r'^(\\d{4}):(\\d{2}):(\\d{2})'),
          (match) => '${match.group(1)}-${match.group(2)}-${match.group(3)}',
        );

    return DateTime.tryParse(normalized);
  }
}