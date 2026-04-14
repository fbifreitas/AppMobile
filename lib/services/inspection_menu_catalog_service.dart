import '../config/inspection_menu_package.dart';
import 'inspection_semantic_field_service.dart';
import 'inspection_environment_instance_service.dart';
import 'inspection_menu_ranking_service.dart';
import 'inspection_taxonomy_service.dart';

class InspectionMenuCatalogService {
  const InspectionMenuCatalogService({
    this.rankingService = InspectionMenuRankingService.instance,
    this.environmentInstanceService =
        InspectionEnvironmentInstanceService.instance,
    this.taxonomyService = InspectionTaxonomyService.instance,
    this.semanticFieldService = InspectionSemanticFieldService.instance,
  });

  static const InspectionMenuCatalogService instance =
      InspectionMenuCatalogService();

  final InspectionMenuRankingService rankingService;
  final InspectionEnvironmentInstanceService environmentInstanceService;
  final InspectionTaxonomyService taxonomyService;
  final InspectionSemanticFieldService semanticFieldService;

  List<String> macroLocals({
    required InspectionMenuPackage? package,
    required Map<String, dynamic> usage,
    required String propertyType,
    String? subtipo,
  }) {
    final config = package?.configFor(propertyType);
    final flatOptions = _flatLevelOptions(config: config, levelId: 'macroLocal');
    final step1Contexts = package?.step1Config?.contextos ?? const <String>[];
    final scopedMacroLocals =
        package?.cameraMacroLocalsFor(
          propertyType: propertyType,
          subtipo: subtipo,
        ) ??
        const <MacroLocalOption>[];
    final options =
        scopedMacroLocals.isNotEmpty
            ? scopedMacroLocals
            : flatOptions != null
            ? flatOptions
                .map((option) => MacroLocalOption(label: option.label, baseScore: 100))
                .toList(growable: false)
            : step1Contexts.isNotEmpty
            ? step1Contexts
                .map(
                  (context) => MacroLocalOption(
                    label: context,
                    baseScore: 100,
                  ),
                )
                .toList(growable: false)
            : taxonomyService.fallbackMacroLocals(propertyType);
    return _rankOptions(
      options: options,
      usage: usage,
      rankingPolicy: package?.rankingPolicy,
      scope: 'camera.${propertyType.toLowerCase()}.macro',
    ).map((item) => item.label).toList();
  }

  List<String> ambientes({
    required InspectionMenuPackage? package,
    required Map<String, dynamic> usage,
    required String propertyType,
    String? subtipo,
    required String macroLocal,
  }) {
    final config = package?.configFor(propertyType);
    final flatOptions = _flatLevelOptions(config: config, levelId: 'ambiente');
    final scopedMacroLocals =
        package?.cameraMacroLocalsFor(
          propertyType: propertyType,
          subtipo: subtipo,
        ) ??
        const <MacroLocalOption>[];
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      scopedMacroLocals,
      (item) => item.label == macroLocal,
    );
    final options =
        selectedMacro != null
            ? selectedMacro.ambientes
            : flatOptions ??
                taxonomyService.fallbackAmbientes(propertyType, macroLocal);
    return _rankOptions(
      options: options,
      usage: usage,
      rankingPolicy: package?.rankingPolicy,
      scope: 'camera.${propertyType.toLowerCase()}.$macroLocal.ambiente',
    ).map((item) => item.label).toList();
  }

  List<String> elementos({
    required InspectionMenuPackage? package,
    required Map<String, dynamic> usage,
    required String propertyType,
    String? subtipo,
    required String macroLocal,
    required String ambiente,
  }) {
    final config = package?.configFor(propertyType);
    final flatOptions = _flatLevelOptions(config: config, levelId: 'elemento');
    final scopedMacroLocals =
        package?.cameraMacroLocalsFor(
          propertyType: propertyType,
          subtipo: subtipo,
        ) ??
        const <MacroLocalOption>[];
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      scopedMacroLocals,
      (item) => item.label == macroLocal,
    );
    final selectedAmbiente = _firstWhereOrNull<RankedMenuOption>(
      selectedMacro?.ambientes ?? const <RankedMenuOption>[],
      (item) => _matchesAmbiente(item.label, ambiente),
    );
    final normalizedAmbiente = environmentInstanceService.baseLabelOf(ambiente);
    final options =
        selectedAmbiente != null
            ? selectedAmbiente.elements
            : flatOptions ??
                taxonomyService.fallbackElementos(normalizedAmbiente);
    return _rankOptions(
      options: options,
      usage: usage,
      rankingPolicy: package?.rankingPolicy,
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.elemento',
    ).map((item) => item.label).toList();
  }

  List<String> materiais({
    required InspectionMenuPackage? package,
    required Map<String, dynamic> usage,
    required String propertyType,
    String? subtipo,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) {
    final selectedElement = _findSelectedElement(
      package: package,
      propertyType: propertyType,
      subtipo: subtipo,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
    final flatOptions = _flatLevelOptions(
      config: package?.configFor(propertyType),
      levelId: 'material',
    );
    final options =
        selectedElement != null
            ? selectedElement.materials
            : flatOptions ?? taxonomyService.fallbackMateriais(elemento);
    return _rankOptions(
      options: options,
      usage: usage,
      rankingPolicy: package?.rankingPolicy,
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.$elemento.material',
    ).map((item) => item.label).toList();
  }

  List<String> estados({
    required InspectionMenuPackage? package,
    required Map<String, dynamic> usage,
    required String propertyType,
    String? subtipo,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) {
    final selectedElement = _findSelectedElement(
      package: package,
      propertyType: propertyType,
      subtipo: subtipo,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
    final flatOptions = _flatLevelOptions(
      config: package?.configFor(propertyType),
      levelId: 'estado',
    );
    final options =
        selectedElement != null
            ? selectedElement.states
            : flatOptions ?? taxonomyService.fallbackEstados();
    return _rankOptions(
      options: options,
      usage: usage,
      rankingPolicy: package?.rankingPolicy,
      scope:
          'camera.${propertyType.toLowerCase()}.$macroLocal.$ambiente.$elemento.estado',
    ).map((item) => item.label).toList();
  }

  RankedMenuOption? _findSelectedElement({
    required InspectionMenuPackage? package,
    required String propertyType,
    String? subtipo,
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) {
    final scopedMacroLocals =
        package?.cameraMacroLocalsFor(
          propertyType: propertyType,
          subtipo: subtipo,
        ) ??
        const <MacroLocalOption>[];
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      scopedMacroLocals,
      (item) => item.label == macroLocal,
    );
    final selectedAmbiente = _firstWhereOrNull<RankedMenuOption>(
      selectedMacro?.ambientes ?? const <RankedMenuOption>[],
      (item) => _matchesAmbiente(item.label, ambiente),
    );
    return _firstWhereOrNull<RankedMenuOption>(
      selectedAmbiente?.elements ?? const <RankedMenuOption>[],
      (item) => item.label == elemento,
    );
  }

  T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T item) test) {
    for (final value in values) {
      if (test(value)) return value;
    }
    return null;
  }

  bool _matchesAmbiente(String configuredLabel, String selectedLabel) {
    final configuredBase = environmentInstanceService.baseLabelOf(
      configuredLabel,
    );
    final selectedBase = environmentInstanceService.baseLabelOf(selectedLabel);
    return _normalize(configuredBase) == _normalize(selectedBase);
  }

  List<T> _rankOptions<T extends RankedMenuOption>({
    required List<T> options,
    required Map<String, dynamic> usage,
    required RankingPolicyConfig? rankingPolicy,
    required String scope,
  }) {
    return rankingService.rankOptions(
      options: options,
      usage: usage,
      rankingPolicy: rankingPolicy,
      scope: scope,
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();

  List<RankedMenuOption>? _flatLevelOptions({
    required PropertyTypeCameraConfig? config,
    required String levelId,
  }) {
    if (config == null || config.macroLocals.isNotEmpty) {
      return null;
    }

    for (final level in config.levels) {
      final canonicalId =
          semanticFieldService.mapCameraLevelId(level.id) ?? level.id.trim();
      if (_normalize(canonicalId) != _normalize(levelId) ||
          level.options.isEmpty) {
        continue;
      }

      return level.options
          .map((option) => RankedMenuOption(label: option, baseScore: 100))
          .toList(growable: false);
    }

    return null;
  }
}
