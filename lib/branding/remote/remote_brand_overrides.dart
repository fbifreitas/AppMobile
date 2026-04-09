/// Sobrescritas leves de configuração remota para uma marca.
///
/// ## Limite arquitetural — o que override remoto NÃO altera (regra)
/// Override remoto nunca altera:
/// - package id / bundle id
/// - app icon nativo (launcher icon)
/// - splash nativa
/// - nome do app no sistema operacional
///
/// Esses elementos pertencem ao flavor/build e são imutáveis em runtime.
///
/// ## O que pode ser sobrescrito
/// - [labels]: labels genéricos da UI por chave semântica
/// - [sectionNames]: nomes de seções (home, menu, etc.)
/// - [homeTexts]: textos específicos da home
/// - [lightFlags]: flags leves de feature (subset de [BrandFeatureFlags])
///
/// Todos os campos são nullable — ausência significa "use o default do manifest".
class RemoteBrandOverrides {
  /// Labels genéricos da UI. Chave = identificador semântico.
  /// Ex: {'login_welcome': 'Bem-vindo à plataforma'}
  final Map<String, String>? labels;

  /// Nomes de seções. Ex: {'jobs_section': 'ORDENS DO DIA'}
  final Map<String, String>? sectionNames;

  /// Textos da Home. Ex: {'home_subtitle': 'Seu painel de hoje'}
  final Map<String, String>? homeTexts;

  /// Flags leves. Só afetam blocos opcionais de UI.
  /// Ex: {'proposalsBlockEnabled': false, 'financialSummaryEnabled': true}
  final Map<String, bool>? lightFlags;

  const RemoteBrandOverrides({
    this.labels,
    this.sectionNames,
    this.homeTexts,
    this.lightFlags,
  });

  /// Sem overrides ativos.
  static const RemoteBrandOverrides empty = RemoteBrandOverrides();

  bool get isEmpty =>
      labels == null &&
      sectionNames == null &&
      homeTexts == null &&
      lightFlags == null;

  factory RemoteBrandOverrides.fromJson(Map<String, dynamic> json) {
    return RemoteBrandOverrides(
      labels: _toStringMap(json['labels']),
      sectionNames: _toStringMap(json['sectionNames']),
      homeTexts: _toStringMap(json['homeTexts']),
      lightFlags: _toBoolMap(json['lightFlags']),
    );
  }

  static Map<String, String>? _toStringMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry('$k', '$v'));
    }
    return null;
  }

  static Map<String, bool>? _toBoolMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry('$k', v == true));
    }
    return null;
  }
}
