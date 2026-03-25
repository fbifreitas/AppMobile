import 'dart:io';

import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inspection_session_model.dart';

class InspectionCaptureException implements Exception {
  final String message;

  const InspectionCaptureException(this.message);

  @override
  String toString() => message;
}

class InspectionCaptureService {
  InspectionCaptureService({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<void> ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const InspectionCaptureException(
        'Ative o GPS do aparelho para continuar.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const InspectionCaptureException(
        'Permissão de localização negada.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const InspectionCaptureException(
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

  double distanceMeters({
    required GeoPointData origin,
    required GeoPointData target,
  }) {
    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      target.latitude,
      target.longitude,
    );
  }

  Future<PhotoEvidence> captureCameraEvidence({
    required InspectionSession session,
    required String ambienteId,
    required String ambienteNome,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
  }) async {
    final currentGeo = await getCurrentGeoPoint();
    _validateRadius(session: session, geoPoint: currentGeo);

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (file == null) {
      throw const InspectionCaptureException('Captura cancelada pelo usuário.');
    }

    return PhotoEvidence(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ambienteId: ambienteId,
      ambienteNome: ambienteNome,
      elementoId: elementoId,
      elementoNome: elementoNome,
      material: material,
      estadoConservacao: estadoConservacao,
      observacao: null,
      filePath: file.path,
      source: EvidenceSource.camera,
      geoPoint: currentGeo,
      isValidForAudit: true,
      importedFromGallery: false,
    );
  }

  Future<PhotoEvidence> pickGalleryEvidence({
    required InspectionSession session,
    required String ambienteId,
    required String ambienteNome,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
  }) async {
    // Mesmo para galeria, o GPS do aparelho precisa estar ativo.
    await ensureLocationReady();
    await getCurrentGeoPoint();

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (file == null) {
      throw const InspectionCaptureException('Seleção cancelada pelo usuário.');
    }

    final exifGeo = await _extractGeoFromExif(file.path);
    if (exifGeo == null) {
      throw const InspectionCaptureException(
        'A imagem selecionada não possui geolocalização válida no EXIF.',
      );
    }

    _validateRadius(session: session, geoPoint: exifGeo);

    return PhotoEvidence(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ambienteId: ambienteId,
      ambienteNome: ambienteNome,
      elementoId: elementoId,
      elementoNome: elementoNome,
      material: material,
      estadoConservacao: estadoConservacao,
      observacao: null,
      filePath: file.path,
      source: EvidenceSource.gallery,
      geoPoint: exifGeo,
      isValidForAudit: true,
      importedFromGallery: true,
    );
  }

  void _validateRadius({
    required InspectionSession session,
    required GeoPointData geoPoint,
  }) {
    final allowedMeters = session.template.auditRules.raioPermitidoMetros;
    final distance = distanceMeters(
      origin: session.checkinGeoPoint,
      target: geoPoint,
    );

    if (distance > allowedMeters) {
      throw InspectionCaptureException(
        'A evidência está fora do raio permitido da vistoria (${distance.toStringAsFixed(0)}m de distância; limite ${allowedMeters.toStringAsFixed(0)}m).',
      );
    }
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
          RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
          (match) => '${match.group(1)}-${match.group(2)}-${match.group(3)}',
        );

    return DateTime.tryParse(normalized);
  }
}