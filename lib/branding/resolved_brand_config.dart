import '../config/brand_feature_flags.dart';
import '../config/product_mode.dart';
import 'brand_manifest.dart';
import 'brand_tokens.dart';

/// Configuração de marca resolvida — **único contrato consumido pela UI**.
///
/// Widgets nunca leem [BrandManifest] ou [RemoteBrandOverrides] diretamente.
/// Toda leitura passa por [ResolvedBrandConfig] via [BrandProvider.configOf(context)].
///
/// Produzido por [BrandConfigResolver.resolve] uma vez no startup, após
/// fetch de configuração remota. Atualizado via [BrandProvider] se o
/// override remoto chegar de forma assíncrona.
class ResolvedBrandConfig {
  final BrandManifest manifest;
  final BrandTokens tokens;
  final BrandFeatureFlags featureFlags;

  /// Copy resolvido = manifest.copyOverrides + remote overrides aplicados.
  final Map<String, String> resolvedCopy;

  const ResolvedBrandConfig({
    required this.manifest,
    required this.tokens,
    required this.featureFlags,
    required this.resolvedCopy,
  });

  // --- Conveniências ---

  String get brandId => manifest.brandId;
  String get appName => manifest.appName;
  ProductMode get productMode => manifest.productMode;
  bool get isMarketplace => productMode.isMarketplace;

  String? get logoAsset => manifest.logoAsset;
  String? get iconAsset => manifest.iconAsset;
  bool get hasLogo => manifest.hasLogo;

  /// Retorna texto de copy por chave semântica com fallback para [defaultValue].
  String copyText(String key, {String defaultValue = ''}) =>
      resolvedCopy[key] ?? defaultValue;

  /// Retorna o texto de copy por chave, ou [null] se a chave não estiver
  /// presente no mapa resolvido.
  ///
  /// Use este helper quando o widget tem um fallback próprio e deve usá-lo
  /// quando não houver override de copy definido.
  String? copyTextOrNull(String key) => resolvedCopy[key];
}
