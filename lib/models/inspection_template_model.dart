import 'package:flutter/material.dart';

enum TipoImovel {
  urbano,
  rural,
  comercial,
  industrial,
}

extension TipoImovelExtension on TipoImovel {
  String get label {
    switch (this) {
      case TipoImovel.urbano:
        return 'Urbano';
      case TipoImovel.rural:
        return 'Rural';
      case TipoImovel.comercial:
        return 'Comercial';
      case TipoImovel.industrial:
        return 'Industrial';
    }
  }

  static TipoImovel fromString(String value) {
    final normalizado = value.trim().toLowerCase();

    if (normalizado == 'urbano') return TipoImovel.urbano;
    if (normalizado == 'rural') return TipoImovel.rural;
    if (normalizado == 'comercial') return TipoImovel.comercial;
    if (normalizado == 'industrial') return TipoImovel.industrial;

    return TipoImovel.urbano;
  }
}

class CheckinStep2PhotoFieldConfig {
  final String id;
  final String titulo;
  final IconData icon;
  final bool obrigatorio;

  const CheckinStep2PhotoFieldConfig({
    required this.id,
    required this.titulo,
    required this.icon,
    this.obrigatorio = false,
  });
}

class CheckinStep2OptionItemConfig {
  final String id;
  final String label;

  const CheckinStep2OptionItemConfig({
    required this.id,
    required this.label,
  });
}

class CheckinStep2OptionGroupConfig {
  final String id;
  final String titulo;
  final bool multiplaEscolha;
  final bool permiteObservacao;
  final List<CheckinStep2OptionItemConfig> opcoes;

  const CheckinStep2OptionGroupConfig({
    required this.id,
    required this.titulo,
    required this.opcoes,
    this.multiplaEscolha = true,
    this.permiteObservacao = false,
  });
}

class CheckinStep2Config {
  final TipoImovel tipoImovel;
  final String tituloTela;
  final String subtituloTela;
  final List<CheckinStep2PhotoFieldConfig> camposFotos;
  final List<CheckinStep2OptionGroupConfig> gruposOpcoes;

  const CheckinStep2Config({
    required this.tipoImovel,
    required this.tituloTela,
    required this.subtituloTela,
    required this.camposFotos,
    required this.gruposOpcoes,
  });
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
      obrigatorioParaConclusao: map['obrigatorioParaConclusao'] as bool? ?? false,
      materiais: List<String>.from(map['materiais'] ?? const []),
      estadosConservacao: List<String>.from(map['estadosConservacao'] ?? const []),
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

  String get targetQualifierId => id;
  String get targetQualifierLabel => nome;
  List<String> get targetQualifierMaterialOptions => materiais;
  List<String> get targetConditionOptions => estadosConservacao;
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

  String get targetItemId => id;
  String get targetItemLabel => nome;
  List<ElementTemplate> get targetQualifiers => elementos;
}

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

  List<EnvironmentTemplate> get targetItems => ambientes;
}

class InspectionTemplateFactory {
  static CheckinStep2Config byTipo(TipoImovel tipo) {
    switch (tipo) {
      case TipoImovel.urbano:
        return _urbano();
      case TipoImovel.rural:
        return _rural();
      case TipoImovel.comercial:
        return _comercial();
      case TipoImovel.industrial:
        return _industrial();
    
    }
    
  }

  

  static InspectionTemplate byKey({
    required String tipoImovel,
    required String subtipoImovel,
  }) {
    final tipo = tipoImovel.trim().toLowerCase();
    final subtipo = subtipoImovel.trim().toLowerCase();

    if (tipo == 'urbano' && subtipo == 'apartamento') {
      return urbanoApartamento();
    }

    return urbanoApartamento();
  }

  static CheckinStep2Config _urbano() {
    return const CheckinStep2Config(
      tipoImovel: TipoImovel.urbano,
      tituloTela: 'Check-in Vistoria',
      subtituloTela: 'Pré Vistoria Externa',
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'fachada',
          titulo: 'Fachada',
          icon: Icons.home_work_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'logradouro',
          titulo: 'Logradouro',
          icon: Icons.map_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'numero_imovel',
          titulo: 'Número do Imóvel',
          icon: Icons.pin_outlined,
          obrigatorio: true,
        ),
      ],
      gruposOpcoes: [
        CheckinStep2OptionGroupConfig(
          id: 'pavimentacao',
          titulo: 'Pavimentação da via',
          multiplaEscolha: false,
          opcoes: [
            CheckinStep2OptionItemConfig(id: 'asfalto', label: 'Asfalto'),
            CheckinStep2OptionItemConfig(id: 'paralelepipedo', label: 'Paralelepípedo'),
            CheckinStep2OptionItemConfig(id: 'bloquete', label: 'Bloquete'),
            CheckinStep2OptionItemConfig(id: 'terra', label: 'Terra'),
            CheckinStep2OptionItemConfig(id: 'mista', label: 'Mista'),
          ],
        ),
        CheckinStep2OptionGroupConfig(
          id: 'infraestrutura_urbana',
          titulo: 'Infraestrutura urbana',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(id: 'calcada', label: 'Calçada'),
            CheckinStep2OptionItemConfig(id: 'guia_sarjeta', label: 'Guia / Sarjeta'),
            CheckinStep2OptionItemConfig(id: 'galeria_pluvial', label: 'Galeria pluvial'),
            CheckinStep2OptionItemConfig(id: 'iluminacao_publica', label: 'Iluminação pública'),
            CheckinStep2OptionItemConfig(id: 'arborizacao', label: 'Arborização'),
            CheckinStep2OptionItemConfig(id: 'sinalizacao_viaria', label: 'Sinalização viária'),
          ],
          permiteObservacao: true,
        ),
        CheckinStep2OptionGroupConfig(
          id: 'servicos_publicos',
          titulo: 'Serviços públicos disponíveis',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(id: 'agua', label: 'Rede de água'),
            CheckinStep2OptionItemConfig(id: 'esgoto', label: 'Rede de esgoto'),
            CheckinStep2OptionItemConfig(id: 'energia', label: 'Energia elétrica'),
            CheckinStep2OptionItemConfig(id: 'telefonia', label: 'Telefonia'),
            CheckinStep2OptionItemConfig(id: 'internet', label: 'Internet'),
            CheckinStep2OptionItemConfig(id: 'coleta_lixo', label: 'Coleta de lixo'),
            CheckinStep2OptionItemConfig(id: 'transporte_publico', label: 'Transporte público'),
          ],
          permiteObservacao: true,
        ),
        CheckinStep2OptionGroupConfig(
          id: 'caracteristicas_localizacao',
          titulo: 'Características da localização',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(id: 'esquina', label: 'Imóvel de esquina'),
            CheckinStep2OptionItemConfig(id: 'meio_quadra', label: 'Meio de quadra'),
            CheckinStep2OptionItemConfig(id: 'condominio', label: 'Em condomínio'),
            CheckinStep2OptionItemConfig(id: 'avenida', label: 'Em avenida'),
            CheckinStep2OptionItemConfig(id: 'rua_local', label: 'Rua local'),
          ],
          permiteObservacao: true,
        ),
      ],
    );
  }

  static CheckinStep2Config _rural() {
    return const CheckinStep2Config(
      tipoImovel: TipoImovel.rural,
      tituloTela: 'Check-in Vistoria',
      subtituloTela: 'Pré Vistoria Externa',
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'acesso_principal',
          titulo: 'Acesso Principal',
          icon: Icons.agriculture_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'entrada_propriedade',
          titulo: 'Entrada da Propriedade',
          icon: Icons.login_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'identificacao_area',
          titulo: 'Identificação / Referência',
          icon: Icons.place_outlined,
          obrigatorio: true,
        ),
      ],
      gruposOpcoes: [
        CheckinStep2OptionGroupConfig(
          id: 'acesso_rural',
          titulo: 'Acesso',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(id: 'rodovia', label: 'Rodovia'),
            CheckinStep2OptionItemConfig(id: 'estrada_terra', label: 'Estrada de terra'),
            CheckinStep2OptionItemConfig(id: 'cascalho', label: 'Cascalho'),
          ],
        ),
      ],
    );
  }

  static CheckinStep2Config _comercial() {
    return const CheckinStep2Config(
      tipoImovel: TipoImovel.comercial,
      tituloTela: 'Check-in Vistoria',
      subtituloTela: 'Pré Vistoria Externa',
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'fachada_comercial',
          titulo: 'Fachada',
          icon: Icons.storefront_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'logradouro_comercial',
          titulo: 'Logradouro',
          icon: Icons.map_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'numero_comercial',
          titulo: 'Número do Imóvel',
          icon: Icons.pin_outlined,
          obrigatorio: true,
        ),
      ],
      gruposOpcoes: [
        CheckinStep2OptionGroupConfig(
          id: 'infra_comercial',
          titulo: 'Infraestrutura',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(id: 'estacionamento', label: 'Estacionamento'),
            CheckinStep2OptionItemConfig(id: 'calcada', label: 'Calçada'),
            CheckinStep2OptionItemConfig(id: 'iluminacao_publica', label: 'Iluminação pública'),
          ],
        ),
      ],
    );
  }

  static CheckinStep2Config _industrial() {
    return const CheckinStep2Config(
      tipoImovel: TipoImovel.industrial,
      tituloTela: 'Check-in Vistoria',
      subtituloTela: 'Pré Vistoria Externa',
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'acesso_industrial',
          titulo: 'Acesso Principal',
          icon: Icons.factory_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'fachada_industrial',
          titulo: 'Fachada / Portaria',
          icon: Icons.apartment_outlined,
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'numero_industrial',
          titulo: 'Número / Identificação',
          icon: Icons.pin_outlined,
          obrigatorio: true,
        ),
      ],
      gruposOpcoes: [
        CheckinStep2OptionGroupConfig(
          id: 'infra_industrial',
          titulo: 'Infraestrutura',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(id: 'energia_trifasica', label: 'Energia trifásica'),
            CheckinStep2OptionItemConfig(id: 'patio_manobra', label: 'Pátio de manobra'),
            CheckinStep2OptionItemConfig(id: 'acesso_caminhoes', label: 'Acesso para caminhões'),
          ],
        ),
      ],
    );
  }

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
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Textura', 'Papel de parede'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
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
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Textura', 'Papel de parede'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
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
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Azulejo', 'Cerâmica', 'Pintura'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'bancada',
              nome: 'Bancada',
              obrigatorioParaConclusao: false,
              materiais: ['Granito', 'Mármore', 'Sintético'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
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
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: true,
              materiais: ['Azulejo', 'Cerâmica', 'Pintura'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'teto',
              nome: 'Teto',
              obrigatorioParaConclusao: true,
              materiais: ['Pintura', 'Gesso', 'Laje'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'loucas_metais',
              nome: 'Louças e Metais',
              obrigatorioParaConclusao: false,
              materiais: ['Louça', 'Metal cromado', 'Inox'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
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
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
            ElementTemplate(
              id: 'paredes',
              nome: 'Paredes',
              obrigatorioParaConclusao: false,
              materiais: ['Azulejo', 'Pintura'],
              estadosConservacao: ['Novo', 'Excelente', 'Bom', 'Regular', 'Ruim', 'Péssimo'],
            ),
          ],
        ),
      ],
    );
  }
}
