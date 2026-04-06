import '../config/inspection_menu_package.dart';

class InspectionSemanticFieldKeys {
  static const String clientPresence = 'client_presence';
  static const String propertyType = 'property_type';
  static const String propertySubtype = 'property_subtype';
  static const String captureContext = 'capture_context';
  static const String photoLocation = 'photo_location';
  static const String photoElement = 'photo_element';
  static const String photoMaterial = 'photo_material';
  static const String photoState = 'photo_state';
}

class InspectionSurfaceKeys {
  static const String checkinStep1 = 'checkin_step1';
  static const String camera = 'camera';
  static const String review = 'review';
}

class InspectionSemanticFieldService {
  const InspectionSemanticFieldService();

  static const InspectionSemanticFieldService instance =
      InspectionSemanticFieldService();

  static const Map<String, List<String>> _fallbackAliases =
      <String, List<String>>{
        InspectionSemanticFieldKeys.captureContext: <String>[
          'contexto',
          'porOndeComecar',
          'por_onde_comecar',
          'area_foto',
          'areaFoto',
          'macroLocal',
          'macro_local',
        ],
        InspectionSemanticFieldKeys.photoLocation: <String>[
          'ambiente',
          'local_foto',
          'localFoto',
          'local',
          'cameraAmbiente',
        ],
        InspectionSemanticFieldKeys.photoElement: <String>[
          'elemento',
          'cameraElementoInicial',
          'item',
        ],
        InspectionSemanticFieldKeys.photoMaterial: <String>[
          'material',
          'materiais',
        ],
        InspectionSemanticFieldKeys.photoState: <String>[
          'estado',
          'condicao',
        ],
      };

  static const Map<String, String> _cameraLevelIds = <String, String>{
    InspectionSemanticFieldKeys.captureContext: 'macroLocal',
    InspectionSemanticFieldKeys.photoLocation: 'ambiente',
    InspectionSemanticFieldKeys.photoElement: 'elemento',
    InspectionSemanticFieldKeys.photoMaterial: 'material',
    InspectionSemanticFieldKeys.photoState: 'estado',
  };

  String labelForLevel({
    required ConfigLevelDefinition level,
    required String surface,
  }) {
    final configured = level.labelsBySurface[surface]?.trim();
    return configured == null || configured.isEmpty ? level.label : configured;
  }

  String? resolveSelectedValueForSemantic({
    required Map<String, String> selectedLevels,
    required Iterable<ConfigLevelDefinition> levels,
    required String semanticKey,
  }) {
    final configuredLevel = levels.cast<ConfigLevelDefinition?>().firstWhere(
      (level) => level != null && matchesSemantic(level: level, semanticKey: semanticKey),
      orElse: () => null,
    );

    if (configuredLevel != null) {
      final direct = selectedLevels[configuredLevel.id];
      if (direct != null && direct.trim().isNotEmpty) {
        return direct.trim();
      }
    }

    final aliases = <String>{
      ...?_fallbackAliases[semanticKey]?.map(_normalize),
      _normalize(cameraLevelIdForSemantic(semanticKey)),
      _normalize(semanticKey),
    };

    for (final entry in selectedLevels.entries) {
      if (aliases.contains(_normalize(entry.key)) &&
          entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    return null;
  }

  bool matchesSemantic({
    required ConfigLevelDefinition level,
    required String semanticKey,
  }) {
    final normalizedSemantic = _normalize(semanticKey);
    if (normalizedSemantic.isEmpty) return false;

    if (_normalize(level.semanticKey) == normalizedSemantic) {
      return true;
    }

    final aliases = <String>{
      _normalize(level.id),
      ...level.aliases.map(_normalize),
      ...?_fallbackAliases[semanticKey]?.map(_normalize),
      _normalize(cameraLevelIdForSemantic(semanticKey)),
    };
    return aliases.contains(normalizedSemantic);
  }

  String? mapCameraLevelId(String raw) {
    final normalizedRaw = _normalize(raw);
    if (normalizedRaw.isEmpty) {
      return null;
    }

    for (final entry in _cameraLevelIds.entries) {
      final aliases = _fallbackAliases[entry.key] ?? const <String>[];
      if (_normalize(entry.value) == normalizedRaw ||
          _normalize(entry.key) == normalizedRaw ||
          aliases.map(_normalize).contains(normalizedRaw)) {
        return entry.value;
      }
    }

    return null;
  }

  String? cameraLevelIdForSemantic(String semanticKey) {
    return _cameraLevelIds[semanticKey];
  }

  String _normalize(String? value) {
    return (value ?? '').trim().toLowerCase();
  }
}
