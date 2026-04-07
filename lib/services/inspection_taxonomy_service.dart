class InspectionTaxonomyService {
  const InspectionTaxonomyService();

  static const InspectionTaxonomyService instance = InspectionTaxonomyService();

  static const List<String> _elementOptions = <String>[
    'VisÃ£o geral',
    'NÃºmero',
    'Porta',
    'PortÃ£o',
    'Janela',
    'Piso',
    'Parede',
    'Teto',
    'Outro',
  ];

  static const List<String> _materialOptions = <String>[
    'Alvenaria',
    'Metal',
    'Madeira',
    'Vidro',
    'CerÃ¢mica',
    'Concreto',
    'Outro',
  ];

  static const List<String> _stateOptions = <String>[
    'Bom',
    'Regular',
    'Ruim',
    'Necessita reparo',
    'NÃ£o se aplica',
  ];

  static const List<String> _environmentOptions = <String>[
    'Fachada',
    'Logradouro',
    'Acesso ao imÃ³vel',
    'Entorno',
    'Sala de Estar',
    'Sala',
    'DormitÃ³rio',
    'Cozinha',
    'Banheiro',
    'Ãrea de serviÃ§o',
    'Ãreas Comuns',
    'Garagem',
    'Outro ambiente',
  ];

  List<String> environmentOptions() => _environmentOptions;
  List<String> targetItemOptions() => environmentOptions();

  List<String> elementOptions() => _elementOptions;
  List<String> targetQualifierOptions() => elementOptions();

  List<String> materialOptions() => _materialOptions;
  List<String> targetQualifierMaterialOptions() => materialOptions();

  List<String> stateOptions() => _stateOptions;
  List<String> targetConditionOptions() => stateOptions();
}
