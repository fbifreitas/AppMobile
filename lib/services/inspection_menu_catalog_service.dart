import '../config/inspection_menu_package.dart';
import 'inspection_environment_instance_service.dart';
import 'inspection_menu_ranking_service.dart';
import 'inspection_taxonomy_service.dart';

class InspectionMenuCatalogService {
  const InspectionMenuCatalogService({
    this.rankingService = InspectionMenuRankingService.instance,
    this.environmentInstanceService =
        InspectionEnvironmentInstanceService.instance,
    this.taxonomyService = InspectionTaxonomyService.instance,
  });

  static const InspectionMenuCatalogService instance =
      InspectionMenuCatalogService();

  final InspectionMenuRankingService rankingService;
  final InspectionEnvironmentInstanceService environmentInstanceService;
  final InspectionTaxonomyService taxonomyService;

  List<String> macroLocals({
    required InspectionMenuPackage? package,
    required Map<String, dynamic> usage,
    required String propertyType,
  }) {
    final config = package?.configFor(propertyType);
    final options =
        config?.macroLocals ?? taxonomyService.fallbackMacroLocals(propertyType);
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
    required String macroLocal,
  }) {
    final config = package?.configFor(propertyType);
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      config?.macroLocals ?? const <MacroLocalOption>[],
      (item) => item.label == macroLocal,
    );
    final options =
        selectedMacro?.ambientes ??
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
    required String macroLocal,
    required String ambiente,
  }) {
    final config = package?.configFor(propertyType);
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      config?.macroLocals ?? const <MacroLocalOption>[],
      (item) => item.label == macroLocal,
    );
    final selectedAmbiente = _firstWhereOrNull<RankedMenuOption>(
      selectedMacro?.ambientes ?? const <RankedMenuOption>[],
      (item) => _matchesAmbiente(item.label, ambiente),
    );
    final normalizedAmbiente = environmentInstanceService.baseLabelOf(ambiente);
    final options =
        selectedAmbiente?.elements ??
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
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) {
    final selectedElement = _findSelectedElement(
      package: package,
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
    final options =
        selectedElement?.materials ?? taxonomyService.fallbackMateriais(elemento);
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
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) {
    final selectedElement = _findSelectedElement(
      package: package,
      propertyType: propertyType,
      macroLocal: macroLocal,
      ambiente: ambiente,
      elemento: elemento,
    );
    final options =
        selectedElement?.states ?? taxonomyService.fallbackEstados();
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
    required String macroLocal,
    required String ambiente,
    required String elemento,
  }) {
    final config = package?.configFor(propertyType);
    final selectedMacro = _firstWhereOrNull<MacroLocalOption>(
      config?.macroLocals ?? const <MacroLocalOption>[],
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
}
