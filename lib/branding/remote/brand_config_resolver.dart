import '../brand_manifest.dart';
import '../brand_tokens.dart';
import '../resolved_brand_config.dart';
import 'remote_brand_overrides.dart';

/// Resolve o [ResolvedBrandConfig] final a partir do [BrandManifest] base
/// e dos [RemoteBrandOverrides] opcionais.
///
/// Este é o único ponto onde manifest + overrides são combinados.
/// A UI nunca lê manifest e overrides separadamente — sempre lê
/// [ResolvedBrandConfig] via [BrandProvider].
class BrandConfigResolver {
  const BrandConfigResolver._();

  /// Limite arquitetural: override remoto pode alterar apenas textos, labels
  /// e flags leves de UI. Não altera: applicationId, bundle identifier,
  /// nome do app no SO, app icon nativo, splash nativa nem qualquer
  /// propriedade de flavor/build — esses são imutáveis em runtime.
  ///
  /// Produz a configuração resolvida final.
  ///
  /// Se [overrides] for null ou [RemoteBrandOverrides.empty], retorna
  /// configuração baseada apenas no manifest.
  static ResolvedBrandConfig resolve(
    BrandManifest manifest, {
    RemoteBrandOverrides? overrides,
  }) {
    final tokens = BrandTokens.fromManifest(manifest);
    final effectiveOverrides = overrides ?? RemoteBrandOverrides.empty;

    // Flags: manifest base + light overrides remotos
    final flags = effectiveOverrides.lightFlags != null
        ? manifest.featureFlags.applyLightOverrides(effectiveOverrides.lightFlags!)
        : manifest.featureFlags;

    // Copy: manifest copyOverrides + labels/sectionNames/homeTexts remotos
    final Map<String, String> resolvedCopy = {
      ...manifest.copyOverrides,
      if (effectiveOverrides.labels != null) ...effectiveOverrides.labels!,
      if (effectiveOverrides.sectionNames != null) ...effectiveOverrides.sectionNames!,
      if (effectiveOverrides.homeTexts != null) ...effectiveOverrides.homeTexts!,
    };

    return ResolvedBrandConfig(
      manifest: manifest,
      tokens: tokens,
      featureFlags: flags,
      resolvedCopy: resolvedCopy,
    );
  }
}
