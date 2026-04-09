import 'package:flutter/material.dart';

import '../config/brand_feature_flags.dart';
import '../config/product_mode.dart';

/// Manifesto de marca — base fixa definida em compile-time pelo flavor.
///
/// [BrandManifest] descreve a identidade estática de uma marca.
/// É definido uma vez no entrypoint do flavor e não muda em runtime.
///
/// ## Separação de responsabilidades
/// - [BrandManifest] = base fixa da marca (compile-time)
/// - [RemoteBrandOverrides] = sobrescritas leves (runtime, opcional)
/// - [ResolvedBrandConfig] = objeto final consumido pela UI
///
/// ## Política de assets ausentes
/// Assets de logo/ícone ausentes resultam em **fallback silencioso**:
/// - logo ausente → exibe [appName] como texto
/// - ícone ausente → usa ícone padrão do flavor (definido no build nativo)
/// Não há falha de build por asset de marca ausente nos paths opcionais.
/// Assets obrigatórios (ex: launcher icon) devem existir no source set
/// do flavor Android ou no target iOS — esses falham no build nativo.
class BrandManifest {
  /// Identificador único da marca. Imutável. Ex: 'kaptur', 'compass'.
  final String brandId;

  /// Nome do app exibido em textos da UI. Não substitui o nome do sistema
  /// operacional (esse é definido no AndroidManifest/Info.plist pelo flavor).
  final String appName;

  /// Cor primária da marca.
  final Color primaryColor;

  /// Cor secundária da marca.
  final Color secondaryColor;

  /// Cor de destaque/accent da marca.
  final Color accentColor;

  /// Path do asset de logo (ex: 'assets/brands/kaptur/logo.png').
  /// Pode ser null — a UI deve lidar com ausência via [hasLogo].
  final String? logoAsset;

  /// Path do asset de ícone de marca para uso interno na UI.
  /// Diferente do launcher icon (esse é nativo, não referenciado aqui).
  final String? iconAsset;

  /// Modo de produto: marketplace ou corporate.
  final ProductMode productMode;

  /// Feature flags da marca.
  final BrandFeatureFlags featureFlags;

  /// Overrides de copy da marca. Chaves são identificadores semânticos.
  /// Ex: {'jobs_section_title': 'MEUS TRABALHOS', 'login_welcome': 'Bem-vindo'}
  final Map<String, String> copyOverrides;

  const BrandManifest({
    required this.brandId,
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.logoAsset,
    this.iconAsset,
    required this.productMode,
    required this.featureFlags,
    this.copyOverrides = const {},
  });

  bool get hasLogo => logoAsset != null;
  bool get hasIcon => iconAsset != null;
}
