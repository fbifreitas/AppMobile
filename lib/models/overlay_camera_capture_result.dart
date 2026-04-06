import 'inspection_session_model.dart';

class OverlayCameraCaptureResult {
  final String filePath;
  final String? macroLocal;
  final String ambiente;
  final String? ambienteBase;
  final int? ambienteInstanceIndex;
  final String? elemento;
  final String? material;
  final String? estado;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool classificationConfirmed;
  final bool learningPersisted;
  final bool usedSuggestion;
  final String? suggestionSummary;

  const OverlayCameraCaptureResult({
    required this.filePath,
    required this.ambiente,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.macroLocal,
    this.ambienteBase,
    this.ambienteInstanceIndex,
    this.elemento,
    this.material,
    this.estado,
    this.classificationConfirmed = false,
    this.learningPersisted = false,
    this.usedSuggestion = false,
    this.suggestionSummary,
  });

  OverlayCameraCaptureResult copyWith({
    String? filePath,
    String? macroLocal,
    String? ambiente,
    String? ambienteBase,
    int? ambienteInstanceIndex,
    String? elemento,
    String? material,
    String? estado,
    DateTime? capturedAt,
    double? latitude,
    double? longitude,
    double? accuracy,
    bool? classificationConfirmed,
    bool? learningPersisted,
    bool? usedSuggestion,
    String? suggestionSummary,
  }) {
    return OverlayCameraCaptureResult(
      filePath: filePath ?? this.filePath,
      macroLocal: macroLocal ?? this.macroLocal,
      ambiente: ambiente ?? this.ambiente,
      ambienteBase: ambienteBase ?? this.ambienteBase,
      ambienteInstanceIndex: ambienteInstanceIndex ?? this.ambienteInstanceIndex,
      elemento: elemento ?? this.elemento,
      material: material ?? this.material,
      estado: estado ?? this.estado,
      capturedAt: capturedAt ?? this.capturedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      classificationConfirmed:
          classificationConfirmed ?? this.classificationConfirmed,
      learningPersisted: learningPersisted ?? this.learningPersisted,
      usedSuggestion: usedSuggestion ?? this.usedSuggestion,
      suggestionSummary: suggestionSummary ?? this.suggestionSummary,
    );
  }

  bool get hasAnyClassification =>
      (elemento != null && elemento!.trim().isNotEmpty) ||
      (material != null && material!.trim().isNotEmpty) ||
      (estado != null && estado!.trim().isNotEmpty);

  GeoPointData toGeoPointData() => GeoPointData(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    capturedAt: capturedAt,
  );

  String get ambienteBaseLabel {
    final direct = ambienteBase?.trim();
    return direct == null || direct.isEmpty ? ambiente : direct;
  }

  Map<String, dynamic> toMap() {
    return {
      'filePath': filePath,
      'macroLocal': macroLocal,
      'ambiente': ambiente,
      'ambienteBase': ambienteBase,
      'ambienteInstanceIndex': ambienteInstanceIndex,
      'elemento': elemento,
      'material': material,
      'estado': estado,
      'capturedAt': capturedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'classificationConfirmed': classificationConfirmed,
      'learningPersisted': learningPersisted,
      'usedSuggestion': usedSuggestion,
      'suggestionSummary': suggestionSummary,
    };
  }

  factory OverlayCameraCaptureResult.fromMap(Map<String, dynamic> map) {
    final capturedAtString = map['capturedAt']?.toString();
    final capturedAt =
        DateTime.tryParse(capturedAtString ?? '') ?? DateTime.now();

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    return OverlayCameraCaptureResult(
      filePath: map['filePath']?.toString() ?? '',
      ambiente: map['ambiente']?.toString() ?? '',
      macroLocal: map['macroLocal']?.toString(),
      ambienteBase: map['ambienteBase']?.toString(),
      ambienteInstanceIndex:
          (map['ambienteInstanceIndex'] as num?)?.toInt() ??
          int.tryParse('${map['ambienteInstanceIndex'] ?? ''}'),
      elemento: map['elemento']?.toString(),
      material: map['material']?.toString(),
      estado: map['estado']?.toString(),
      capturedAt: capturedAt,
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      accuracy: parseDouble(map['accuracy']),
      classificationConfirmed: parseBool(map['classificationConfirmed']),
      learningPersisted: parseBool(map['learningPersisted']),
      usedSuggestion: parseBool(map['usedSuggestion']),
      suggestionSummary: map['suggestionSummary']?.toString(),
    );
  }
}
