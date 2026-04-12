/// Feature flags de produto controladas pela marca ativa.
///
/// Estas flags são definidas no [BrandManifest] de cada marca e podem
/// ser sobrescritas por [RemoteBrandOverrides] apenas para flags marcadas
/// como "leves" (não afetam publicação, bundle id, ícone ou splash).
///
/// ## Limite do override remoto
/// Override remoto NÃO altera:
/// - package id / bundle id
/// - app icon nativo
/// - splash nativa
/// - nome do app no sistema operacional
///
  /// Override remoto PODE alterar apenas:
  /// - [proposalsBlockEnabled] (habilitar/desabilitar bloco de propostas na home)
  /// - [financialSummaryEnabled] (mostrar/ocultar resumo financeiro)
  /// - [marketplaceCopyEnabled] (copy de marketplace vs. corporativo)
  /// - [geofenceRequired] (exigir ou nao geofence para iniciar a inspeção)
class BrandFeatureFlags {
  /// Habilita o módulo de propostas (aceite de demandas externas).
  /// Quando false, [proposalsBlockEnabled] é forçado para false.
  final bool proposalsEnabled;

  /// Habilita o bloco de propostas na Home.
  /// Requer [proposalsEnabled] = true para ter efeito.
  final bool proposalsBlockEnabled;

  /// Exige geofence para habilitar o início de inspeção.
  /// Quando false, o botão de início não é bloqueado por distância.
  final bool geofenceRequired;

  /// Exige gesto de deslize para ações críticas (aceite de proposta).
  /// Quando false, exibe botão convencional no lugar do swipe.
  final bool swipeRequired;

  /// Habilita o bloco de resumo financeiro na Home ou em jobs.
  final bool financialSummaryEnabled;

  /// Usa linguagem de marketplace (proposta, oportunidade, expiração).
  /// Quando false, usa linguagem corporativa (demanda, ordem, prazo).
  final bool marketplaceCopyEnabled;

  const BrandFeatureFlags({
    required this.proposalsEnabled,
    required this.proposalsBlockEnabled,
    required this.geofenceRequired,
    required this.swipeRequired,
    required this.financialSummaryEnabled,
    required this.marketplaceCopyEnabled,
  });

  /// Kaptur: app marketplace completo.
  static const BrandFeatureFlags kaptur = BrandFeatureFlags(
    proposalsEnabled: true,
    proposalsBlockEnabled: true,
    geofenceRequired: true,
    swipeRequired: true,
    financialSummaryEnabled: true,
    marketplaceCopyEnabled: true,
  );

  /// Compass: app corporativo sem propostas.
  static const BrandFeatureFlags compass = BrandFeatureFlags(
    proposalsEnabled: false,
    proposalsBlockEnabled: false,
    geofenceRequired: false,
    swipeRequired: false,
    financialSummaryEnabled: false,
    marketplaceCopyEnabled: false,
  );

  /// Aplica overrides leves de configuração remota.
  /// Flags de publicação/identidade nativa são ignoradas aqui por design.
  BrandFeatureFlags applyLightOverrides(Map<String, bool> overrides) {
    return BrandFeatureFlags(
      proposalsEnabled: proposalsEnabled,
      proposalsBlockEnabled: overrides['proposalsBlockEnabled'] ?? proposalsBlockEnabled,
      geofenceRequired: overrides['geofenceRequired'] ?? geofenceRequired,
      swipeRequired: swipeRequired,
      financialSummaryEnabled: overrides['financialSummaryEnabled'] ?? financialSummaryEnabled,
      marketplaceCopyEnabled: overrides['marketplaceCopyEnabled'] ?? marketplaceCopyEnabled,
    );
  }
}
