import '../config/inspection_menu_package.dart';

class InspectionCheckinStep1StateService {
  const InspectionCheckinStep1StateService();

  static const InspectionCheckinStep1StateService instance =
      InspectionCheckinStep1StateService();

  List<ConfigLevelDefinition> resolveActiveLevels({
    required List<ConfigLevelDefinition> defaultLevels,
    required Map<String, List<ConfigLevelDefinition>> levelsByTipoSubtipo,
    required List<String> fallbackContextos,
    required String contextLevelId,
    required String? tipoImovel,
    required String? subtipoImovel,
  }) {
    if (defaultLevels.isEmpty) {
      return <ConfigLevelDefinition>[
        ConfigLevelDefinition(
          id: contextLevelId,
          label: 'Por onde deseja começar?',
          required: true,
          dependsOn: null,
          options: fallbackContextos,
        ),
      ];
    }

    if (tipoImovel == null || subtipoImovel == null) {
      return defaultLevels;
    }

    final typedKey =
        '${tipoImovel.trim().toLowerCase()}::${subtipoImovel.trim().toLowerCase()}';
    final bySubtype = levelsByTipoSubtipo[typedKey];
    if (bySubtype != null && bySubtype.isNotEmpty) {
      return bySubtype;
    }
    return defaultLevels;
  }

  List<String> optionsForLevel({
    required ConfigLevelDefinition level,
    required String contextLevelId,
    required List<String> fallbackContextos,
  }) {
    if (level.id == contextLevelId) {
      return level.options.isNotEmpty ? level.options : fallbackContextos;
    }
    return level.options;
  }

  Map<String, String> sanitizeSelectedLevels({
    required List<ConfigLevelDefinition> activeLevels,
    required Map<String, String> selectedLevels,
    required String contextLevelId,
    required List<String> fallbackContextos,
  }) {
    final activeIds = activeLevels.map((level) => level.id).toSet();
    final next = <String, String>{};

    for (final entry in selectedLevels.entries) {
      if (!activeIds.contains(entry.key)) {
        continue;
      }

      final level = activeLevels.firstWhere((item) => item.id == entry.key);
      final options = optionsForLevel(
        level: level,
        contextLevelId: contextLevelId,
        fallbackContextos: fallbackContextos,
      );
      if (options.isNotEmpty && !options.contains(entry.value)) {
        continue;
      }

      if (level.dependsOn != null && level.dependsOn!.trim().isNotEmpty) {
        final parentValue = next[level.dependsOn!.trim()];
        if (parentValue == null || parentValue.isEmpty) {
          continue;
        }
      }

      next[entry.key] = entry.value;
    }

    return next;
  }

  bool hasRequiredLevelsSelected({
    required List<ConfigLevelDefinition> activeLevels,
    required Map<String, String> selectedLevels,
  }) {
    for (final level in activeLevels.where((item) => item.required)) {
      final selected = selectedLevels[level.id];
      if (selected == null || selected.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  int totalQuestions({
    required bool? clientePresente,
    required List<ConfigLevelDefinition> activeLevels,
  }) {
    if (clientePresente != true) {
      return 1;
    }
    return 3 + activeLevels.length;
  }

  int answeredQuestions({
    required bool? clientePresente,
    required String? tipoImovel,
    required String? subtipoImovel,
    required List<ConfigLevelDefinition> activeLevels,
    required Map<String, String> selectedLevels,
  }) {
    var answered = clientePresente == null ? 0 : 1;
    if (clientePresente == true && tipoImovel != null) {
      answered += 1;
    }
    if (clientePresente == true && subtipoImovel != null) {
      answered += 1;
    }
    if (clientePresente == true) {
      for (final level in activeLevels) {
        final selected = selectedLevels[level.id];
        if (selected != null && selected.trim().isNotEmpty) {
          answered += 1;
        }
      }
    }
    return answered;
  }

  String? resolveNextPendingQuestionId({
    required bool? clientePresente,
    required String questionClienteId,
    required String questionTipoId,
    required String questionSubtipoId,
    required String Function(String levelId) levelQuestionId,
    required String? tipoImovel,
    required String? subtipoImovel,
    required List<ConfigLevelDefinition> activeLevels,
    required Map<String, String> selectedLevels,
  }) {
    if (clientePresente == null) {
      return questionClienteId;
    }
    if (clientePresente != true) {
      return null;
    }
    if (tipoImovel == null) {
      return questionTipoId;
    }
    if (subtipoImovel == null) {
      return questionSubtipoId;
    }

    for (final level in activeLevels) {
      final selected = selectedLevels[level.id];
      if (selected == null || selected.trim().isEmpty) {
        return levelQuestionId(level.id);
      }
    }
    return null;
  }

  String? resolveExpandedQuestionId({
    required String? currentExpandedQuestionId,
    required List<String> visibleQuestionIds,
    required String? nextPendingQuestionId,
  }) {
    if (currentExpandedQuestionId != null &&
        visibleQuestionIds.contains(currentExpandedQuestionId)) {
      return currentExpandedQuestionId;
    }

    if (currentExpandedQuestionId == null) {
      return null;
    }

    if (nextPendingQuestionId != null &&
        visibleQuestionIds.contains(nextPendingQuestionId)) {
      return nextPendingQuestionId;
    }
    return null;
  }
}
