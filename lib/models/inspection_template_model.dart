class InspectionTemplate {
  final String id;
  final String version;
  final String tipoImovel;
  final String subtipoImovel;
  final AuditRules auditRules;
  final List<EnvironmentTemplate> ambientes;

  const InspectionTemplate({
    required this.id,
    required this.version,
    required this.tipoImovel,
    required this.subtipoImovel,
    required this.auditRules,
    required this.ambientes,
  });

  factory InspectionTemplate.fromMap(Map<String, dynamic> map) {
    return InspectionTemplate(
      id: map['id'] as String,
      version: map['version'] as String,
      tipoImovel: map['tipoImovel'] as String,
      subtipoImovel: map['subtipoImovel'] as String,
      auditRules: AuditRules.fromMap(
        Map<String, dynamic>.from(map['auditRules'] as Map),
      ),
      ambientes: (map['ambientes'] as List<dynamic>)
          .map(
            (item) => EnvironmentTemplate.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'version': version,
      'tipoImovel': tipoImovel,
      'subtipoImovel': subtipoImovel,
      'auditRules': auditRules.toMap(),
      'ambientes': ambientes.map((e) => e.toMap()).toList(),
    };
  }

  EnvironmentTemplate? getEnvironmentById(String id) {
    try {
      return ambientes.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}

class AuditRules {
  final bool gpsObrigatorio;
  final bool galleryAllowed;
  final double raioPermitidoMetros;

  const AuditRules({
    required this.gpsObrigatorio,
    required this.galleryAllowed,
    required this.raioPermitidoMetros,
  });

  factory AuditRules.fromMap(Map<String, dynamic> map) {
    return AuditRules(
      gpsObrigatorio: map['gpsObrigatorio'] as bool? ?? true,
      galleryAllowed: map['galleryAllowed'] as bool? ?? true,
      raioPermitidoMetros: (map['raioPermitidoMetros'] as num?)?.toDouble() ?? 80,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gpsObrigatorio': gpsObrigatorio,
      'galleryAllowed': galleryAllowed,
      'raioPermitidoMetros': raioPermitidoMetros,
    };
  }
}

class EnvironmentTemplate {
  final String id;
  final String nome;
  final bool obrigatorio;
  final int minFotos;
  final bool permiteAmbienteNaoConfigurado;
  final List<ElementTemplate> elementos;

  const EnvironmentTemplate({
    required this.id,
    required this.nome,
    required this.obrigatorio,
    required this.minFotos,
    required this.permiteAmbienteNaoConfigurado,
    required this.elementos,
  });

  factory EnvironmentTemplate.fromMap(Map<String, dynamic> map) {
    return EnvironmentTemplate(
      id: map['id'] as String,
      nome: map['nome'] as String,
      obrigatorio: map['obrigatorio'] as bool? ?? true,
      minFotos: map['minFotos'] as int? ?? 1,
      permiteAmbienteNaoConfigurado:
          map['permiteAmbienteNaoConfigurado'] as bool? ?? true,
      elementos: (map['elementos'] as List<dynamic>? ?? [])
          .map(
            (item) => ElementTemplate.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'obrigatorio': obrigatorio,
      'minFotos': minFotos,
      'permiteAmbienteNaoConfigurado': permiteAmbienteNaoConfigurado,
      'elementos': elementos.map((e) => e.toMap()).toList(),
    };
  }
}

class ElementTemplate {
  final String id;
  final String nome;
  final bool obrigatorioParaConclusao;
  final List<String> materiais;
  final List<String> estadosConservacao;

  const ElementTemplate({
    required this.id,
    required this.nome,
    required this.obrigatorioParaConclusao,
    required this.materiais,
    required this.estadosConservacao,
  });

  factory ElementTemplate.fromMap(Map<String, dynamic> map) {
    return ElementTemplate(
      id: map['id'] as String,
      nome: map['nome'] as String,
      obrigatorioParaConclusao:
          map['obrigatorioParaConclusao'] as bool? ?? false,
      materiais: List<String>.from(map['materiais'] ?? const []),
      estadosConservacao:
          List<String>.from(map['estadosConservacao'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'obrigatorioParaConclusao': obrigatorioParaConclusao,
      'materiais': materiais,
      'estadosConservacao': estadosConservacao,
    };
  }
}

class InspectionTemplateFactory {
  static InspectionTemplate urbanoApartamento() {
    return const InspectionTemplate(
      id: 'urbano_apartamento_v1',
      version: '1.0.0',
      tipoImovel: 'Urbano',
      subtipoImovel: 'Apartamento',
      auditRules: AuditRules(
        gpsObrigatorio: true,
        galleryAllowed: true,
        raioPermitidoMetros: 80,
      ),
      ambientes: [
        EnvironmentTemplate(
          id: 'sala',
          nome: 'Sala',
          obrigatorio: true,
          minFotos: 3,
          permiteAmbienteNaoConfigurado: true,
          elementos: [
            ElementTemplate(
              id: 'piso',
              nome: 'Piso',
              obrigatorioParaConclusao: true,
              materiais: ['Cerâmico', 'Porcelanato', 'Madeira', 'Laminado'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Textura', 'Papel de parede'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
          ],
        ),
        EnvironmentTemplate(
          id: 'quarto',
          nome: 'Quarto',
          obrigatorio: true,
          minFotos: 3,
          permiteAmbienteNaoConfigurado: true,
          elementos: [
            ElementTemplate(
              id: 'piso',
              nome: 'Piso',
              obrigatorioParaConclusao: true,
              materiais: ['Cerâmico', 'Porcelanato', 'Madeira', 'Laminado'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Textura', 'Papel de parede'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
          ],
        ),
        EnvironmentTemplate(
          id: 'cozinha',
          nome: 'Cozinha',
          obrigatorio: true,
          minFotos: 4,
          permiteAmbienteNaoConfigurado: true,
          elementos: [
            ElementTemplate(
              id: 'piso',
              nome: 'Piso',
              obrigatorioParaConclusao: true,
              materiais: ['Cerâmico', 'Porcelanato', 'Granito'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Azulejo', 'Cerâmica', 'Pintura'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'bancada',
              nome: 'Bancada',
              obrigatorioParaConclusao: false,
              materiais: ['Granito', 'Mármore', 'Sintético'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
          ],
        ),
        EnvironmentTemplate(
          id: 'banheiro',
          nome: 'Banheiro',
          obrigatorio: true,
          minFotos: 4,
          permiteAmbienteNaoConfigurado: true,
          elementos: [
            ElementTemplate(
              id: 'piso',
              nome: 'Piso',
              obrigatorioParaConclusao: true,
              materiais: ['Cerâmico', 'Porcelanato', 'Pedra'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Azulejo', 'Cerâmica', 'Pintura'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'loucas_metais',
              nome: 'Louças e Metais',
              obrigatorioParaConclusao: false,
              materiais: ['Louça', 'Metal cromado', 'Inox'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
          ],
        ),
        EnvironmentTemplate(
          id: 'area_servico',
          nome: 'Área de Serviço',
          obrigatorio: false,
          minFotos: 2,
          permiteAmbienteNaoConfigurado: true,
          elementos: [
            ElementTemplate(
              id: 'piso',
              nome: 'Piso',
              obrigatorioParaConclusao: false,
              materiais: ['Cerâmico', 'Porcelanato', 'Cimento'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: false,
              materiais: ['Azulejo', 'Pintura'],
              estadosConservacao: [
                'Novo',
                'Excelente',
                'Bom',
                'Regular',
                'Ruim',
                'Péssimo'
              ],
            ),
          ],
        ),
      ],
    );
  }
}