import '../config/inspection_menu_package.dart';
import 'inspection_menu_ranking_service.dart';

class InspectionMenuCatalogService {
  const InspectionMenuCatalogService({
    this.rankingService = InspectionMenuRankingService.instance,
  });

  static const InspectionMenuCatalogService instance =
      InspectionMenuCatalogService();

  final InspectionMenuRankingService rankingService;

  List<String> macroLocals({
    required InspectionMenuPackage? package,
    required Map<String, dynamic> usage,
    required String propertyType,
  }) {
    final config = package?.configFor(propertyType);
    final options = config?.macroLocals ?? _fallbackMacroLocals(propertyType);
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
        selectedMacro?.ambientes ?? _fallbackAmbientes(propertyType, macroLocal);
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
      (item) => item.label == ambiente,
    );
    final options =
        selectedAmbiente?.elements ??
        _fallbackElementos(propertyType, macroLocal, ambiente);
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
    final options = selectedElement?.materials ?? _fallbackMateriais(elemento);
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
    final options = selectedElement?.states ?? _fallbackEstados();
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
      (item) => item.label == ambiente,
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

  List<MacroLocalOption> _fallbackMacroLocals(String propertyType) {
    switch (propertyType.trim().toLowerCase()) {
      case 'rural':
        return const <MacroLocalOption>[
          MacroLocalOption(label: 'Rua', baseScore: 100, pinnedTop: true),
          MacroLocalOption(label: 'Área externa', baseScore: 80),
        ];
      case 'comercial':
      case 'industrial':
      case 'urbano':
      default:
        return const <MacroLocalOption>[
          MacroLocalOption(label: 'Rua', baseScore: 100, pinnedTop: true),
          MacroLocalOption(label: 'Área externa', baseScore: 80),
          MacroLocalOption(label: 'Área interna', baseScore: 60),
        ];
    }
  }

  List<RankedMenuOption> _fallbackAmbientes(String propertyType, String macroLocal) {
    final key = propertyType.trim().toLowerCase();
    if (macroLocal == 'Rua') {
      switch (key) {
        case 'rural':
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Acesso principal', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Entrada da propriedade', baseScore: 95),
            RankedMenuOption(label: 'Identificação / referência', baseScore: 90),
          ];
        case 'comercial':
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Fachada', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Logradouro', baseScore: 95),
            RankedMenuOption(label: 'Acesso principal', baseScore: 92),
          ];
        case 'industrial':
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Acesso principal', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Fachada / portaria', baseScore: 95),
            RankedMenuOption(label: 'Número / identificação', baseScore: 90),
          ];
        case 'urbano':
        default:
          return const <RankedMenuOption>[
            RankedMenuOption(label: 'Fachada', baseScore: 100, pinnedTop: true),
            RankedMenuOption(label: 'Logradouro', baseScore: 95),
            RankedMenuOption(label: 'Acesso ao imóvel', baseScore: 92),
            RankedMenuOption(label: 'Entorno', baseScore: 88),
          ];
      }
    }

    if (macroLocal == 'Área externa') {
      return const <RankedMenuOption>[
        RankedMenuOption(label: 'Garagem', baseScore: 90),
        RankedMenuOption(label: 'Quintal', baseScore: 88),
        RankedMenuOption(label: 'Jardim', baseScore: 84),
      ];
    }

    return const <RankedMenuOption>[
      RankedMenuOption(label: 'Sala', baseScore: 90),
      RankedMenuOption(label: 'Quarto', baseScore: 88),
      RankedMenuOption(label: 'Cozinha', baseScore: 84),
    ];
  }

  List<RankedMenuOption> _fallbackElementos(
    String propertyType,
    String macroLocal,
    String ambiente,
  ) {
    switch (ambiente) {
      case 'Fachada':
      case 'Fachada / portaria':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Número', baseScore: 95),
          RankedMenuOption(label: 'Porta', baseScore: 82),
          RankedMenuOption(label: 'Portão', baseScore: 80),
          RankedMenuOption(label: 'Janela', baseScore: 74),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Logradouro':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Calçada', baseScore: 90),
          RankedMenuOption(label: 'Rua / via', baseScore: 88),
          RankedMenuOption(label: 'Pavimentação', baseScore: 82),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Acesso ao imóvel':
      case 'Acesso principal':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Portão', baseScore: 94),
          RankedMenuOption(label: 'Porta', baseScore: 90),
          RankedMenuOption(label: 'Interfone', baseScore: 84),
          RankedMenuOption(label: 'Número', baseScore: 80),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Entrada da propriedade':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Porteira', baseScore: 94),
          RankedMenuOption(label: 'Cerca', baseScore: 88),
          RankedMenuOption(label: 'Estrada interna', baseScore: 82),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Identificação / referência':
      case 'Número / identificação':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Número', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Placa', baseScore: 96),
          RankedMenuOption(label: 'Marco de referência', baseScore: 84),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      case 'Entorno':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Rua / via', baseScore: 90),
          RankedMenuOption(label: 'Vegetação', baseScore: 76),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
      default:
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Visão geral', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Outro elemento', baseScore: 1, pinnedBottom: true),
        ];
    }
  }

  List<RankedMenuOption> _fallbackMateriais(String elemento) {
    switch (elemento) {
      case 'Piso':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Cerâmico', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Porcelanato', baseScore: 95),
          RankedMenuOption(label: 'Madeira', baseScore: 88),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      case 'Parede':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Pintura', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Azulejo', baseScore: 92),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Teto':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Pintura', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Gesso', baseScore: 90),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      case 'Porta':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Madeira', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Metal', baseScore: 90),
          RankedMenuOption(label: 'Vidro', baseScore: 80),
        ];
      case 'Janela':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Vidro', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Alumínio', baseScore: 90),
          RankedMenuOption(label: 'Madeira', baseScore: 82),
        ];
      case 'Bancada':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Granito', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Mármore', baseScore: 92),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Louças e metais':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Cerâmica', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Metal', baseScore: 92),
        ];
      case 'Portão':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Madeira', baseScore: 82),
        ];
      case 'Número':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Pintura', baseScore: 88),
        ];
      case 'Calçada':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Concreto', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Cerâmico', baseScore: 82),
        ];
      case 'Rua / via':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Asfalto', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Acesso':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 84),
        ];
      case 'Interfone':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Plástico', baseScore: 82),
        ];
      case 'Cobertura':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Telha', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      case 'Guarda-corpo':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Metal', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Vidro', baseScore: 82),
        ];
      case 'Tanque':
        return const <RankedMenuOption>[
          RankedMenuOption(label: 'Cerâmica', baseScore: 100, pinnedTop: true),
          RankedMenuOption(label: 'Concreto', baseScore: 82),
        ];
      default:
        return const <RankedMenuOption>[];
    }
  }

  List<RankedMenuOption> _fallbackEstados() {
    return const <RankedMenuOption>[
      RankedMenuOption(label: 'Novo', baseScore: 100, pinnedTop: true),
      RankedMenuOption(label: 'Bom', baseScore: 90),
      RankedMenuOption(label: 'Regular', baseScore: 75),
      RankedMenuOption(label: 'Ruim', baseScore: 60),
      RankedMenuOption(label: 'Péssimo', baseScore: 45),
    ];
  }
}
