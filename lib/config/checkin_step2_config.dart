import 'package:flutter/material.dart';

enum TipoImovel { urbano, rural, comercial, industrial }

typedef AssetType = TipoImovel;

extension AssetTypeExtension on TipoImovel {
  String get displayName => label;

  static AssetType parse(String value) {
    return TipoImovelExtension.fromString(value);
  }
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
    final normalizado = value.split('•').first.trim().toLowerCase();

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
  // Legacy mapping names kept for compatibility with existing payloads.
  final String cameraMacroLocal;
  final String cameraAmbiente;
  final String? cameraElementoInicial;

  const CheckinStep2PhotoFieldConfig({
    required this.id,
    required this.titulo,
    required this.icon,
    required this.cameraMacroLocal,
    required this.cameraAmbiente,
    this.cameraElementoInicial,
    this.obrigatorio = false,
  });

  String get evidenceContext => cameraMacroLocal;

  String get evidenceTargetItem => cameraAmbiente;

  String? get evidenceTargetQualifier => cameraElementoInicial;

  String get title => titulo;
  bool get required => obrigatorio;
  String get captureContext => cameraMacroLocal;
  String get targetItem => cameraAmbiente;
  String? get targetQualifier => cameraElementoInicial;
}

class CheckinStep2OptionItemConfig {
  final String id;
  final String label;

  const CheckinStep2OptionItemConfig({required this.id, required this.label});
}

class CheckinStep2OptionGroupConfig {
  final String id;
  final String titulo;
  final bool visivel;
  final bool obrigatorio;
  final bool multiplaEscolha;
  final bool permiteObservacao;
  final List<CheckinStep2OptionItemConfig> opcoes;

  const CheckinStep2OptionGroupConfig({
    required this.id,
    required this.titulo,
    required this.opcoes,
    this.visivel = true,
    this.obrigatorio = false,
    this.multiplaEscolha = true,
    this.permiteObservacao = false,
  });

  String get title => titulo;
  bool get visible => visivel;
  bool get required => obrigatorio;
  bool get multiSelect => multiplaEscolha;
  bool get allowsNote => permiteObservacao;
  List<CheckinStep2OptionItemConfig> get options => opcoes;
}

class CheckinStep2Config {
  final TipoImovel tipoImovel;
  final String tituloTela;
  final String subtituloTela;
  final String secaoFotosLabel;
  final bool secaoFotosVisivel;
  final bool secaoFotosObrigatoria;
  final String secaoOpcoesLabel;
  final bool secaoOpcoesVisivel;
  final bool secaoOpcoesObrigatoria;
  final String botaoConfirmarLabel;
  final int minFotos;
  final int? maxFotos;
  final bool visivelNoFluxo;
  final bool obrigatoriaParaEntrega;
  final bool bloqueiaCaptura;
  final List<CheckinStep2PhotoFieldConfig> camposFotos;
  final List<CheckinStep2OptionGroupConfig> gruposOpcoes;

  const CheckinStep2Config({
    required this.tipoImovel,
    required this.tituloTela,
    required this.subtituloTela,
    this.secaoFotosLabel = 'Registro fotográfico',
    this.secaoFotosVisivel = true,
    this.secaoFotosObrigatoria = false,
    this.secaoOpcoesLabel = 'Infraestrutura e serviços',
    this.secaoOpcoesVisivel = true,
    this.secaoOpcoesObrigatoria = false,
    this.botaoConfirmarLabel = 'Confirmar e abrir a câmera',
    this.minFotos = 0,
    this.maxFotos,
    this.visivelNoFluxo = true,
    this.obrigatoriaParaEntrega = false,
    this.bloqueiaCaptura = false,
    required this.camposFotos,
    required this.gruposOpcoes,
  });

  bool get obrigatoriaNoFluxo => obrigatoriaParaEntrega;

  AssetType get assetType => tipoImovel;
  String get screenTitle => tituloTela;
  String get screenSubtitle => subtituloTela;
  String get photoSectionLabel => secaoFotosLabel;
  bool get photoSectionVisible => secaoFotosVisivel;
  bool get photoSectionRequired => secaoFotosObrigatoria;
  String get optionSectionLabel => secaoOpcoesLabel;
  bool get optionSectionVisible => secaoOpcoesVisivel;
  bool get optionSectionRequired => secaoOpcoesObrigatoria;
  String get confirmButtonLabel => botaoConfirmarLabel;
  bool get flowVisible => visivelNoFluxo;
  bool get requiredForSubmission => obrigatoriaParaEntrega;
  bool get blocksCapture => bloqueiaCaptura;
  List<CheckinStep2PhotoFieldConfig> get photoFields => camposFotos;
  List<CheckinStep2OptionGroupConfig> get optionGroups => gruposOpcoes;
}

class CheckinStep2Configs {
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

  static CheckinStep2Config _urbano() {
    return const CheckinStep2Config(
      tipoImovel: TipoImovel.urbano,
      tituloTela: 'Check-in Vistoria',
      subtituloTela: 'Pré Vistoria Externa',
      minFotos: 4,
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'fachada',
          titulo: 'Fachada',
          icon: Icons.home_work_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Fachada',
          cameraElementoInicial: 'Visão geral',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'logradouro',
          titulo: 'Logradouro',
          icon: Icons.map_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Logradouro',
          cameraElementoInicial: 'Visão geral',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'acesso_imovel',
          titulo: 'Acesso ao imóvel',
          icon: Icons.door_front_door_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Acesso ao imóvel',
          cameraElementoInicial: 'Portão',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'entorno',
          titulo: 'Entorno',
          icon: Icons.landscape_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Entorno',
          cameraElementoInicial: 'Visão geral',
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
            CheckinStep2OptionItemConfig(
              id: 'paralelepipedo',
              label: 'Paralelepípedo',
            ),
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
            CheckinStep2OptionItemConfig(
              id: 'guia_sarjeta',
              label: 'Guia / Sarjeta',
            ),
            CheckinStep2OptionItemConfig(
              id: 'galeria_pluvial',
              label: 'Galeria pluvial',
            ),
            CheckinStep2OptionItemConfig(
              id: 'iluminacao_publica',
              label: 'Iluminação pública',
            ),
            CheckinStep2OptionItemConfig(
              id: 'arborizacao',
              label: 'Arborização',
            ),
            CheckinStep2OptionItemConfig(
              id: 'sinalizacao_viaria',
              label: 'Sinalização viária',
            ),
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
            CheckinStep2OptionItemConfig(
              id: 'energia',
              label: 'Energia elétrica',
            ),
            CheckinStep2OptionItemConfig(id: 'telefonia', label: 'Telefonia'),
            CheckinStep2OptionItemConfig(id: 'internet', label: 'Internet'),
            CheckinStep2OptionItemConfig(
              id: 'coleta_lixo',
              label: 'Coleta de lixo',
            ),
            CheckinStep2OptionItemConfig(
              id: 'transporte_publico',
              label: 'Transporte público',
            ),
          ],
          permiteObservacao: true,
        ),
        CheckinStep2OptionGroupConfig(
          id: 'caracteristicas_localizacao',
          titulo: 'Características da localização',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(
              id: 'esquina',
              label: 'Imóvel de esquina',
            ),
            CheckinStep2OptionItemConfig(
              id: 'meio_quadra',
              label: 'Meio de quadra',
            ),
            CheckinStep2OptionItemConfig(
              id: 'condominio',
              label: 'Em condomínio',
            ),
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
      minFotos: 3,
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'acesso_principal',
          titulo: 'Acesso Principal',
          icon: Icons.agriculture_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Acesso principal',
          cameraElementoInicial: 'Visão geral',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'entrada_propriedade',
          titulo: 'Entrada da propriedade',
          icon: Icons.login_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Entrada da propriedade',
          cameraElementoInicial: 'Porteira',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'identificacao_area',
          titulo: 'Identificação / referência',
          icon: Icons.place_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Identificação / referência',
          cameraElementoInicial: 'Placa',
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
            CheckinStep2OptionItemConfig(
              id: 'estrada_terra',
              label: 'Estrada de terra',
            ),
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
      minFotos: 3,
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'fachada_comercial',
          titulo: 'Fachada',
          icon: Icons.storefront_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Fachada',
          cameraElementoInicial: 'Visão geral',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'logradouro_comercial',
          titulo: 'Logradouro',
          icon: Icons.map_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Logradouro',
          cameraElementoInicial: 'Visão geral',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'acesso_comercial',
          titulo: 'Acesso principal',
          icon: Icons.door_front_door_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Acesso principal',
          cameraElementoInicial: 'Porta',
          obrigatorio: true,
        ),
      ],
      gruposOpcoes: [
        CheckinStep2OptionGroupConfig(
          id: 'infra_comercial',
          titulo: 'Infraestrutura',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(
              id: 'estacionamento',
              label: 'Estacionamento',
            ),
            CheckinStep2OptionItemConfig(id: 'calcada', label: 'Calçada'),
            CheckinStep2OptionItemConfig(
              id: 'iluminacao_publica',
              label: 'Iluminação pública',
            ),
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
      minFotos: 3,
      camposFotos: [
        CheckinStep2PhotoFieldConfig(
          id: 'acesso_industrial',
          titulo: 'Acesso principal',
          icon: Icons.factory_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Acesso principal',
          cameraElementoInicial: 'Portão',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'fachada_industrial',
          titulo: 'Fachada / portaria',
          icon: Icons.apartment_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Fachada / portaria',
          cameraElementoInicial: 'Visão geral',
          obrigatorio: true,
        ),
        CheckinStep2PhotoFieldConfig(
          id: 'identificacao_industrial',
          titulo: 'Número / identificação',
          icon: Icons.pin_outlined,
          cameraMacroLocal: 'Rua',
          cameraAmbiente: 'Número / identificação',
          cameraElementoInicial: 'Número',
          obrigatorio: true,
        ),
      ],
      gruposOpcoes: [
        CheckinStep2OptionGroupConfig(
          id: 'infra_industrial',
          titulo: 'Infraestrutura',
          multiplaEscolha: true,
          opcoes: [
            CheckinStep2OptionItemConfig(
              id: 'energia_trifasica',
              label: 'Energia trifásica',
            ),
            CheckinStep2OptionItemConfig(
              id: 'patio_manobra',
              label: 'Pátio de manobra',
            ),
            CheckinStep2OptionItemConfig(
              id: 'acesso_caminhoes',
              label: 'Acesso para caminhões',
            ),
          ],
        ),
      ],
    );
  }
}


