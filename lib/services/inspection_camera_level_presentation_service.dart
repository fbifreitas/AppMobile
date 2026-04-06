import '../config/inspection_menu_package.dart';
import 'inspection_semantic_field_service.dart';

class InspectionCameraLevelPresentationService {
  const InspectionCameraLevelPresentationService({
    this.semanticFieldService = InspectionSemanticFieldService.instance,
  });

  static const InspectionCameraLevelPresentationService instance =
      InspectionCameraLevelPresentationService();

  static const List<String> _defaultCameraLevels = <String>[
    'macroLocal',
    'ambiente',
    'elemento',
    'material',
    'estado',
  ];

  final InspectionSemanticFieldService semanticFieldService;

  List<String> normalizeLevelOrder(List<String> rawLevels) {
    final normalized = <String>[];
    for (final raw in rawLevels) {
      final mapped = semanticFieldService.mapCameraLevelId(raw);
      if (mapped == null || normalized.contains(mapped)) {
        continue;
      }
      normalized.add(mapped);
    }

    if (normalized.isEmpty) {
      return List<String>.from(_defaultCameraLevels);
    }
    return normalized;
  }

  bool isLevelEnabled({
    required List<String> levelOrder,
    required String levelId,
  }) {
    return levelOrder.contains(levelId);
  }

  String labelForLevel({
    required String levelId,
    required Map<String, String> labelsByLevel,
  }) {
    final configured = labelsByLevel[levelId]?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }

    switch (levelId) {
      case 'macroLocal':
        return 'Área da foto';
      case 'ambiente':
        return 'Local da foto';
      case 'elemento':
        return 'Elemento fotografado';
      case 'material':
        return 'Material';
      case 'estado':
        return 'Estado';
    }
    return levelId;
  }

  Map<String, String> resolveLabelsByLevel({
    required List<ConfigLevelDefinition> levels,
    required String surface,
  }) {
    if (levels.isEmpty) {
      return const <String, String>{};
    }

    final labels = <String, String>{};
    for (final level in levels) {
      final cameraLevelId =
          semanticFieldService.mapCameraLevelId(level.id) ??
          semanticFieldService.cameraLevelIdForSemantic(level.semanticKey ?? '');
      if (cameraLevelId == null || cameraLevelId.trim().isEmpty) {
        continue;
      }
      labels[cameraLevelId] = semanticFieldService.labelForLevel(
        level: level,
        surface: surface,
      );
    }
    return labels;
  }
}
